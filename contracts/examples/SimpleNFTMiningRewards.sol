pragma solidity 0.6.12;

import "../NFTMiningRewardsBase.sol";

contract SimpleNFTMiningRewards is NFTMiningRewardsBase {

    /* ========== CONSTRUCTOR ========== */

    constructor(address _rewardsToken, address _stakingToken)
        public
        NFTMiningRewardsBase(msg.sender, _rewardsToken, _stakingToken)
    {

    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _score(uint256 _tokenId) internal view virtual override returns (uint256) {
        _tokenId; // avoid compiler warning

        // return same score for all tokenIds
        return 1000000000000000000;
    }
}
