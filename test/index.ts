import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers, network } from "hardhat";
// eslint-disable-next-line node/no-missing-import,camelcase
import {
  BaseCarbonTonne,
  ContractOffsetterPOC,
  // eslint-disable-next-line camelcase
  ContractOffsetterPOC__factory,
  ToucanCarbonOffsets,
} from "../typechain";
import * as tcoAbi from "../artifacts/contracts/CO2KEN_contracts/ToucanCarbonOffsets.sol/ToucanCarbonOffsets.json";
import * as bctAbi from "../artifacts/contracts/CO2KEN_contracts/pools/BaseCarbonTonne.sol/BaseCarbonTonne.json";
import deposit from "../utils/deposit";
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
const bctAddress: string = "0xf2438A14f668b1bbA53408346288f3d7C71c10a1";

// TODO most tests shall be redone for new contract structure

describe("Contract Offsetter POC", function () {
  let cop: ContractOffsetterPOC;
  let tco: ToucanCarbonOffsets;
  let bct: BaseCarbonTonne;
  let owner: SignerWithAddress;
  let addr1: SignerWithAddress;
  let addr2: SignerWithAddress;
  let addrs: SignerWithAddress[];

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

    // we get a signer based on my above address (I have TCO2, BCT & MATIC on it at the blockNumber I chose)
    owner = await ethers.getSigner(myAddress);
    // and we get a bunch of other random signers
    [addr1, addr2, ...addrs] = await ethers.getSigners();

    // we deploy a DEX contract and get a portal to it
    const copFactory = (await ethers.getContractFactory(
      "ContractOffsetterPOC",
      owner
      // eslint-disable-next-line camelcase
    )) as ContractOffsetterPOC__factory;
    cop = await copFactory.deploy();

    // we instantiate a portal to my TCO2 contract
    // @ts-ignore
    tco = new ethers.Contract(tco2Address, tcoAbi.abi, owner);

    // we instantiate a portal to BCT
    // @ts-ignore
    bct = new ethers.Contract(bctAddress, bctAbi.abi, owner);
  });

  describe("Deposit", function () {
    /**
     * We're depositing 1 TCO2 to a newly deployed contract, empty contract
     */
    it("Should deposit 1 TCO2", async function () {
      await deposit(tco, cop, tco2Address, "1.0");

      const balance = await cop.balances(myAddress, tco2Address);
      expect(ethers.utils.formatEther(balance)).to.eql("1.0");
    });

    it("Should deposit 1 BCT", async function () {
      await deposit(bct, cop, bctAddress, "1.0");

      const balance = await cop.balances(myAddress, bctAddress);
      expect(ethers.utils.formatEther(balance)).to.eql("1.0");
    });
  });

  describe("redeemBCT", function () {
    it("Should redeem 1 BCT for 1 TCO2", async function () {
      await deposit(bct, cop, bctAddress, "10.0");

      const redeemTxn = await cop.redeemBCT(
        tco2Address,
        ethers.utils.parseEther("1.0")
      );
      await redeemTxn.wait();

      const bctBalance = await cop.balances(myAddress, bctAddress);
      expect(ethers.utils.formatEther(bctBalance)).to.eql("9.0");

      const tcoBalance = await cop.balances(myAddress, tco2Address);
      expect(ethers.utils.formatEther(tcoBalance)).to.eql("1.0");
    });

    it("Should be reverted with 'You don't have enough BCT in this contract.'", async function () {
      await deposit(bct, cop, bctAddress, "0.5");

      await expect(
        cop.redeemBCT(tco2Address, ethers.utils.parseEther("10.0"))
      ).to.be.revertedWith("You don't have enough BCT in this contract.");
    });

    it("Should be reverted with 'Can't redeem BCT for this token.", async function () {});
  });

  describe("selfOffset", function () {
    it("Should retire all TCO2 & footprint should be 0", async function () {
      expect(
        ethers.utils.formatEther(await cop.footprints(myAddress))
      ).to.be.eql("0.0");

      await deposit(bct, cop, bctAddress, "100.0");

      const redeemTxn = await cop.redeemBCT(
        tco2Address,
        ethers.utils.parseEther("10.0")
      );
      await redeemTxn.wait();

      // TODO this shouldn't be 0.0; _updateFootpring() might not work
      expect(
        ethers.utils.formatEther(await cop.footprints(myAddress))
      ).to.be.eql("213.0");

      const offsetTxn = await cop["selfOffset(address)"](tco2Address);
      await offsetTxn.wait();

      expect(
        ethers.utils.formatEther(await cop.footprints(myAddress))
      ).to.be.eql("0.0");
    });

    it("Should retire 1 TCO2 & footprint should be less by 1", async function () {});

    it("Should be reverted with 'Can't retire this token.'", async function () {});

    it("Should be reverted with 'You don't have enough of this TCO2 (in the contract).'", async function () {});

    it("Should be reverted with 'You can't offset more than your footprint.'", async function () {
      await deposit(bct, cop, bctAddress, "15.0");

      const redeemTxn = await cop.redeemBCT(
        tco2Address,
        ethers.utils.parseEther("10.0")
      );
      await redeemTxn.wait();

      await expect(
        cop["selfOffset(address,uint256)"](
          tco2Address,
          ethers.utils.parseEther("2.0")
        )
      ).to.be.revertedWith("You can't offset more than your footprint.");
    });
  });
});
