//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
// I've no idea how to import from Github. So I just copied these contracts over
import "./CO2KEN_contracts/ToucanCarbonOffsets.sol";
import "./CO2KEN_contracts/pools/BaseCarbonTonne.sol";

contract DEX {
  uint256 private footprint;
  ToucanCarbonOffsets public tco;
  event Retirement(address indexed sender, uint256 amount);

  constructor() {
    tco = new ToucanCarbonOffsets();
  }

  // TODO: this is hardcoded for now
  function calculateFootprint(uint256 _amount) public pure returns (uint256) {
    return _amount;
  }

  /**
   * Takes in an amount of TCO2, calculates the footprint and retires
   * an amount of TCO2 equivalent to the footprint
   */
  function retireTCO2() public payable {
    uint256 amountReceived = msg.value;
    uint256 wtcoBalance = tco.balanceOf(address(this));

    // requirements to make sure we did receive TCO2 tokens
    require(amountReceived > 0, "You need to send some ether");
    require(amountReceived <= wtcoBalance, "Not enough tokens in the reserve");

    // calculate footprint
    footprint = calculateFootprint(amountReceived);

    tco.transfer(msg.sender, footprint);

    // retire an amount of TCO2 equal to the calculated footprint
    tco.retire(footprint);

    // emit a Retirement event
    emit Retirement(msg.sender, footprint);
  }
}
