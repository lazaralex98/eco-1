import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";
// eslint-disable-next-line node/no-missing-import,camelcase
import { DEX, DEX__factory, ToucanCarbonOffsets } from "../typechain";
import * as tcoAbi from "../artifacts/contracts/CO2KEN_contracts/ToucanCarbonOffsets.sol/ToucanCarbonOffsets.json";

// this is the TCO2 address from the test.toucan.earth/contracts list for Mumbai network
// const tco2Address: string = "0x788d12e9f6E5D65a0Fa4C3f5D6AA34Ef39A6E582";

// this is my TCO2 address from my test project (Yingpeng HFC23 Decompostion Project)
const tco2Address: string = "0xa5831eb637dff307395b5183c86B04c69C518681";

describe("DEX", function () {
  let dex: DEX;
  let tco: ToucanCarbonOffsets;
  let owner: SignerWithAddress;
  let addr1: SignerWithAddress;
  let addr2: SignerWithAddress;
  let addrs: SignerWithAddress[];

  beforeEach(async function () {
    // we get a bunch of signers to be used
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

    // we deploy a DEX contract
    const dexFactory = (await ethers.getContractFactory(
      "DEX",
      owner
      // eslint-disable-next-line camelcase
    )) as DEX__factory;
    dex = await dexFactory.deploy(tco2Address);

    // @ts-ignore and we instantiate a portal to my TCO2 contract
    tco = new ethers.Contract(tco2Address, tcoAbi.abi, owner);
  });

  // TODO Why is it taking sooo looong?!? (sometimes up to 6 minutes)
  describe("Deposit", function () {
    it("Should deposit 1 TCO2", async function () {
      // first we use have the TCO2 contract approve up to 1 unit to be used by the DEX contract
      tco.approve(dex.address, ethers.utils.parseEther("1"));

      // we then deposit 1 unit of TCO2 into the DEX contract
      const depositTxn = await dex.deposit(
        tco2Address,
        ethers.utils.parseEther("1"),
        {
          gasLimit: 1200000,
        }
      );
      await depositTxn.wait();

      // TODO sometimes I'm getting a code=REPLACEMENT_UNDERPRICED

      // if everything goes well,
      const balance = await dex.getTokenBalance(tco2Address);
      expect(ethers.utils.formatEther(balance)).to.eql("1.0");
    });
  });
});
