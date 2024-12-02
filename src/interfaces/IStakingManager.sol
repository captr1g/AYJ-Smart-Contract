// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title INsETHStakingManagerL1 Interface
 * @notice Interface for the nsETH Staking Manager contract with detailed error messages and events.
 * @author Neemo.
 */
interface IStakingManager {
    /// @notice Status of withdraw orders.
    enum OrderStatus {
        Inactive,
        Active,
        Redeemed
    }

    /// @notice Status of batch.
    enum BatchStatus {
        Active,
        Unlocking,
        Finalized
    }

    /// @notice Thrown when authentication fails.
    error AuthenticationFailed();

    /// @notice Thrown when an action is paused.
    error ActionPaused();

    /// @notice Thrown when an input parameter is invalid.
    error InvalidInput();

    /// @notice Thrown when claim request fails.
    error TokenClaimFailed(string _reason);

    /// @notice Thrown when the implementation is invalid.
    error InvalidImplementation();

    /// @notice Thrown when a token redemption fails due to zero amount.
    error InvalidRescueAmount();

    /// @notice Thrown when an invalid withdraw request is made.
    error RequestWithdrawFailed(string reason);

    /// @notice Thrown when a transfer fails.
    /// @param to The address to which the transfer failed.
    /// @param amount The amount that failed to be transferred.
    error TransferFailed(address to, uint256 amount);

    /// @notice Thrown when a mint is failed.
    error MintingFailed(string reason);

    /// @notice Thrown when a manager call fails.
    error ManagerCallFailed(string reason);

    /// @notice Thrown when a deposit fails.
    error DepositTokenFailed(string reason);

    /// @notice Thrown when a reprice fails.
    error RepriceFailed(string reason);

    /// @notice Emitted when tokens are rescued.
    /// @param _token The address of the token rescued.
    /// @param amount The amount of tokens rescued.
    event LogRescueTokens(address indexed _token, uint256 amount);

    /// @notice Emitted when the treasury address is set.
    /// @param _oldTreasury The previous treasury address.
    /// @param _newTreasury The new treasury address.
    event LogSetTreasury(address _oldTreasury, address _newTreasury);

    /// @notice Emitted when the reward split is set.
    /// @param _oldSplit The previous reward split eras.
    /// @param _newSplit The new reward split eras.
    event LogSetBonusRewardSplit(uint256 _oldSplit, uint256 _newSplit);

    /// @notice Emitted when a deposit is made.
    /// @param _recipient The address of the recipient.
    /// @param _amount The amount deposited.
    /// @param _lstAllocated The amount of LST allocated.
    event LogDeposit(address indexed _recipient, uint256 _amount, uint256 _lstAllocated);

    /// @notice Emitted when a user is referred by another address.
    /// @param _user The address of the user.
    /// @param _referredBy The address of the referrer.
    /// @param _amount The amount of tokens deposited by the user.
    event LogReferredBy(address indexed _user, address indexed _referredBy, uint256 _amount);

    /// @notice Emitted when tokens are claimed.
    /// @param _sentTo The address receiving the tokens.
    /// @param _batchId The ID of the batch.
    /// @param _lstUnstaked The amount of LST unstaked.
    /// @param _ASTRReceived The amount of ASTR received.
    event LogTokenClaimed(address _sentTo, uint256 _batchId, uint256 _lstUnstaked, uint256 _ASTRReceived);

    /// @notice Emitted when the exchange deviation is set.
    /// @param _increaseLimit The increase limit.
    event LogSetExchangeDeviation(uint256 _increaseLimit);

    /// @notice Emitted when a reward boost is made.
    /// @param _donator The address of the donator.
    /// @param donationAmount The amount of the donation.
    event LogRewardBoost(address indexed _donator, uint256 donationAmount);

    /// @notice Emitted when staking is activated or deactivated.
    /// @param isStakingActive The status of staking.
    event LogSetStakingActive(bool isStakingActive);

    /// @notice Emitted when the reward fee is set.
    /// @param _oldFee The old fee.
    /// @param _newFee The new fee.
    event LogSetRewardFee(uint256 _oldFee, uint256 _newFee);

    /// @notice Emitted when the mint fee is set.
    /// @param _oldFee The old fee.
    /// @param _newFee The new fee.
    event LogSetMintFee(uint256 _oldFee, uint256 _newFee);

    /// @notice Emitted when a withdraw request is made.
    /// @param _user The user address.
    /// @param _requestAmount The amount requested to withdraw.
    /// @param _totalUnstaked The total amount unstaked in currentBatch.
    /// @param _batchId The batch ID of the withdraw request.
    event LogRequestWithdraw(
        address indexed _user,
        uint256 _requestAmount,
        uint256 _totalUnstaked,
        uint256 indexed _batchId
    );

