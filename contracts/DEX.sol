//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
// You can't import contracts via https from GH. So I just copied these contracts over.
// You could use NPM publish, but this works for now.
import "./CO2KEN_contracts/ToucanCarbonOffsets.sol";
import "./CO2KEN_contracts/pools/BaseCarbonTonne.sol";

/* TODO (long term structure)
 * receive WETH, MATIC, USDC or BCT
 *  if WETH, MATIC or USDC -> buy BCT from Sushiswap
 *  if BCT -> redeem BCT for TCO2 -> retire TCO2
 */
contract DEX {
  uint256 private footprint;
  mapping(address => uint256) public tokenBalances;
  event Deposited(address erc20Addr, uint256 amount);
  // this is the address for Mumbai
  address constant private tco2Address = "0xf2438A14f668b1bbA53408346288f3d7C71c10a1";
  address private owner;

  constructor ()  {
    owner = msg.sender;
  }

  // TODO: this is hardcoded for now, but it should do some carbon emission math to return the footprint
  function _calculateFootprint(uint256 _amount) private pure returns (uint256) {
    return _amount;
  }

  /* @notice Internal function that checks if token to be deposited is eligible for this pool
   * this can be changed in the future to contain other tokens
   * @param _erc20Address ERC20 contract address to be checked
   */
  function checkEligible(address _erc20Address) {
    if (_erc20Address == tco2Address) return true;
    return false;
  }

  /* @notice function to deposit tokens from user to this contract
   * @param _erc20Address ERC20 contract address to be deposited
   * @param _amount amount to be deposited
   * in the long run, this will modified to adapt to the structure mentioned above
   */
  function deposit(address _erc20Address, uint256 _amount) public {
    // check token eligibility
    require(checkEligible(_erc20Address), "Token rejected");

    // use TCO contract to do a safe transfer from the user to this contract
    IERC20(_erc20Address).safeTransferFrom(msg.sender, address(this), _amount);

    // add amount of said token to balance sheet of this contract
    tokenBalances[_erc20Address] += _amount;

    // emit an event for good measure
    emit Deposited(_erc20Address, _amount);
  }

  /* @notice retires that amount from its balance
   * @param _amount to be retired
   * TODO: question. Should users be able to call this if they are not the owner of the contract?
   */
  function retireTCO2(uint256 _amount) public {
//    require(msg.sender == owner, "Only use this if you are the contract owner.");

    require(_amount <= tokenBalances[tco2Address], "Can't retire more than we hold.");

    footprint = _calculateFootprint(_amount);

    ToucanCarbonOffsets(_erc20Address).retire(footprint);
  }
}
