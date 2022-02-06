//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// You can't import contracts via https from GH. So I just copied these contracts over.
// You could use NPM publish, but this works for now.
import "./CO2KEN_contracts/ToucanCarbonOffsets.sol";
import "./CO2KEN_contracts/pools/BaseCarbonTonne.sol";

contract ContractOffsetterPOC {
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
  // user => (token => amount)
  mapping(address => mapping(address => uint)) public balances;
  event Deposited(address depositorAddress, address erc20Address, uint256 amountDeposited);

  // @description checks if token to be deposited is eligible for this pool
  // @param _erc20Address address to be checked
  function checkTokenEligibility(address _erc20Address) private view returns (bool) {
    // TODO how do I check if a address belongs to a TCO2 type token so that we can use multiple types of TCO2s
    if (ToucanCarbonOffsets(_erc20Address)) return true;
    if (_erc20Address == bctAddress) return true;
    return false;
  }

  // @description deposit tokens from use to this contract
  // @param _erc20Address token to be deposited
  // @param _amount amount to be deposited
  function deposit(address _erc20Address, uint256 _amount) public {
    // update footprint to account for this function and its transactions
    _updateFootprint(2);

    bool eligibility = checkTokenEligibility(_erc20Address);
    require(eligibility, "Token rejected");

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
  // TODO should user be able to pick his desired TCO2?
  function redeemBCT(address _desiredTCO2, uint256 _amount) public {
    // update footprint to account for this function and its transactions
    _updateFootprint(3);

    require(_amount <= balances[msg.sender][bctAddress], "You don't have enough BCT in this contract.");

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
    footprint += _transactions * 0.00000036;
    return footprint;
  }

  // @description retire TCO2 so that you offset the carbon used by this contract
  function selfOffsetContract() public {
    // update footprint to account for this function and its transactions
    _updateFootprint(2);

    // require that the contract owns an amount at least equal to the amount we are trying to retire
    // TODO: make this check each TCO2 address that the contract has have
    require(footprint <= balances[msg.sender][tco2Address], "You don't have enough TCO2.");

    // use the TCO contract to retire TCO2
    // TODO: which TCO2 address shall I even use?
    ToucanCarbonOffsets(tco2Address).retire(footprint);

    // reduce amount of TCO2 in the balance sheet of this contract
    // TODO: make this reduce amount for each used TCO2
    balances[msg.sender][tco2Address] -= footprint;

    // reset the footprint
    footprint = 0;
  }
}
