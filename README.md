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

Next up, it updates the `balances` which is a nested mapping with the following structure: **`user => (token => amount)`**.

And it lastly emits an event.

## redeemBCT()

```solidity
function redeemBCT(address _desiredTCO2, uint256 _amount) public {
  require(
    _amount <= balances[msg.sender][bctAddress],
    "You don't have enough BCT in this contract."
  );

  bool eligibility = checkTokenEligibility(_desiredTCO2);
  require(eligibility, "Can't redeem BCT for this token.");

  // prepare/format params for BCT.retireMany() method
  address[] memory tco2Addresses = new address[](1);
  uint256[] memory amounts = new uint256[](1);
  tco2Addresses[0] = _desiredTCO2;
  amounts[0] = _amount;

  // send BCT, receive TCO2
  BaseCarbonTonne(bctAddress).redeemMany(tco2Addresses, amounts);

  // modify balance sheets of this contract
  balances[msg.sender][bctAddress] -= _amount;
  balances[msg.sender][_desiredTCO2] += _amount;

  emit Redeemed(msg.sender, _desiredTCO2, _amount);
}

```

This function takes in as parameters the address of the TCO2 token the user desires to receive upon redeeming and the amount of BCT he wants to redeem.

First, we run some basic checks to ensure the user has deposited enough BCT in the `ContractOffsetter` to redeem it and to make sure that the TCO2 he desires is valid.

After that, we format the parameters he has given us in arrays. That's what the `redeemMany()` method from the `BaseCarbonTonne` requires us to pass.

We use this `redeemMany()` method to burn the BCT the user has within `ContractOffsetter` and to `safeTransfer()` the TCO2 into `ContractOffsetter`. (These are things you can see within the `BaseCarbonTonne` contract)

If all that was successful, we update the `balances` mapping to reflect the changes and emit an event.

## offset()

```solidity
function offset(
  address _tco2Address,
  uint256 _amount,
  address _offsetAddress,
  uint256 _nonce
) public {
  bool eligibility = checkTokenEligibility(_tco2Address);
  require(eligibility, "Can't retire this token.");

  require(
    _amount <= balances[msg.sender][_tco2Address],
    "You don't have enough of this TCO2 (in the contract)."
  );

  // use the TCO contract to retire TCO2
  ToucanCarbonOffsets(_tco2Address).retire(_amount);

  // reduce amount of TCO2 in the balance sheet
  balances[msg.sender][_tco2Address] -= _amount;

  // set new last offset nonce
  lastOffsetNonce[_offsetAddress] = _nonce;

  emit Offset(msg.sender, _tco2Address, _amount, _offsetAddress, _nonce);
}

```

This function takes in quite a few parameters: the address of the TCO2 token to be retired, the amount of TCO2 to retire, the address that will have its footprint offset, and the nonce up to which we are offsetting.

We first require token eligibility and that the user has enough TCO2 to offset.

Then, the important part, we call the `retire()` method of the `ToucanCarbonOffsets` contract.

This method **burns the TCO2 tokens we provided** (and updates a balance of how much TCO2 the `ContractOffsetter` has ever retired and emits an event).

If all that was successful, we update the `balances` mapping to reflect the changes.

We also update the `lastOffsetNonce` mapping which has the following structure: **`user/contract => nonce of last offset`** and remembers up until which transaction we have offset an address' footprint.

Lastly, we emit an event.

## Other, 'less important' methods
