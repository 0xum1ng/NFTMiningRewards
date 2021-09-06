pragma solidity 0.6.12;

import "../NFTMiningRewardsBase.sol";

interface Loot {
    function getWeapon(uint256 tokenId) external view returns (string memory);
    function getChest(uint256 tokenId) external view returns (string memory);
    function getHead(uint256 tokenId) external view returns (string memory);
    function getWaist(uint256 tokenId) external view returns (string memory);
    function getFoot(uint256 tokenId) external view returns (string memory);
    function getHand(uint256 tokenId) external view returns (string memory);
    function getNeck(uint256 tokenId) external view returns (string memory);
    function getRing(uint256 tokenId) external view returns (string memory);
}

contract LootMiningRewards is NFTMiningRewardsBase {
    using SafeMath for uint256;

    /* ========== CONSTRUCTOR ========== */

    constructor(
      address _rewardsDistribution,
      address _rewardsToken,
      address _stakingToken)
      public
      NFTMiningRewardsBase(_rewardsDistribution, _rewardsToken, _stakingToken)
    {

    }

    // Example loot scoring with simple string to uint converter
    function _score(uint256 _tokenId) internal view virtual override returns (uint256) {
        uint256 totalScore;
        totalScore = totalScore.add(toUint256(toBytes(Loot(address(stakingToken)).getWeapon(_tokenId))));
        totalScore = totalScore.add(toUint256(toBytes(Loot(address(stakingToken)).getChest(_tokenId))));
        totalScore = totalScore.add(toUint256(toBytes(Loot(address(stakingToken)).getHead(_tokenId))));
        totalScore = totalScore.add(toUint256(toBytes(Loot(address(stakingToken)).getWaist(_tokenId))));
        totalScore = totalScore.add(toUint256(toBytes(Loot(address(stakingToken)).getFoot(_tokenId))));
        totalScore = totalScore.add(toUint256(toBytes(Loot(address(stakingToken)).getHand(_tokenId))));
        totalScore = totalScore.add(toUint256(toBytes(Loot(address(stakingToken)).getNeck(_tokenId))));
        totalScore = totalScore.add(toUint256(toBytes(Loot(address(stakingToken)).getRing(_tokenId))));
        return totalScore;
    }

    function toUint256(bytes memory _bytes) internal pure returns (uint256 value) {
        assembly {
          value := mload(add(_bytes, 0x20))
        }
    }

    function toBytes(string memory _s) internal pure returns (bytes memory){
        bytes memory b3 = bytes(_s);
        return b3;
    }
}
