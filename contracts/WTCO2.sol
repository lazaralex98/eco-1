//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// TODO: how do you even import these with hardhat?!?
import "https://github.com/CO2ken/contracts/blob/602ac834cd18b6bd9d863ed8c5b6f9be9efa9fc0/contracts/ToucanCarbonOffsets.sol#L221";
import "https://github.com/CO2ken/contracts/blob/602ac834cd18b6bd9d863ed8c5b6f9be9efa9fc0/contracts/pools/BaseCarbonTonne.sol#L362";
import "https://github.com/sushiswap/sushiswap/blob/canary/contracts/SushiMaker.sol";

contract WTCO2 is ToucanCarbonOffsets {
  uint256 private footprint;
  address private sushiMakerAddress = "0xf1c9881Be22EBF108B8927c4d197d126346b5036";
  address private baseCarbonTonneAddress = "";

  // TODO: this is hardcoded for now
  function calculateFootprint() public pure returns (uint256) {
    return 10;
  }

  function deposit(uint256 _amount, address _receivedToken) public payable {
    if (
      // TODO: how do I even check this?!? ETH is not a token 🤯
      _receivedToken == "TODO_ETH_address" ||
      _receivedToken == "TODO_MATIC_address" ||
      _receivedToken == "TODO_USDC_address"
    ) {
      /**
       * TODO: my though for doing this is to instantiate SushiMaker and use it to convert ETH to BCT.
       * the problem with that is I need access to the _swap() method
       */
      SushiMaker sushi = SushiMaker(sushiMakerAddress);
      sushi.convert(_receivedToken, baseCarbonTonneAddress);
    
    } else if (_receivedToken == baseCarbonTonneAddress) {
      footprint = calculateFootprint();

      /**
       * TODO: same as above, I figured I should instantiate BCT and use that to redeem TCO2.
       * BCT for TCO2 using BaseCarbonTonne.redeemMany(). Marcel
       */
      BaseCarbonTonne bct = BaseCarbonTonne(baseCarbonTonneAddress);

      // TODO retire TCO2
      retire(footprint);
    }
}
