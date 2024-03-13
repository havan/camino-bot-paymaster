# Camino Bot Paymaster Concept

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
- A message can have multiple cheques. Ex: service fee that will be paid to the
  service provider
- All of these cheques are **off-chain** and are signed by the bot with its private key
- It should be possible to verify the signature of the cheque **on-chain** and
  release the funds from the paymaster to the receiver of the cheque.

## Notes

- The design is coded in Solidity but the concept is language agnostic.
  Cryptographically, it can be implemented in any language.

## Design

### BotPaymaster

#### Partner

- Partners will deploy a BotPaymaster smart contract. 
- And then register bot addresses using this paymaster contract.

#### Bot

- Any registered bot wallet can create cheques and send them to the receiver.
- Bots create a cheque by creating a hash with `from`, `to`, `amount`, and `nonce`

  ```solidity
  keccak256(abi.encodePacked(from, to, amount, nonce));
  ```

  **from:** the bot's address
  **to:** the address of the receiver
  **amount:** the amount of tokens/coins to send to the reciever
  **nonce:** incremental nonce to prevent replay of the already cached out cheques

#### Receiver

- The receiver (or any one that have access to the cheque) can cash out the cheque. Because
  the cheques can only be cashed out to the original receiver address, it is safe to let any
  address to initiate the `cashCheque` function.
- In the `cashCheque` function, the Paymaster recreates the cheque hash with the given

[^1]: The smart contract can be improved to be able to spend other wallet's ETC20-like funds 
      usind the `approve` method of the ERC20 standard.