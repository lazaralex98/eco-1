A dapp that calculates footprint on the frontend.

User connects wallet and he gets to a dashboard that shows him his address and his balance sheet within the `ContractOffsetter` contract (any BCT, TCO2 that he may have deposited).

In this dashboard, the user shall have a few options:

1. deposit BCT/TCO2
2. redeem BCT for TCO2
3. offset emissions

The first 2 are fairly straightforward (I could have different pages for each), let's discuss #3.

User clicks on "load my transactions" and a `loadTransactions()` function:

1. loads (and renders) all his transactions
2. parses all gas for these transactions
3. multiplies that by an emission factor to get the overall_emmissions and renders this overall_emmissions as well
   (I’ll use the 0.00000036 TCO2 per transaction number we came up with)

The user can also use a form to load transactions of another wallet/contract. (There could be a separate page for each address)

Once the user has a view of all transactions for his address of choice, he should have an "Offset All" btn that will run a `offsetAll()` function.

The `offsetAll()` function will interact with the `ContractOffsetter` contract to offset an amount of TCO2 equal to overall_emmissions.

It's SUPER IMPORTANT to edit the contract such that it remembers which nonces were offset. I think a nested mapping in the contract could work. It could look like: `user/contract => (nonce => true/false)`. I think the `offset()` method in the contract would need to take in the nonces as an array of uints?

This opens up the possibility to offset any one specific transaction or range of transactions. (I'm not going to build the UI for this yet, I think, but it's an option for the future)

I think the emitted event of the `offset()` method should become a bit more intricate. It should have:

1. the address that did the offsetting
2. the address of the TCO2 that was used
3. a uint representing how much was offset
4. the address that had the offsetting done to it
5. an array of the nonces that were offset

All this does away with the `addContract()` and `addEvents()` methods.

Things may change as I build, especially since I'm on a tight timeline.