    /// @notice Emitted when a withdrawal request is rebalanced.
    /// @param _user The user address.
    /// @param _requestAmount The amount requested to rebalance from withdraw.
    /// @param _totalUnstaked The total pending unstaked in currentBatch.
    /// @param _batchId The batch ID of the rebalnce request.
    event LogRebalanceRequestWithdraw(
        address indexed _user,
        uint256 _requestAmount,
        uint256 _totalUnstaked,
        uint256 indexed _batchId
    );

    /// @notice Emitted when a reprice.
    /// @param totalWeETHDeposit in AssetStateMeta.
    /// @param totalWeETHStrategy in AssetStateMeta.
    /// @param totalWeETHRewardCut in AssetStateMeta.
    event LogReprice(uint256 totalWeETHDeposit, uint256 totalWeETHStrategy, uint256 totalWeETHRewardCut);

    /// @notice Emitted when multichain manager is set
    /// @param _multichainManager The address of the multichain manager.
    event LogSetMultichainManager(address _multichainManager);

    /// @notice Emitted when multichain mint is activated or deactivated.
    /// @param _isMultichainMintActive The status of multichain mint.
    event LogSetMultichainMintActive(bool _isMultichainMintActive);

    /// @notice Emitted when a mint is made.
    /// @param _to The address of the recipient.
    /// @param _amount The amount minted.
    /// @param _fee The mint fee.
    event LogMintNsAstr(address _to, uint256 _amount, uint256 _fee);

    /// @dev Struct holding staking state metadata.
    struct AssetStateMeta {
        uint256 totalWeETHDeposit;
        uint256 totalWeETHStrategy;
        uint256 totalETHRedeemable;
        uint256 totalLstSupply;
        uint256 totalWeETHRewardCut;
    }

    /// @notice Struct holding unstake request metadata.
    struct WithdrawRequestMeta {
        OrderStatus status;
        uint256 requestAmount;
        uint256 batchId;
        uint256 unstaked;
        uint256 received;
    }

    /// @notice Struct holding batch metadata.
    struct BatchMeta {
        uint256 lstWithdrawQueue;
        uint256 batchId;
        uint256 finalExchangeRate;
        uint256 expectedETH;
        uint256 claimableBlock;
        BatchStatus status;
    }

    /// @notice Updates the neemo treasury.
    function setTreasury(address payable _newTreasury) external;

    function setMultichainMintActive(bool _active) external;

    /// @notice Sets the reward fee fee percentage.
    function setRewardFee(uint256 _rewardFee) external;

    /// @notice Sets the nsAstr mint fee percentage.
    function setMintFee(uint256 _mintFee) external;

    /// @notice Updates Exchange rate allowed percentage deviation.
    function setRateDeviationLimit(uint256 _increaseLimit) external;

    /// @notice Sets the multichain manager address.
    function setMultichainManager(address _manager) external;

    /// @notice Deposits WeETH tokens to mint LST tokens.
    function depositWeEth(
        uint256 _tokenAmount,
        address _delegateTo,
        address _referredBy,
        bool _lazyMint
    ) external returns (uint256);

    /// @notice Mints NsETH tokens for the user.
    function mintNsETH(bool _lazyMint) external returns (uint256);

    /// @notice Requests withdrawal of LST at the end of current period.
    function requestWithdraw(uint256 _lstAmount) external returns (uint256);

    /// @notice Claims withdrawn tokens.
    function claim(uint256 _batchId) external returns (bool);

    /// @notice reprice rates.
    function reprice() external returns (bool);

    /// @notice Execute strategy.
    function executeStrategy(uint256 _amount) external;

    /// @notice Returns all the batches meta.
    function getBatches(uint256 _index) external view returns (BatchMeta[] memory, uint256);

    /// @notice Returns all the user requests.
    function getUserWithdrawRequests(
        uint256 _index,
        address _user
    ) external view returns (WithdrawRequestMeta[] memory, uint256);

    /// @notice Returns the current LST exchange rate.
    function getRate() external view returns (uint256);

    /// @notice Returns the Astar to LST exhange rate.
    function underlyingToLstRate() external view returns (uint256);

    /// @notice Returns the current asset state.
    function getAssetState() external view returns (AssetStateMeta memory);

    /// @notice Rescue ERC20 tokens from the contract to the treasury address.
    function rescueTokens(address _token) external returns (uint256);

    function depositWithERC20(
        address token,
        uint256 amount,
        address recipient
    ) external returns (uint256);
}