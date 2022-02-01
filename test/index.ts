import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";
// eslint-disable-next-line node/no-missing-import,camelcase
import { DEX, DEX__factory, ToucanCarbonOffsets } from "../typechain";
import * as tcoAbi from "../artifacts/contracts/CO2KEN_contracts/ToucanCarbonOffsets.sol/ToucanCarbonOffsets.json";

// Mumbai network address
// const tco2Address: string = "0x788d12e9f6E5D65a0Fa4C3f5D6AA34Ef39A6E582"; // this is the one from the list
const tco2Address: string = "0xa5831eb637dff307395b5183c86B04c69C518681"; // this is the one I have

describe("DEX", function () {
  let dex: DEX;
  let tco: ToucanCarbonOffsets;
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
    dex = await dexFactory.deploy(tco2Address);

    // @ts-ignore
    tco = new ethers.Contract(tco2Address, tcoAbi.abi, owner);
  });

  describe("TCO2", function () {
    // TODO why does this take so loong ?!?
    return;
    // eslint-disable-next-line no-unreachable
    it("Allowance should be above 1", async function () {
      const txn = await tco.increaseAllowance(
        owner.address,
        ethers.utils.parseEther("1")
      );
      await txn.wait();
      const allowance = await tco.allowance(owner.address, owner.address);
      expect(parseFloat(ethers.utils.formatEther(allowance))).to.be.above(1);
    });
  });

  describe("Deposit", function () {
    it("Should deposit 1 TCO2", async function () {
      const depositTxn = await dex.deposit(
        tco2Address,
        ethers.utils.parseEther("1"),
        {
          gasLimit: 1200000,
        }
      );
      await depositTxn.wait();
      expect(depositTxn).to.eql(2);
    });
  });
});
