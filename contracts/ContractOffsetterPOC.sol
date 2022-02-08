//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// You can't import contracts via https from GH. So I just copied these contracts over.
// You could use NPM publish, but this works for now.
import "./CO2KEN_contracts/ToucanCarbonOffsets.sol";
import "./CO2KEN_contracts/pools/BaseCarbonTonne.sol";
import "./CO2KEN_contracts/IToucanContractRegistry.sol";

contract ContractOffsetterPOC is OwnableUpgradeable {
  using SafeERC20 for IERC20;
  // ======================================================================================================
  // ------------------------------------------    THE STORY   -------------------------------------------
  //  The main/first functionality of this contract is to deposit & redeem BCT for TCO2.
  //
  //  As this contract is used, the contract calculates the footprint of each user
  //  (meaning the CO2 that was emitted when using this contract).
  //
  //  For the moment, we are using a hardcoded 0,00000036 TCO2 per transaction to calculate
  //  the footprint. The goal is to eventually get a real calculation in place.
  //
  //  At any point in time, the user can check the footprint created by his using of this contract.
  //  And he can also offset that footprint (by retiring TCO2).
  //
  //  When the user offsets, he can choose between offsetting ALL his footprint or an amount of his choice.
  //  He can't offset more than his footprint.
  //
  //  If the user already has TCO2 in his wallet, he has the possibility to deposit that to this contract
  //  in order to retire it and offset the footprint.
  //
  //  It should be noted, everytime you deposit, or redeem, or offset or do any interaction with this contract:
  //  that adds to the footprint.
  //
  //  And there are some long-term TODOs:
  //  TODO addContract(), addEvents(); documented here: https://linear.app/toucan/issue/ECO-22/mycontractoffsetter-my-personal-offsetting-contract
  //  TODO a function to swap (W)ETH, (W)MATIC or USDC for BCT with Sushiswap
  //
  // ======================================================================================================

  // user => footprint
  mapping(address => uint256) public footprints;
  address public bctAddress = 0xf2438A14f668b1bbA53408346288f3d7C71c10a1;
  address public contractRegistry = 0x6739D490670B2710dc7E79bB12E455DE33EE1cb6;
  // user => (token => amount)
  mapping(address => mapping(address => uint256)) public balances;

  event Deposited(
    address depositor,
    address erc20Address,
    uint256 amountDeposited
  );
  event Redeemed(
    address redeemer,
    address receivedTCO2,
    uint256 amountRedeemed
  );
  event Offset(
    address offsetter,
    address retiredTCO2,
    uint256 amountOffset,
    uint256 remainingFootprint
  );

  // @description you can use this to change the TCO2 contracts registry if needed
  // @param _address the contract registry to use
  function setToucanContractRegistry(address _address)
    public
    virtual
    onlyOwner
  {
    contractRegistry = _address;
  }

  // for the moment we are using a hardcoded TCO2 per transaction until we have something better
  function addFootprint(uint256 _transactions) private {
    footprints[msg.sender] += 360000000000 * _transactions; // 0,00000036 TCO2 per transaction
  }

  // @description checks if token to be deposited is eligible for this pool
  // @param _erc20Address address to be checked
  function checkTokenEligibility(address _erc20Address)
    private
    view
    returns (bool)
  {
    // check if token is a TCO2
    bool isToucanContract = IToucanContractRegistry(contractRegistry)
      .checkERC20(_erc20Address);
    if (isToucanContract) return true;

    // check if token is BCT
    if (_erc20Address == bctAddress) return true;

    // nothing matches, return false
    return false;
  }

  // @description deposit tokens from use to this contract
  // @param _erc20Address token to be deposited
  // @param _amount amount to be deposited
  function deposit(address _erc20Address, uint256 _amount) public {
    // update footprint to account for this function and its transactions
    addFootprint(2);

    bool eligibility = checkTokenEligibility(_erc20Address);
    require(eligibility, "Can't deposit this token");

    // use token's contract to do a safe transfer from the user to this contract
    // remember that the user has to approve this in the frontend
    IERC20(_erc20Address).safeTransferFrom(msg.sender, address(this), _amount);

    // add amount of said token to balance of this user in this contract
    balances[msg.sender][_erc20Address] += _amount;

    emit Deposited(msg.sender, _erc20Address, _amount);
  }

  // @description redeems some BCT from contract balance for a chosen TCO2 token
  // @param _desiredTCO2 the address of the TCO2 you want to receive
  // @param _amount the amount of BCT you want to redeem for TCO2
  function redeemBCT(address _desiredTCO2, uint256 _amount) public {
    // update footprint to account for this function and its transactions
    addFootprint(3);

    require(
      _amount <= balances[msg.sender][bctAddress],
      "You don't have enough BCT in this contract."
    );

    bool eligibility = checkTokenEligibility(_desiredTCO2);
    require(eligibility, "Can't redeem BCT for this token.");

    // prepare/format params for BCT.retireMany() method
    address[] memory tco2Addresses = new address[](1);
    uint256[] memory amounts = new uint256[](1);
    tco2Addresses[0] = _desiredTCO2;
    amounts[0] = _amount;

    // send BCT, receive TCO2
    BaseCarbonTonne(bctAddress).redeemMany(tco2Addresses, amounts);

    // modify balance sheets of this contract
    balances[msg.sender][bctAddress] -= _amount;
    balances[msg.sender][_desiredTCO2] += _amount;

    emit Redeemed(msg.sender, _desiredTCO2, _amount);
  }

  // @description retire TCO2 so that you offset ALL the carbon used by this contract
  // @param _tco2Address address of the TCO2 you want to retire
  function selfOffset(address _tco2Address) public {
    // update footprint to account for this function and its transactions
    addFootprint(2);

    bool eligibility = checkTokenEligibility(_tco2Address);
    require(eligibility, "Can't retire this token.");

    require(
      footprints[msg.sender] <= balances[msg.sender][_tco2Address],
      "You don't have enough of this TCO2 (in the contract)."
    );

    // use the TCO contract to retire TCO2
    ToucanCarbonOffsets(_tco2Address).retire(footprints[msg.sender]);

    // reduce amount of TCO2 in the balance sheet
    balances[msg.sender][_tco2Address] -= footprints[msg.sender];

    uint256 amountOffset = footprints[msg.sender];

    // reset the footprint
    footprints[msg.sender] = 0;

    emit Offset(msg.sender, _tco2Address, amountOffset, footprints[msg.sender]);
  }

  // @description retire TCO2 so that you offset a certain amount of the carbon used by this contract
  // @param _tco2Address address of the TCO2 you want to retire
  // @param _amount how much CO2 you want to offset
  function selfOffset(address _tco2Address, uint256 _amount) public {
    // update footprint to account for this function and its transactions
    addFootprint(2);

    bool eligibility = checkTokenEligibility(_tco2Address);
    require(eligibility, "Can't retire this token.");

    require(
      _amount <= balances[msg.sender][_tco2Address],
      "You don't have enough of this TCO2 (in the contract)."
    );

    require(
      _amount <= footprints[msg.sender],
      "You can't offset more than your footprint."
    );

    // use the TCO contract to retire TCO2
    ToucanCarbonOffsets(_tco2Address).retire(_amount);

    // reduce amount of TCO2 in the balance sheet
    balances[msg.sender][_tco2Address] -= _amount;

    // reduce the footprint
    footprints[msg.sender] -= _amount;

    emit Offset(msg.sender, _tco2Address, _amount, footprints[msg.sender]);
  }
}
