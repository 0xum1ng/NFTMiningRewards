# NFT-Mining

Untested proof of concept for mining ERC20 token with NFTs.

For learning purposes only, do not use in production.

## Overview
This repo contains contracts for staking NFTs to mine reward tokens.

`NFTMiningRewardsBase` is modified on-top the famous `StakingRewards` contract, with changes for staking/withdrawing ERC721 token, and added interface for calculating a custom `score` for each ERC721 `tokenId`. 

`NFTMiningRewardsBase` itself is abstract, but can be extended with any custom `score` logic for different ERC721 tokens.

## Examples
`SimpleNFTMiningRewards` is the simplest example with a `score` function that just returns the same score for all `tokenId`

`LootMiningRewards` is an example of how the scoring interface can become complex, it uses the loot contract to generate a `score` based on the bag's attributes.
