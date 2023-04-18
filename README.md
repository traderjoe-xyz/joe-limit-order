# [Joe Limit Order](https://github.com/traderjoe-xyz/joe-limit-order)

This repository contains the Joe Limit Order contract.

### [LimitOrderManager](./src/LimitOrderManager.sol)

This contracts allows users to place limit orders using the Liquidity Book protocol.
It allows to create orders for any Liquidity Book pair V2.1.

The flow of the Limit Order Manager is the following:

- Users create orders for a specific pair, type (bid or ask), price (bin id) and amount
  (in token Y for bid orders and token X for ask orders) which will be added to the liquidity book pair.
- Users can cancel orders, which will remove the liquidity from the liquidity book pair according to the order amount
  and send the token amounts back to the user (the amounts depend on the bin composition).
- Users can execute orders, which will remove the liquidity from the order and send the token to the
  Limit Order Manager contract.
- Users can claim their executed orders, which will send a portion of the token received from the execution
  to the user (the share depends on the total executed amount of the orders).

Users can place orders using the `placeOrder` function by specifying the following parameters:

- `tokenX`: the token X of the liquidity book pair
- `tokenY`: the token Y of the liquidity book pair
- `binStep`: the bin step of the liquidity book pair
- `orderType`: the order type (bid or ask)
- `binId`: the bin id of the order, which is the price of the order
- `amount`: the amount of token to be used for the order, in token Y for bid orders and token X for ask orders
  Orders can't be placed in the active bin id. Bid orders need to be placed in a bin id greater than the active id,
  while ask orders need to be placed in a bin id lower than the active bin id.

Users can cancel orders using the `cancelOrder` function by specifying the same parameters as for `placeOrder` but
without the `amount` parameter.
If the order is already executed, it can't be cancelled, and user will need to claim the filled amount.
If the user is trying to cancel an order that is inside the active bin id, he may receive a partially filled order,
according to the active bin composition.

Users can claim orders using the `claimOrder` function by specifying the same parameters as for `placeOrder` but
without the `amount` parameter.
If the order is not already executed, but that it can be executed, it will be executed first and then claimed.
If the order isn't executable, it can't be claimed and the transaction will revert.
If the order is already executed, the user will receive the filled amount.

Users can execute orders using the `executeOrder` function by specifying the same parameters as for `placeOrder` but
without the `amount` parameter.
If the order can't be executed or if it is already executed, the transaction will revert.

## Install foundry

Foundry documentation can be found [here](https://book.getfoundry.sh/forge/index.html).

### On Linux and macOS

Open your terminal and type in the following command:

```
curl -L https://foundry.paradigm.xyz | bash
```

This will download foundryup. Then install Foundry by running:

```
foundryup
```

To update foundry after installation, simply run `foundryup` again, and it will update to the latest Foundry release.
You can also revert to a specific version of Foundry with `foundryup -v $VERSION`.

### On Windows

If you use Windows, you need to build from source to get Foundry.

Download and run `rustup-init` from [rustup.rs](https://rustup.rs/). It will start the installation in a console.

After this, run the following to build Foundry from source:

```
cargo install --git https://github.com/foundry-rs/foundry foundry-cli anvil --bins --locked
```

To update from source, run the same command again.

## Install dependencies

To install dependencies, run the following to install dependencies:

```
forge install
```

---

## Tests

To run tests, run the following command:

```
forge test
```
