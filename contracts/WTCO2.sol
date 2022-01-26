//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
// I've no idea how to import from Github. So I just copied these contracts over
import "./CO2KEN_contracts/ToucanCarbonOffsets.sol";
import "./CO2KEN_contracts/pools/BaseCarbonTonne.sol";

contract WTCO2 {
  uint256 private footprint;
  ToucanCarbonOffsets public tco;
  event Retirement(address indexed sender, uint256 amount);

  constructor() {
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
  function retireTCO2(uint256 _amount) public payable {
    // requirements to make sure we did receive TCO2 tokens
    require(_amount > 0, "You need at least a few tokens");
    uint256 allowance = tco.allowance(msg.sender, address(this));
    require(allowance >= _amount, "Check the token allowance");

    // calculate footprint
    footprint = calculateFootprint(_amount);

    // transfer TCO2 to this contract
    tco.transferFrom(msg.sender, address(this), _amount);
    tco.transfer(address(this), _amount);

    // retire an amount of TCO2 equal to the calculated footprint
    tco.retire(footprint);

    // emit a Retirement event
    emit Retirement(msg.sender, footprint);
  }
}
