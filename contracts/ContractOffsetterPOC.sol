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
  // the main/first functionality of this contract is to redeem BCT
  // then we present a demonstration of how people could
  //  1. calculate the emissions / footprint of this contract when receiving and redeeming BCT
  //  2. offset its activities (by using the retireTCO2 function)
  //
  // How the calculation of the footprint is done, is still up to discussion. One thing I have found
  // in my research with Andi is that roughly speaking one transaction on Polygon is equal to
  // 0.0003 kg of CO2 (which means 0,0000003 TCO2)
  // ======================================================================================================

  // TODO if possible (time-wise) eventually make a function to swap (W)ETH, (W)MATIC or USDC for BCT with Sushiswap

  uint256 public footprint = 0;
  address public bctAddress = 0xf2438A14f668b1bbA53408346288f3d7C71c10a1;
  address public contractRegistry = 0x6739D490670B2710dc7E79bB12E455DE33EE1cb6;
  // user => (token => amount)
  mapping(address => mapping(address => uint)) public balances;
  event Deposited(address depositorAddress, address erc20Address, uint256 amountDeposited);

  // @description you can use this to change the TCO2 contracts registry if needed
  // @param _address the contract registry to use
  function setToucanContractRegistry(address _address)
  public
  virtual
  onlyOwner
  {
    contractRegistry = _address;
  }

  // @description checks if token to be deposited is eligible for this pool
  // @param _erc20Address address to be checked
  function checkTokenEligibility(address _erc20Address) private view returns (bool) {
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
    _updateFootprint(2);

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
    _updateFootprint(3);

    require(_amount <= balances[msg.sender][bctAddress], "You don't have enough BCT in this contract.");

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
  }

  // for the moment we are using a hardcoded TCO2 per transaction until we have something better
  function _updateFootprint(uint256 _transactions) private returns (uint256) {
    footprint += _transactions * 36 / 100000000 ; // * 0.00000036
    return footprint;
  }

  // @description retire TCO2 so that you offset the carbon used by this contract
  // @param _tco2Address address of the TCO2 you want to retire
  function selfOffset(address _tco2Address) public {
    // update footprint to account for this function and its transactions
    _updateFootprint(2);

    bool eligibility = checkTokenEligibility(_tco2Address);
    require(eligibility, "Can't retire this token.");

    // require that the contract owns an amount at least equal to the amount we are trying to retire
    require(footprint <= balances[msg.sender][_tco2Address], "You don't have enough of this TCO2 (deposited).");

    // use the TCO contract to retire TCO2
    ToucanCarbonOffsets(_tco2Address).retire(footprint);

    // reduce amount of TCO2 in the balance sheet of this contract
    balances[msg.sender][_tco2Address] -= footprint;

    // reset the footprint
    footprint = 0;
  }
}
