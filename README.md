# A contract that can be used to offset transactions of other addresses

If you are curious about the dapp to interact with this contract [you have a repo here](https://github.com/lazaralex98/contract-offsetter-ui). Also, here is [a link to the ContractOffseter polygonscan here](https://mumbai.polygonscan.com/address/0x4F828CeDAfcBa0cDd2d9Ace14caFfb0b1FaF9199).

In this README I will describe the `ContractOffsetter`, and NOT the `ContractOffsetterPOC`. For a [description of the POC itself go here](https://www.alexlazar.dev/posts/contract-offsetter-poc) (or [here](https://github.com/lazaralex98/alexlazar.dev/blob/main/_posts/contract-offsetter-poc.md)) and for [a description of the dapp go here](https://github.com/lazaralex98/contract-offsetter-ui/blob/main/README.md).

## Let's first describe the overall flow

Anyone can use the contract to deposit BCT or TCO2, redeem deposited BCT for TCO2 of their choice, and offset a footprint of their choice

The contract uses `IToucanContractRegistry` and a private `checkTokenEligibility()` method so that users may only use BCT or TCO2.

One thing that is of note, if you've taken a look at the `ContractOffsetterPOC` before, is that this implementation **does not** calculate or store your footprint (or other contracts' footprint).

The reason is that we have decided calculating footprint is far easier post-transaction.

Moving on, there are 3 main methods that this contracth as:

- `deposit()`
- `redeemBCT()`
- `offset()`

Let's pick them one at a time.

## deposit()
