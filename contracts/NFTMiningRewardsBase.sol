pragma solidity 0.6.12;

import "./common/Address.sol";
import "./common/Math.sol";
import "./common/SafeMath.sol";
import "./common/SafeERC20.sol";
import "./common/IERC20.sol";
import "./common/IERC721.sol";
import "./common/ReentrancyGuard.sol";

abstract contract NFTMiningRewardsBase is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    IERC20 public rewardsToken;
    IERC721 public stakingToken;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public rewardsDuration = 60 days;
    uint256 public lastUpdateTime;
    uint256 public rewardPerScoreStored;

    address public governance;
    address public rewardsDistribution;

    mapping(address => uint256) public userRewardPerScorePaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    /* ========== NFT MINING SPECIFIC VARIABLES ========== */

    uint256 private _totalScore;
    mapping(address => uint256) private _scores;

    // Mapping from tokenId to staker
    mapping(uint256 => address) private _stakedBy;
    // Mapping from staker to list of staked token IDs
    mapping(address => mapping(uint256 => uint256)) private _stakedTokens;
    // Mapping from token ID to index of the staker tokens list
    mapping(uint256 => uint256) private _stakedTokensIndex;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken
    ) public {
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC721(_stakingToken);
        rewardsDistribution = _rewardsDistribution;
        governance = msg.sender;
    }

    /* ========== NFT MINING SPECIFIC FUNCTIONS ========== */

    function tokenOfStakerByIndex(address _staker, uint256 _index) external view returns (uint256) {
        require(_index < _balances[_staker], "Index out of bounds");
        return _stakedTokens[_staker][_index];
    }

    function totalScore() external view returns (uint256) {
        return _totalScore;
    }

    function scoreOf(address account) external view returns (uint256) {
        return _scores[account];
    }

    // Token specific scoring function to return the score for a tokenId
    // To be implemented in implementation
    function _score(uint256 _tokenId) internal view virtual returns (uint256);

    function score(uint256 _tokenId) external view returns(uint256) {
        return _score(_tokenId);
    }

    function stake(uint256 _tokenId) external nonReentrant updateReward(msg.sender) {
        // Transfer token from owner and track ownership
        stakingToken.transferFrom(msg.sender, address(this), _tokenId);
        _addTokenToOwner(_tokenId, msg.sender);

        // Update token score
        uint256 tokenScore = _score(_tokenId);
        _totalScore = _totalScore.add(tokenScore);
        _scores[msg.sender] = _scores[msg.sender].add(tokenScore);

        emit Staked(msg.sender, _tokenId, tokenScore);
    }

    function withdraw(uint256 _tokenId) public nonReentrant updateReward(msg.sender) {
        require(msg.sender == _stakedBy[_tokenId], "tokenId not staked by msg.sender");

        // Update token score
        uint256 tokenScore = _score(_tokenId);
        _totalScore = _totalScore.sub(tokenScore);
        _scores[msg.sender] = _scores[msg.sender].sub(tokenScore);

        // Remove ownership and transfer token to msg.sender
        _removeTokenFromOwner(_tokenId, msg.sender);
        stakingToken.transferFrom(address(this), msg.sender, _tokenId);

        emit Withdrawn(msg.sender, _tokenId, tokenScore);
    }

    function _addTokenToOwner(uint256 _tokenId, address _owner) internal {
        uint256 length = _balances[_owner];
        _stakedTokens[_owner][length] = _tokenId;
        _stakedTokensIndex[_tokenId] = length;

        _totalSupply += 1;
        _balances[_owner] += 1;
        _stakedBy[_tokenId] = _owner;
    }

    function _removeTokenFromOwner(uint256 _tokenId, address _owner) internal {
        // To prevent a gap in owner's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _balances[_owner] - 1;
        uint256 tokenIndex = _stakedTokensIndex[_tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _stakedTokens[_owner][lastTokenIndex];

            _stakedTokens[_owner][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _stakedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _stakedTokensIndex[_tokenId];
        delete _stakedTokens[_owner][lastTokenIndex];

        _totalSupply -= 1;
        _balances[_owner] -= 1;
        _stakedBy[_tokenId] = address(0);
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) external view returns (uint256) {
        return _balances[owner];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerScore() public view returns (uint256) {
        if (_totalScore == 0) {
            return rewardPerScoreStored;
        }
        return
            rewardPerScoreStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalScore)
            );
    }

    function earned(address account) public view returns (uint256) {
        return _scores[account].mul(rewardPerScore().sub(userRewardPerScorePaid[account])).div(1e18).add(rewards[account]);
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function getReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(uint256 reward) external onlyRewardsDistribution updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerScore functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint balance = rewardsToken.balanceOf(address(this));
        require(rewardRate <= balance.div(rewardsDuration), "Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    function setGovernance(address _governance) external onlyGov() {
        governance = _governance;
    }

    function setRewardDistribution(address _rewardsDistribution) external onlyGov() {
        rewardsDistribution = _rewardsDistribution;
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerScoreStored = rewardPerScore();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerScorePaid[account] = rewardPerScoreStored;
        }
        _;
    }

    modifier onlyRewardsDistribution() {
        require(msg.sender == rewardsDistribution, "Caller is not RewardsDistribution contract");
        _;
    }

    modifier onlyGov() {
        require(msg.sender == governance, "!gov");
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 tokenId, uint256 idScore);
    event Withdrawn(address indexed user, uint256 tokenId, uint256 idScore);
    event RewardPaid(address indexed user, uint256 reward);
}
