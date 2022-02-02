import { ethers } from "hardhat";
import { DEX, ToucanCarbonOffsets } from "../typechain";
import { ContractTransaction } from "ethers";

const retire = async (
  tco: ToucanCarbonOffsets,
  dex: DEX,
  tco2Address: string,
  amount: string
): Promise<ContractTransaction> => {
  const retireTxn = await dex.retireTCO2(ethers.utils.parseEther(amount), {
    gasLimit: 1200000,
  });
  await retireTxn.wait();
  return retireTxn;
};

export default retire;
