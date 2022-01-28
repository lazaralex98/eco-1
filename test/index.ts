import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { BigNumber } from "ethers";
import { ethers } from "hardhat";
// eslint-disable-next-line node/no-missing-import,camelcase
import { DEX, DEX__factory } from "../typechain";

// Mumbai network address
const tco2Address: string = "0x788d12e9f6E5D65a0Fa4C3f5D6AA34Ef39A6E582";

describe("DEX", function () {
  let dex: DEX;
  let owner: SignerWithAddress;
  let addr1: SignerWithAddress;
  let addr2: SignerWithAddress;
  let addrs: SignerWithAddress[];

  beforeEach(async function () {
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

    const dexFactory = (await ethers.getContractFactory(
      "DEX",
      owner
      // eslint-disable-next-line camelcase
    )) as DEX__factory;
    dex = await dexFactory.deploy();
  });

  describe("Deposit", function () {
    it("Should deposit 1 TCO2", async function () {
      const depositTxn = await dex.deposit(tco2Address, 1, {
        gasLimit: 1200000,
      });
      await depositTxn.wait();
      expect(depositTxn).to.equal(2);
      const balance = await dex.getTokenBalance(tco2Address);
      expect(balance).to.equal(1);
    });
  });
});
