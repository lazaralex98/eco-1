import { expect } from "chai";
import { ethers } from "hardhat";

/**
 * TODO: obviously all this is not working because I have no artifacts because I cannot compile
 * BECAUSE I cannot import the needed contracts via https
 */

describe("WTCO2", function () {
  let wtco2: WTCO2;
  let owner: SignerWithAddress;
  let addr1: SignerWithAddress;
  let addr2: SignerWithAddress;
  let addrs: SignerWithAddress[];

  beforeEach(async function () {
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

    const wtco2Factory = (await ethers.getContractFactory(
      "WTCO2",
      owner
    )) as WTCO2__factory;
    wtco2 = await wtco2Factory.deploy();
  });

  describe("Deployment", function () {
    it("Should ...", async function () {
      /**
       * TODO: I can test the user's balance, or the total supply, etc to see if retirement worked
       */
      await wtco2.retireTCO2(10);
      expect("A").to.equal("B");
    });
  });
});
