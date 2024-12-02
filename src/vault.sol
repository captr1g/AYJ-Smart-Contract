// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "./interfaces/IVault.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // OpenZeppelin's Ownable for access control

contract Vault is Ownable {
    IERC20 public token; // The token being deposited
    uint256 public apr; // Dynamic APR set by the owner
    uint256 public constant SECONDS_IN_A_YEAR = 31536000; // Seconds in a year
    uint256 public constant SECONDS_IN_A_WEEK = 604800; // Seconds in a week
    uint256 public constant PERCENT_DIVISOR = 100; // To handle percentages

    struct Stake {
        uint256 amount; // Amount of tokens staked
        uint256 reward; // Accumulated rewards
        uint256 lastUpdated; // Timestamp of the last interaction
    }

    mapping(address => Stake) public stakes; // Track stakes per user
    address[] public stakers; // List of staker addresses
    uint256 public lastRewardDistribution; // Last time rewards were distributed

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount, uint256 reward);
    event RewardsDistributed(uint256 totalReward);
    event APRUpdated(uint256 newAPR);

    constructor(IERC20 _token, uint256 _initialAPR) Ownable(msg.sender) {
        token = _token;
        apr = _initialAPR;
        lastRewardDistribution = block.timestamp;
    }

    /**
     * @dev Set a new APR. Only the owner can call this function.
     * @param _newAPR The new APR value.
     */
    function setAPR(uint256 _newAPR) external onlyOwner {
        require(_newAPR > 0, "APR must be greater than zero");
        apr = _newAPR;
        emit APRUpdated(_newAPR);
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

        // If the user is a new staker, add to the stakers array
        if (stakes[msg.sender].amount == 0) {
            stakers.push(msg.sender);
        }

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

        // Remove user from stakers if fully withdrawn
        _removeStaker(msg.sender);

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
        for (uint256 i = 0; i < stakers.length; i++) {
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
            uint256 newReward = (stakeInfo.amount * apr * timeElapsed) / (SECONDS_IN_A_YEAR * PERCENT_DIVISOR);
            stakeInfo.reward += newReward;
        }

        // Update the last interaction time
        stakeInfo.lastUpdated = block.timestamp;
    }

    /**
     * @dev Removes a user from the stakers array when they withdraw fully.
     * @param user The address of the user.
     */
    function _removeStaker(address user) internal {
        for (uint256 i = 0; i < stakers.length; i++) {
            if (stakers[i] == user) {
                stakers[i] = stakers[stakers.length - 1]; // Replace with the last element
                stakers.pop(); // Remove the last element
                break;
            }
        }
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
            pendingReward = (stakeInfo.amount * apr * timeElapsed) / (SECONDS_IN_A_YEAR * PERCENT_DIVISOR);
            pendingReward += stakeInfo.reward;
        }
    }

    /**
     * @dev Returns the total number of stakers.
     */
    function getStakerCount() external view returns (uint256) {
        return stakers.length;
    }
}
