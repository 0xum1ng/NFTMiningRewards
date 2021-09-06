# NFT-Mining

Untested proof of concept for mining ERC20 token with NFTs.

For learning purposes only, do not use in production.

## Overview
This repo contains contracts for staking NFTs to mine reward tokens.

`NFTMiningRewardsBase` is modified on-top the famous `StakingRewards` contract, with changes for staking/withdrawing ERC721 token, and added interface for calculating a custom `score` for each ERC721 `tokenId`. `NFTMiningRewardsBase` itself is abstract, but can be extended with any custom `score` logic for different ERC721 tokens.
