//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
// TODO: Hardhat doesn't support imports via https and copying all needed contracts is tedious
import "https://github.com/CO2ken/contracts/blob/602ac834cd18b6bd9d863ed8c5b6f9be9efa9fc0/contracts/ToucanCarbonOffsets.sol";

/**
 * TODO: NEED CLARITY #3. there is this repo eth-co2 (https://github.com/CO2ken/eth-co2)
 * for carbon offsetting on Ethereum. I wonder why was it discontinued and if it would be of interest.
 */

contract WTCO2 is ToucanCarbonOffsets {
  uint256 private footprint;

  string public name = "Wrapped TCO2";
  string public symbol = "WTCO2";
  uint8 public decimals = 18;

  event Deposit(address indexed sender, uint256 amount);
  event Withdrawal(address indexed recipient, uint256 amount);

  // TODO this is hardcoded for now
  function calculateFootprint() public pure returns (uint256) {
    return 10;
  }

  /**
   * whenever you wrap the TCO2 token, we calculate the footprint,
   * mint an equal amount of WTCO2 and retire and equal amount of TCO2
   */
  function deposit() public payable {
    footprint = calculateFootprint();

    _mint(msg.sender, msg.value);
    retire(footprint);

    emit Deposit(msg.sender, msg.value);
  }

  /**
   * TODO: NEED CLARITY #2. In a normal wrapped token, whenever you unwrap the WTCO2 token,
   * you burn the WTCO2 token and transfer back the helpd TCO2. But, I think in this project that
   * wouldn't be something we want to do, as we have burned (retired) the TCO2 tokens upon wrapping.
   */
  function withdraw(uint256 amount) public {
    require(balanceOf(msg.sender) >= amount);
    address payable recipient = msg.sender;
    _burn(msg.sender, amount);
    recipient.transfer(amount);
    emit Withdrawal(recipient, amount);
  }

  function withdraw(uint256 amount, address payable recipient) public {
    require(balanceOf(msg.sender) >= amount);
    recipient.transfer(amount);
    _burn(msg.sender, amount);
    emit Withdrawal(recipient, amount);
  }
}
