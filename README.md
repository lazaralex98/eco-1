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

Let's pick them one at a time. We'll tackle the less important ones at the end.

## deposit()

```solidity
function deposit(address _erc20Address, uint256 _amount) public {
  bool eligibility = checkTokenEligibility(_erc20Address);
  require(eligibility, "Can't deposit this token");

  // use token's contract to do a safe transfer from the user to this contract
  // remember that the user has to approve this in the frontend
  IERC20(_erc20Address).safeTransferFrom(msg.sender, address(this), _amount);

  // add amount of said token to balance of this user in this contract
  balances[msg.sender][_erc20Address] += _amount;

  emit Deposited(msg.sender, _erc20Address, _amount);
}

```

This function takes in as parameters the address of the token and the amount to be deposited.

It checks the token for eligibility and then uses the `safeTransferFrom()` method of the `SafeERC20` OpenZeppelin contract.

_Side note: it's important to know that whoever calls this method has to first approve the `ContractOffseter` from the contract of the token to be deposited._

Next up, it updates the `balances` which is a nested mapping with the following structure: **user => (token => amount)**.

And it lastly emits an event.
