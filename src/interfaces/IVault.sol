// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVault {
    // --- Errors ---
    
    /// @dev Thrown when the deposit amount is zero.
    error ZeroDeposit();

    /// @dev Thrown when the APR set by the owner is zero.
    error InvalidAPR();

    /// @dev Thrown when attempting to withdraw with no staked tokens.
    error NoStakedTokens();

    /// @dev Thrown when weekly rewards are attempted to be distributed before the cooldown ends.
    error WeeklyDistributionCooldown();

    /// @dev Thrown when a token transfer fails.
    error TokenTransferFailed();

    // --- Events ---
    
    /// @dev Emitted when a user deposits tokens.
    /// @param user The address of the user.
    /// @param amount The amount of tokens deposited.
    event Deposited(address indexed user, uint256 amount);

    /// @dev Emitted when a user withdraws tokens and rewards.
    /// @param user The address of the user.
    /// @param stakedAmount The amount of tokens withdrawn from the stake.
    /// @param rewardAmount The amount of rewards withdrawn.
    event Withdrawn(address indexed user, uint256 stakedAmount, uint256 rewardAmount);

    /// @dev Emitted when the owner updates the APR.
    /// @param newAPR The new APR value.
    event APRUpdated(uint256 newAPR);

    /// @dev Emitted when weekly rewards are distributed.
    /// @param totalReward The total reward distributed across all stakers.
    event RewardsDistributed(uint256 totalReward);

    // --- Functions ---
    
    /// @dev Allows a user to deposit tokens into the vault for staking.
    /// @param amount The number of tokens to deposit.
    function deposit(uint256 amount) external;

    /// @dev Allows a user to withdraw their staked tokens along with accumulated rewards.
    function withdraw() external;

    /// @dev Allows the owner to set a new APR.
    /// @param _newAPR The new APR value to set.
    function setAPR(uint256 _newAPR) external;

    /// @dev Distributes weekly rewards to all stakers.
    function distributeWeeklyRewards() external;

    /// @dev Returns the number of stakers in the vault.
    /// @return The total number of stakers.
    function getStakerCount() external view returns (uint256);

    /// @dev Calculates the pending rewards for a user.
    /// @param user The address of the user.
    /// @return pendingReward The calculated pending rewards for the user.
    function calculatePendingReward(address user) external view returns (uint256 pendingReward);
}
