import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers, network } from "hardhat";
// eslint-disable-next-line node/no-missing-import,camelcase
import { DEX, DEX__factory, ToucanCarbonOffsets } from "../typechain";
import * as tcoAbi from "../artifacts/contracts/CO2KEN_contracts/ToucanCarbonOffsets.sol/ToucanCarbonOffsets.json";
import deposit from "../utils/deposit";
import retire from "../utils/retire";
import { BigNumber } from "ethers";

// this is the TCO2 address from the test.toucan.earth/contracts list for Mumbai network
// const tco2Address: string = "0x788d12e9f6E5D65a0Fa4C3f5D6AA34Ef39A6E582";

/**
 * This is my the address of my TCO2 coins.
 * I got it from my test project (Yingpeng HFC23 Decompostion Project).
 */
const tco2Address: string = "0xa5831eb637dff307395b5183c86B04c69C518681";
// and this is the address that I wish to deploy from
const myAddress: string = "0x721F6f7A29b99CbdE1F18C4AA7D7AEb31eb2923B";

// TODO implement tests with .to.be.revertedWith

describe("DEX", function () {
  let dex: DEX;
  let tco: ToucanCarbonOffsets;
  let owner: SignerWithAddress;

  beforeEach(async function () {
    /**
     * if we are forking Mumbai (which I chose to do for performance, so I can test & iterate faster)
     * we impersonate my Mumbai account (I have TCO2, BCT & MATIC on it at the blockNumber I chose)
     */
    if (network.name === "hardhat") {
      await network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [myAddress],
      });
    }

    // we get a signer based on my above address
    owner = await ethers.getSigner(myAddress);

    // we deploy a DEX contract and get a portal to it
    const dexFactory = (await ethers.getContractFactory(
      "DEX",
      owner
      // eslint-disable-next-line camelcase
    )) as DEX__factory;
    dex = await dexFactory.deploy(tco2Address);

    // we instantiate a portal to my TCO2 contract
    // @ts-ignore
    tco = new ethers.Contract(tco2Address, tcoAbi.abi, owner);
  });

  describe("Deposit", function () {
    it("Should deposit 1 TCO2", async function () {
      const amountToDeposit = "1.0";

      /**
       * we check my TCO2 before depositing some of it
       */
      const myTcoBalanceBefore = await tco.balanceOf(myAddress);

      /**
       * we attempt to deposit an amount of TCO2 into the DEX contract.
       * I have separated in the deposit() function for readability
       */
      const depositTxn = await deposit(tco, dex, tco2Address, amountToDeposit);
      expect(depositTxn.confirmations).to.be.above(0);

      /**
       * we check the my TCO2 balance after depositing some of it
       * and we are expecting it to be less by the deposited amount
       */
      const myTcoBalanceAfter = await tco.balanceOf(myAddress);
      const expectedTcoBalance = myTcoBalanceBefore.sub(
        ethers.utils.parseEther(amountToDeposit)
      );
      expect(myTcoBalanceAfter).to.eql(expectedTcoBalance);

      /**
       * we check the TCO2 balance of the contract to see if it changed.
       * Normally it should be equal to 1.0 as we redeploy a new DEX contract before each test.
       */
      const dexTcoBalance = await dex.getTokenBalance(tco2Address);
      expect(ethers.utils.formatEther(dexTcoBalance)).to.eql("1.0");
    });
  });

  describe("Retire TCO2", function () {
    it("Should retire 1 TCO2", async function () {
      const amountToRetire = "1.0";

      /**
       * we check the total TCO2 supply before depositing and retiring some of it
       */
      const tcoSupplyBefore = await tco.totalSupply();

      /**
       * we deposit an amount of TCO2 to the DEX contract and then get the balance of the DEX contract.
       * we are expecting it to be equal to the amountToRetire as we redeploy a new DEX contract before each test.
       */
      await deposit(tco, dex, tco2Address, amountToRetire);
      const initialContractBalance = await dex.getTokenBalance(tco2Address);
      expect(ethers.utils.formatEther(initialContractBalance)).to.eql(
        amountToRetire
      );

      /**
       * we attempt to retire TCO2 from the DEX contract and check for txn confirmations.
       * I separated this into another function for readability
       */
      const retireTxn = await retire(tco, dex, tco2Address, amountToRetire);
      expect(retireTxn.confirmations).to.be.above(0);

      /**
       * we check the total TCO2 supply after depositing and retiring some of it
       * and we expect it to be less by the amount to be retired
       */
      const tcoSupplyAfter = await tco.totalSupply();
      const expectedTcoSupply = tcoSupplyBefore.sub(
        ethers.utils.parseEther(amountToRetire)
      );
      expect(tcoSupplyAfter).to.eql(expectedTcoSupply);

      /**
       * we check the DEX contract's TCO2 balance after the operations were done
       */
      const contractBalanceAfter = await dex.getTokenBalance(tco2Address);
      expect(ethers.utils.formatEther(contractBalanceAfter)).to.eql("0.0");
    });
  });
});
