//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// TODO: how do you even import from https with hardhat?!?
import "https://github.com/CO2ken/contracts/blob/602ac834cd18b6bd9d863ed8c5b6f9be9efa9fc0/contracts/ToucanCarbonOffsets.sol#L221";
import "https://github.com/CO2ken/contracts/blob/602ac834cd18b6bd9d863ed8c5b6f9be9efa9fc0/contracts/pools/BaseCarbonTonne.sol#L362";
import "https://github.com/sushiswap/sushiswap/blob/canary/contracts/SushiMaker.sol";

contract WTCO2 {
  uint256 private footprint;
  uint256 private tcoAddress = "TODO insert TCO2 address";
  ToucanCarbonOffsets public tco;
  event Retirement(address indexed sender, uint256 amount);

  constructor() public {
    tco = new ToucanCarbonOffsets();
  }

  // TODO: this is hardcoded for now
  function calculateFootprint(uint256 _tokenAmount)
    public
    pure
    returns (uint256)
  {
    return _tokenAmount;
  }

  /**
   * Takes in an amount of TCO2, calculates the footprint and retires
   * an amount of TCO2 equivalent to the footprint
   */
  function retireTCO2(uint256 _amount) external payable {
    // requirements to make sure we did receive TCO2 tokens
    require(_amount > 0, "You need at least a few tokens");
    uint256 allowance = tco.allowance(msg.sender, address(this));
    require(allowance >= _amount, "Check the token allowance");

    // calculate footprint
    footprint = calculateFootprint(_amount);

    // transfer TCO2 to this contract
    tco.transferFrom(msg.sender, address(this), _amount);
    msg.sender.transfer(_amount);

    // retire an amount of TCO2 equal to the calculated footprint
    tco.retire(footprint);

    // emit a Retirement event
    emit Retirement(msg.sender, footprint);
  }
}
