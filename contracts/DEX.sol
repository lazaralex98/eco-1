//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// You can't import contracts via https from GH. So I just copied these contracts over.
// You could use NPM publish, but this works for now.
import "./CO2KEN_contracts/ToucanCarbonOffsets.sol";
import "./CO2KEN_contracts/pools/BaseCarbonTonne.sol";

contract DEX {
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

  // TODO figure out footprint calculation

  // TODO create a Factory contract to make it easy for people to deploy and user their own version of this contract

  // TODO if possible (time-wise) eventually make a function to swap WETH, MATIC or USDC for BCT with Sushiswap

  // TODO Q: should it be able to retire multiple types of TCO2? or just the one it was deployed with?
  // yes, you should be able to send any TCO2 to this one contract (WAIT FOR JAMES)

  uint256 public footprint;
  address public tco2Address;
  address public bctAddress = 0xf2438A14f668b1bbA53408346288f3d7C71c10a1;
  address public owner;
  mapping(address => uint256) private tokenBalances;
  event Deposited(address erc20Addr, uint256 amount);

  // you are supposed to set the address of the TCO2 token you want to use upon deployment of this contract
  constructor (address _tco2Address)  {
    owner = msg.sender;
    tco2Address = _tco2Address;
  }

  // a simple function that retrieves the balance of the specified token
  function getTokenBalance(address _erc20Address) public view returns (uint256) {
    return tokenBalances[_erc20Address];
  }

  /* @notice Internal function that checks if token to be deposited is eligible for this pool
   * @param _erc20Address ERC20 contract address to be checked
   * this can be changed in the future to contain other tokens
   */
  function checkEligible(address _erc20Address) public view returns (bool) {
    if (_erc20Address == tco2Address) return true;
    if (_erc20Address == bctAddress) return true;
    return false;
  }

  /* @description function to deposit tokens from user to this contract
   * @param _erc20Address ERC20 contract address to be deposited
   * @param _amount amount to be deposited
   * in the long run, this will modified to adapt to the structure mentioned above
   */
  function deposit(address _erc20Address, uint256 _amount) public {
    // require that this is called by the owner
    require(owner == msg.sender, "You can't call unless you are the contract owner.");

    // check token eligibility
    bool eligibility = checkEligible(_erc20Address);
    require(eligibility, "Token rejected");

    // use token's contract to do a safe transfer from the user to this contract
    IERC20(_erc20Address).safeTransferFrom(msg.sender, address(this), _amount);

    // add amount of said token to balance sheet of this contract
    tokenBalances[_erc20Address] += _amount;

    emit Deposited(_erc20Address, _amount);
  }

  // @description redeems some BCT from contract balance for a chosen TCO2 token
  // @param _desiredTCO2 the address of the TCO2 you want to receive
  // @param _amount the amount of BCT you want to redeem for TCO2
  function redeemBCT(address _desiredTCO2, uint256 _amount) public {
    // require that this is called by the owner
    require(owner == msg.sender, "You can't call unless you are the contract owner.");

    // require that the contract owns an amount at least equal to the amount we are trying to retire
    require(_amount <= tokenBalances[bctAddress], "You don't have enough BCT.");

    // check if BCT contract has our desired TCO2
    uint256 bctBalanceOfDesiredTCO2 = BaseCarbonTonne(bctAddress).tokenBalances(_desiredTCO2);
    require(bctBalanceOfDesiredTCO2 >= _amount, "BCT contract doesn't have enough of this TCO2");

    // prepare/format params for BCT.retireMany() method
    address[] memory tco2Addresses = new address[](1);
    uint256[] memory amounts = new uint256[](1);
    tco2Addresses[0] = _desiredTCO2;
    amounts[0] = _amount;

    // redeems an amount of BCT (from contract's balance) into the desired TCO2 token(s)
    // roughly it means this contract will send the BCT contract some BCT and will receive some TCO2
    BaseCarbonTonne(bctAddress).redeemMany(tco2Addresses, amounts);

    // modify balance sheets of this contract
    tokenBalances[bctAddress] -= _amount;
    tokenBalances[_desiredTCO2] += _amount;
  }

  // TODO: this is hardcoded for now, but it should do some carbon emission math to set & return the footprint
  function _calculateFootprint(uint256 _amount) private pure returns (uint256) {
    footprint = _amount;
    return _amount;
  }

  /* @description this method will be used to retire TCO2 so that you offset the carbon used by this contract
   * @param _amount to be retired
   */
  function retireTCO2(uint256 _amount) public {
    // require that this is called by the owner
    require(owner == msg.sender, "You can't call unless you are the contract owner.");

    // require that the contract owns an amount at least equal to the amount we are trying to retire
    require(_amount <= tokenBalances[tco2Address], "You don't have enough TCO2 of this kind.");

    // calculate footprint
    footprint = _calculateFootprint(_amount);

    // use the TCO contract to retire TCO2
    ToucanCarbonOffsets(tco2Address).retire(footprint);

    // reduce amount of TCO2 in the balance sheet of this contract
    tokenBalances[tco2Address] -= _amount;
  }
}
