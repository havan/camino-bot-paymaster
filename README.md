# Camino Bot Manager

## Rationale

Camino Messenger has a concept of "bots" that are used to communicate between
different entitites like providers and distributors. Our initial design was to
use something we call "bot-id" so a company can run multiple bots with the same
wallet (private key).

Companies can also run multiple bots with different wallets. But this was not
favored because it will bring a burden of managing funds for multiple bot
accounts.

## Goals 

- To be able to fund multiple bots with the same wallet
- Register nodes to the manager so nodes can use the funds of the manager, or
  another payment wallet, without the need for each individual bot wallet to
  have funds.

## Considerations

- Bots will generate checks for each message they send via the Camino Messenger
- Each message will contain at least one check (network fee)
- A message can have multiple checks. Ex: service fee that will be paid to the
  service provider
- All of these checks are **off-chain** and are signed by the bot with its private key
- It should be possible to verify the signature of the check **on-chain** and
  release the funds to the receiver of the check.

## Notes

- The design below is coded in Solidity but the concept is language agnostic.
  The implementation can be considered pseudo-code.

## Design

### Bot Manager

Partners will create BotManager Smart Contract. And then register bot addresses
using this manager contract.




