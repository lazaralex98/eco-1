import { ethers } from "hardhat";
import { BaseCarbonTonne, DEX, ToucanCarbonOffsets } from "../typechain";
import { ContractTransaction } from "ethers";

const deposit = async (
  tokenContract: ToucanCarbonOffsets | BaseCarbonTonne,
  dex: DEX,
  tokenAddress: string,
  amount: string
): Promise<ContractTransaction> => {
  // first we use have the TCO2 contract approve up to 1 unit to be used by the DEX contract
  await tokenContract.approve(dex.address, ethers.utils.parseEther(amount));

  // we then deposit 1 unit of TCO2 into the DEX contract
  const depositTxn = await dex.deposit(
    tokenAddress,
    ethers.utils.parseEther(amount),
    {
      gasLimit: 1200000,
    }
  );
  await depositTxn.wait();
  return depositTxn;
};

export default deposit;
