# Camino Bot PayMaster Concept

This is a concept study about implementing a "paymaster" feature for cheque
mechanism of Camino Messenger's bot concept.

## Rationale

Camino Messenger has a concept of "bots" that are used to communicate between
different entitites like providers and distributors. Our initial design was to
use something we call "bot-id" so a company can run multiple bots with the same
wallet (private key).

Companies can also run multiple bots with different wallets. Which in my opinion 
is a better option. But this was not favored because it will bring a burden of managing
funds for multiple bot accounts (wallets).

## Goals 

- To be able to fund multiple bots with the same wallet
- Register bots to the paymaster so bots can use the funds of the paymaster, or
  another payment wallet[^1], without the need for each individual bot wallet to
  have funds.

## Considerations

- Bots will generate cheques for each message they send via the Camino Messenger
- Each message will contain at least one cheque (network fee)
- A message can have multiple cheques. Ex: provider fee that will be paid to the
  service provider
- All of these cheques are **off-chain** and are signed by the bot with its private key
- It should be possible to verify the signature of the cheque **on-chain** and
  release the funds from the paymaster to the receiver of the cheque.

## Notes

- The design is coded in Solidity but the concept is language agnostic.
  Cryptographically, it can be implemented in any language.
- **Security:** The design is not audited for security in any way. For cryptographic security
  we may consider using some standards like EIP-712[^2][^3].
- **PayMaster Address in Cheques:** It may be a good idea to include PayMaster's
  contract address in the cheque, so the cheque is only valid for a specific
  PayMaster.

## Design

### BotPayMaster

#### Partner

- Partners will deploy a BotPayMaster smart contract. 
- And then approve bot addresses using this paymaster contract's `approveBot` function.

#### Bot

- Any approved bot can create cheques, sign them and send them to the receiver.
- Bots create a cheque by creating a hash with `from`, `to`, `amount`, and `nonce`

  ```solidity
  keccak256(abi.encodePacked(from, to, amount, nonce));
  ```

  - **from:** the bot's address
  - **to:** the address of the receiver
  - **amount:** the amount of tokens/coins to send to the reciever
  - **nonce:** incremental nonce to prevent replay of the already cached out cheques

- Then this cheque and signature is send to the receiver.

#### Receiver

- The receiver (or any one that have access to the cheque) can cash out the cheque. 
- Because the cheques can only be cashed out to the original receiver address,
  it is safe to let any address to initiate the `cashCheque` function. This
  enables one to implement another wallet to be used only to pay gas.
- In the `cashCheque` function, the PayMaster recreates the cheque hash with the given fields of 'from`, `to`, `amount` and `nonce. Then it tries to recover the pubkey using the signature. If successfull, it checks if the `from` address
- Receiver can use `isChequeValid` function to validate if the cheque is valid, without cashing it out.

## Diagram

![BotPayMaster Diagram](./assets/BotPayMaster-Concept-Design-1.png)

[^1]: The smart contract can be improved to be able to spend other wallet's
ERC20-like funds usind the `approve` method of the ERC20 standard.
[^2]: https://eips.ethereum.org/EIPS/eip-712
[^3]: More info on security: https://soliditydeveloper.com/ecrecover