// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ILiquidityPool.sol";

contract LPStakingWeekly {
    IERC20 public token; // The token being deposited
    uint256 public apr; // Variable APR instead of constant
    uint256 public constant SECONDS_IN_A_YEAR = 31536000; // Seconds in a year
    uint256 public constant PERCENT_DIVISOR = 100; // To handle percentages
    uint256 public constant SECONDS_IN_A_WEEK = 604800; // Seconds in a week

    struct Stake {
        uint256 amount; // Amount of tokens staked
        uint256 reward; // Accumulated rewards
        uint256 lastUpdated; // Timestamp of the last interaction
    }

    mapping(address => Stake) public stakes; // Track stakes per user

    uint256 public lastRewardDistribution; // Last time rewards were distributed

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount, uint256 reward);
    event RewardsDistributed(uint256 totalReward);

    constructor(IERC20 _token, uint256 _apr) {
        token = _token;
        apr = _apr;
        lastRewardDistribution = block.timestamp;
    }

    /**
     * @dev Deposit tokens to start earning rewards.
     * @param amount The number of tokens to deposit.
     */
    function deposit(uint256 amount) external {
        require(amount > 0, "Deposit amount must be greater than zero");

        // Update rewards for the user before modifying their stake
        _updateReward(msg.sender);

        // Transfer tokens from the user to the contract
        require(token.transferFrom(msg.sender, address(this), amount), "Token transfer failed");

        // Update the user's stake
        stakes[msg.sender].amount += amount;

        emit Deposited(msg.sender, amount);
    }

    /**
     * @dev Withdraw staked tokens along with accumulated rewards.
     */
    function withdraw() external {
        Stake storage stakeInfo = stakes[msg.sender];
        require(stakeInfo.amount > 0, "No staked tokens to withdraw");

        // Update rewards for the user before withdrawal
        _updateReward(msg.sender);

        uint256 totalAmount = stakeInfo.amount + stakeInfo.reward;

        // Reset the user's stake
        stakeInfo.amount = 0;
        stakeInfo.reward = 0;

        // Transfer tokens back to the user
        require(token.transfer(msg.sender, totalAmount), "Token transfer failed");

        emit Withdrawn(msg.sender, stakeInfo.amount, stakeInfo.reward);
    }

    /**
     * @dev Distribute weekly rewards to all stakers.
     */
    function distributeWeeklyRewards() external {
        require(block.timestamp >= lastRewardDistribution + SECONDS_IN_A_WEEK, "Rewards already distributed this week");

        uint256 totalReward = 0;

        // Iterate through all stakers and update their rewards
        address[] memory stakers = _getAllStakers();
        for (uint i = 0; i < stakers.length; i++) {
            address user = stakers[i];
            _updateReward(user);
            totalReward += stakes[user].reward;
        }

        lastRewardDistribution = block.timestamp;

        emit RewardsDistributed(totalReward);
    }

    /**
     * @dev Internal function to update a user's reward.
     * @param user The address of the user.
     */
    function _updateReward(address user) internal {
        Stake storage stakeInfo = stakes[user];

        if (stakeInfo.amount > 0) {
            uint256 timeElapsed = block.timestamp - stakeInfo.lastUpdated;
            uint256 newReward = calculateReward(stakeInfo.amount, apr, timeElapsed);
            stakeInfo.reward += newReward;
        }

        stakeInfo.lastUpdated = block.timestamp;
    }

    /**
     * @dev View function to calculate a user's pending rewards.
     * @param user The address of the user.
     * @return pendingReward The amount of rewards pending for the user.
     */
    function calculatePendingReward(address user) external view returns (uint256 pendingReward) {
        Stake memory stakeInfo = stakes[user];

        if (stakeInfo.amount > 0) {
            uint256 timeElapsed = block.timestamp - stakeInfo.lastUpdated;
            pendingReward = calculateReward(stakeInfo.amount, apr, timeElapsed);
            pendingReward += stakeInfo.reward;
        }
    }

    /**
     * @dev Pure function to calculate rewards based on amount, APR, and time
     * @param amount The staked amount
     * @param _apr The annual percentage rate
     * @param timeElapsed The time period for calculation
     * @return reward The calculated reward amount
     */
    function calculateReward(
        uint256 amount,
        uint256 _apr,
        uint256 timeElapsed
    ) public pure returns (uint256 reward) {
        return (amount * _apr * timeElapsed) / (SECONDS_IN_A_YEAR * PERCENT_DIVISOR);
    }

    /**
     * @dev Returns the list of all stakers (requires tracking all staker addresses).
     * This function is a placeholder and should be implemented with a more efficient approach.
     */
    function _getAllStakers() internal pure returns (address[] memory) {
        return new address[](0);
    }
}
