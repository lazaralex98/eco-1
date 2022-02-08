import { ethers } from "hardhat";
import {
  BaseCarbonTonne,
  ContractOffsetterPOC,
  ToucanCarbonOffsets,
} from "../typechain";
import { ContractTransaction } from "ethers";

const deposit = async (
  tokenContract: ToucanCarbonOffsets | BaseCarbonTonne,
  cop: ContractOffsetterPOC,
  tokenAddress: string,
  amount: string
): Promise<ContractTransaction> => {
  // first we use have the TCO2 contract approve up to 1 unit to be used by the COP contract
  await (
    await tokenContract.approve(cop.address, ethers.utils.parseEther(amount))
  ).wait();

  // we then deposit TCO2 into the COP contract
  const depositTxn = await cop.deposit(
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
