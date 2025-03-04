// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/// @title Lido's Staking Module interface
abstract contract IStakingModule {
    /// @notice Returns the type of the staking module
    function getType() external view virtual returns (bytes32);

    /// @notice Returns all-validators summary in the staking module
    /// @return totalExitedValidators total number of validators in the EXITED state
    ///     on the Consensus Layer. This value can't decrease in normal conditions
    /// @return totalDepositedValidators total number of validators deposited via the
    ///     official Deposit Contract. This value is a cumulative counter: even when the validator
    ///     goes into EXITED state this counter is not decreasing
    /// @return depositableValidatorsCount number of validators in the set available for deposit
    function getStakingModuleSummary() external view virtual returns (
        uint256 totalExitedValidators,
        uint256 totalDepositedValidators,
        uint256 depositableValidatorsCount
    );

    /// @notice Returns all-validators summary belonging to the node operator with the given id
    /// @param _nodeOperatorId id of the operator to return report for
    /// @return targetLimitMode shows whether the current target limit applied to the node operator (0 = disabled, 1 = soft mode, 2 = forced mode)
    /// @return targetValidatorsCount relative target active validators limit for operator
    /// @return stuckValidatorsCount number of validators with an expired request to exit time
    /// @return refundedValidatorsCount number of validators that can't be withdrawn, but deposit
    ///     costs were compensated to the Lido by the node operator
    /// @return stuckPenaltyEndTimestamp time when the penalty for stuck validators stops applying
    ///     to node operator rewards
    /// @return totalExitedValidators total number of validators in the EXITED state
    ///     on the Consensus Layer. This value can't decrease in normal conditions
    /// @return totalDepositedValidators total number of validators deposited via the official
    ///     Deposit Contract. This value is a cumulative counter: even when the validator goes into
    ///     EXITED state this counter is not decreasing
    /// @return depositableValidatorsCount number of validators in the set available for deposit
    function getNodeOperatorSummary(uint256 _nodeOperatorId) external view virtual returns (
        uint256 targetLimitMode,
        uint256 targetValidatorsCount,
        uint256 stuckValidatorsCount,
        uint256 refundedValidatorsCount,
        uint256 stuckPenaltyEndTimestamp,
        uint256 totalExitedValidators,
        uint256 totalDepositedValidators,
        uint256 depositableValidatorsCount
    );

    /// @notice Returns a counter that MUST change its value whenever the deposit data set changes.
    ///     Below is the typical list of actions that requires an update of the nonce:
    ///     1. a node operator's deposit data is added
    ///     2. a node operator's deposit data is removed
    ///     3. a node operator's ready-to-deposit data size is changed
    ///     4. a node operator was activated/deactivated
    ///     5. a node operator's deposit data is used for the deposit
    ///     Note: Depending on the StakingModule implementation above list might be extended
    /// @dev In some scenarios, it's allowed to update nonce without actual change of the deposit
    ///      data subset, but it MUST NOT lead to the DOS of the staking module via continuous
    ///      update of the nonce by the malicious actor
    function getNonce() external view virtual returns (uint256);

    /// @notice Returns total number of node operators
    function getNodeOperatorsCount() external view virtual returns (uint256);

    /// @notice Returns number of active node operators
    function getActiveNodeOperatorsCount() external view virtual returns (uint256);

    /// @notice Returns if the node operator with given id is active
    /// @param _nodeOperatorId Id of the node operator
    function getNodeOperatorIsActive(uint256 _nodeOperatorId) external view virtual returns (bool);

    /// @notice Returns up to `_limit` node operator ids starting from the `_offset`. The order of
    ///     the returned ids is not defined and might change between calls.
    /// @dev This view must not revert in case of invalid data passed. When `_offset` exceeds the
    ///     total node operators count or when `_limit` is equal to 0 MUST be returned empty array.
    function getNodeOperatorIds(uint256 _offset, uint256 _limit)
        external
        view
        virtual
        returns (uint256[] memory nodeOperatorIds);


    /// @notice Called by StakingRouter to signal that stETH rewards were minted for this module.
    /// @param _totalShares Amount of stETH shares that were minted to reward all node operators.
    /// @dev IMPORTANT: this method SHOULD revert with empty error data ONLY because of "out of gas".
    ///      Details about error data: https://docs.soliditylang.org/en/v0.8.9/control-structures.html#error-handling-assert-require-revert-and-exceptions
    function onRewardsMinted(uint256 _totalShares) external virtual;

    /// @notice Called by StakingRouter to decrease the number of vetted keys for node operator with given id
    /// @param _nodeOperatorIds bytes packed array of the node operators id
    /// @param _vettedSigningKeysCounts bytes packed array of the new number of vetted keys for the node operators
    function decreaseVettedSigningKeysCount(
        bytes calldata _nodeOperatorIds,
        bytes calldata _vettedSigningKeysCounts
    ) external virtual;

    /// @notice Updates the number of the validators of the given node operator that were requested
    ///         to exit but failed to do so in the max allowed time
    /// @param _nodeOperatorIds bytes packed array of the node operators id
    /// @param _stuckValidatorsCounts bytes packed array of the new number of STUCK validators for the node operators
    function updateStuckValidatorsCount(
        bytes calldata _nodeOperatorIds,
        bytes calldata _stuckValidatorsCounts
    ) external virtual;

    /// @notice Updates the number of the validators in the EXITED state for node operator with given id
    /// @param _nodeOperatorIds bytes packed array of the node operators id
    /// @param _exitedValidatorsCounts bytes packed array of the new number of EXITED validators for the node operators
    function updateExitedValidatorsCount(
        bytes calldata _nodeOperatorIds,
        bytes calldata _exitedValidatorsCounts
    ) external virtual;

    /// @notice Updates the number of the refunded validators for node operator with the given id
    /// @param _nodeOperatorId Id of the node operator
    /// @param _refundedValidatorsCount New number of refunded validators of the node operator
    function updateRefundedValidatorsCount(uint256 _nodeOperatorId, uint256 _refundedValidatorsCount) external virtual;

    /// @notice Updates the limit of the validators that can be used for deposit
    /// @param _nodeOperatorId Id of the node operator
    /// @param _targetLimitMode target limit mode
    /// @param _targetLimit Target limit of the node operator
    function updateTargetValidatorsLimits(
        uint256 _nodeOperatorId,
        uint256 _targetLimitMode,
        uint256 _targetLimit
    ) external virtual;

    /// @notice Unsafely updates the number of validators in the EXITED/STUCK states for node operator with given id
    ///      'unsafely' means that this method can both increase and decrease exited and stuck counters
    /// @param _nodeOperatorId Id of the node operator
    /// @param _exitedValidatorsCount New number of EXITED validators for the node operator
    /// @param _stuckValidatorsCount New number of STUCK validator for the node operator
    function unsafeUpdateValidatorsCount(
        uint256 _nodeOperatorId,
        uint256 _exitedValidatorsCount,
        uint256 _stuckValidatorsCount
    ) external virtual;

    /// @notice Obtains deposit data to be used by StakingRouter to deposit to the Ethereum Deposit
    ///     contract
    /// @dev The method MUST revert when the staking module has not enough deposit data items
    /// @param _depositsCount Number of deposits to be done
    /// @param _depositCalldata Staking module defined data encoded as bytes.
    ///        IMPORTANT: _depositCalldata MUST NOT modify the deposit data set of the staking module
    /// @return publicKeys Batch of the concatenated public validators keys
    /// @return signatures Batch of the concatenated deposit signatures for returned public keys
    function obtainDepositData(uint256 _depositsCount, bytes calldata _depositCalldata)
        external
        virtual
        returns (bytes memory publicKeys, bytes memory signatures);

    /// @notice Called by StakingRouter after it finishes updating exited and stuck validators
    /// counts for this module's node operators.
    ///
    /// Guaranteed to be called after an oracle report is applied, regardless of whether any node
    /// operator in this module has actually received any updated counts as a result of the report
    /// but given that the total number of exited validators returned from getStakingModuleSummary
    /// is the same as StakingRouter expects based on the total count received from the oracle.
    ///
    /// @dev IMPORTANT: this method SHOULD revert with empty error data ONLY because of "out of gas".
    ///      Details about error data: https://docs.soliditylang.org/en/v0.8.9/control-structures.html#error-handling-assert-require-revert-and-exceptions
    function onExitedAndStuckValidatorsCountsUpdated() external virtual;

    /// @notice Called by StakingRouter when withdrawal credentials are changed.
    /// @dev This method MUST discard all StakingModule's unused deposit data cause they become
    ///      invalid after the withdrawal credentials are changed
    ///
    /// @dev IMPORTANT: this method SHOULD revert with empty error data ONLY because of "out of gas".
    ///      Details about error data: https://docs.soliditylang.org/en/v0.8.9/control-structures.html#error-handling-assert-require-revert-and-exceptions
    function onWithdrawalCredentialsChanged() external virtual;

    /// @dev Event to be emitted on StakingModule's nonce change
    event NonceChanged(uint256 nonce);

    /// @dev Event to be emitted when a signing key is added to the StakingModule
    event SigningKeyAdded(uint256 indexed nodeOperatorId, bytes pubkey);

    /// @dev Event to be emitted when a signing key is removed from the StakingModule
    event SigningKeyRemoved(uint256 indexed nodeOperatorId, bytes pubkey);

    event StakingModuleAdded(uint256 indexed stakingModuleId, address stakingModule, string name, address createdBy);
    event StakingModuleShareLimitSet(uint256 indexed stakingModuleId, uint256 stakeShareLimit, uint256 priorityExitShareThreshold, address setBy);
    event StakingModuleFeesSet(uint256 indexed stakingModuleId, uint256 stakingModuleFee, uint256 treasuryFee, address setBy);
    event StakingModuleStatusSet(uint256 indexed stakingModuleId, StakingModuleStatus status, address setBy);
    event StakingModuleExitedValidatorsIncompleteReporting(uint256 indexed stakingModuleId, uint256 unreportedExitedValidatorsCount);
    event StakingModuleMaxDepositsPerBlockSet(
        uint256 indexed stakingModuleId, uint256 maxDepositsPerBlock, address setBy
    );
    event StakingModuleMinDepositBlockDistanceSet(
        uint256 indexed stakingModuleId, uint256 minDepositBlockDistance, address setBy
    );
    event WithdrawalCredentialsSet(bytes32 withdrawalCredentials, address setBy);
    event WithdrawalsCredentialsChangeFailed(uint256 indexed stakingModuleId, bytes lowLevelRevertData);
    event ExitedAndStuckValidatorsCountsUpdateFailed(uint256 indexed stakingModuleId, bytes lowLevelRevertData);
    event RewardsMintedReportFailed(uint256 indexed stakingModuleId, bytes lowLevelRevertData);

    /// Emitted when the StakingRouter received ETH
    event StakingRouterETHDeposited(uint256 indexed stakingModuleId, uint256 amount);

    /// @dev Errors
    error ZeroAddressLido();
    error ZeroAddressAdmin();
    error ZeroAddressStakingModule();
    error InvalidStakeShareLimit();
    error InvalidFeeSum();
    error StakingModuleNotActive();
    error EmptyWithdrawalsCredentials();
    error DirectETHTransfer();
    error InvalidReportData(uint256 code);
    error ExitedValidatorsCountCannotDecrease();
    error ReportedExitedValidatorsExceedDeposited(
        uint256 reportedExitedValidatorsCount,
        uint256 depositedValidatorsCount
    );
    error StakingModulesLimitExceeded();
    error StakingModuleUnregistered();
    error AppAuthLidoFailed();
    error StakingModuleStatusTheSame();
    error StakingModuleWrongName();
    error UnexpectedCurrentValidatorsCount(
        uint256 currentModuleExitedValidatorsCount,
        uint256 currentNodeOpExitedValidatorsCount,
        uint256 currentNodeOpStuckValidatorsCount
    );
    error UnexpectedFinalExitedValidatorsCount (
        uint256 newModuleTotalExitedValidatorsCount,
        uint256 newModuleTotalExitedValidatorsCountInStakingRouter
    );
    error InvalidDepositsValue(uint256 etherValue, uint256 depositsCount);
    error StakingModuleAddressExists();
    error ArraysLengthMismatch(uint256 firstArrayLength, uint256 secondArrayLength);
    error UnrecoverableModuleError();
    error InvalidPriorityExitShareThreshold();
    error InvalidMinDepositBlockDistance();
    error InvalidMaxDepositPerBlockValue();

    enum StakingModuleStatus {
        Active, // deposits and rewards allowed
        DepositsPaused, // deposits NOT allowed, rewards allowed
        Stopped // deposits and rewards NOT allowed
    }

    struct StakingModule {
        /// @notice Unique id of the staking module.
        uint24 id;
        /// @notice Address of the staking module.
        address stakingModuleAddress;
        /// @notice Part of the fee taken from staking rewards that goes to the staking module.
        uint16 stakingModuleFee;
        /// @notice Part of the fee taken from staking rewards that goes to the treasury.
        uint16 treasuryFee;
        /// @notice Maximum stake share that can be allocated to a module, in BP.
        /// @dev Formerly known as `targetShare`.
        uint16 stakeShareLimit;
        /// @notice Staking module status if staking module can not accept the deposits or can
        /// participate in further reward distribution.
        uint8 status;
        /// @notice Name of the staking module.
        string name;
        /// @notice block.timestamp of the last deposit of the staking module.
        /// @dev NB: lastDepositAt gets updated even if the deposit value was 0 and no actual deposit happened.
        uint64 lastDepositAt;
        /// @notice block.number of the last deposit of the staking module.
        /// @dev NB: lastDepositBlock gets updated even if the deposit value was 0 and no actual deposit happened.
        uint256 lastDepositBlock;
        /// @notice Number of exited validators.
        uint256 exitedValidatorsCount;
        /// @notice Module's share threshold, upon crossing which, exits of validators from the module will be prioritized, in BP.
        uint16 priorityExitShareThreshold;
        /// @notice The maximum number of validators that can be deposited in a single block.
        /// @dev Must be harmonized with `OracleReportSanityChecker.appearedValidatorsPerDayLimit`.
        /// See docs for the `OracleReportSanityChecker.setAppearedValidatorsPerDayLimit` function.
        uint64 maxDepositsPerBlock;
        /// @notice The minimum distance between deposits in blocks.
        /// @dev Must be harmonized with `OracleReportSanityChecker.appearedValidatorsPerDayLimit`.
        /// See docs for the `OracleReportSanityChecker.setAppearedValidatorsPerDayLimit` function).
        uint64 minDepositBlockDistance;
    }

    struct StakingModuleCache {
        address stakingModuleAddress;
        uint24 stakingModuleId;
        uint16 stakingModuleFee;
        uint16 treasuryFee;
        uint16 stakeShareLimit;
        StakingModuleStatus status;
        uint256 activeValidatorsCount;
        uint256 availableValidatorsCount;
    }

    bytes32 public constant MANAGE_WITHDRAWAL_CREDENTIALS_ROLE = keccak256("MANAGE_WITHDRAWAL_CREDENTIALS_ROLE");
    bytes32 public constant STAKING_MODULE_MANAGE_ROLE = keccak256("STAKING_MODULE_MANAGE_ROLE");
    bytes32 public constant STAKING_MODULE_UNVETTING_ROLE = keccak256("STAKING_MODULE_UNVETTING_ROLE");
    bytes32 public constant REPORT_EXITED_VALIDATORS_ROLE = keccak256("REPORT_EXITED_VALIDATORS_ROLE");
    bytes32 public constant UNSAFE_SET_EXITED_VALIDATORS_ROLE = keccak256("UNSAFE_SET_EXITED_VALIDATORS_ROLE");
    bytes32 public constant REPORT_REWARDS_MINTED_ROLE = keccak256("REPORT_REWARDS_MINTED_ROLE");

    bytes32 internal constant LIDO_POSITION = keccak256("lido.StakingRouter.lido");

    /// @dev Credentials to withdraw ETH on Consensus Layer side.
    bytes32 internal constant WITHDRAWAL_CREDENTIALS_POSITION = keccak256("lido.StakingRouter.withdrawalCredentials");

    /// @dev Total count of staking modules.
    bytes32 internal constant STAKING_MODULES_COUNT_POSITION = keccak256("lido.StakingRouter.stakingModulesCount");
    /// @dev Id of the last added staking module. This counter grow on staking modules adding.
    bytes32 internal constant LAST_STAKING_MODULE_ID_POSITION = keccak256("lido.StakingRouter.lastStakingModuleId");
    /// @dev Mapping is used instead of array to allow to extend the StakingModule.
    bytes32 internal constant STAKING_MODULES_MAPPING_POSITION = keccak256("lido.StakingRouter.stakingModules");
    /// @dev Position of the staking modules in the `_stakingModules` map, plus 1 because
    /// index 0 means a value is not in the set.
    bytes32 internal constant STAKING_MODULE_INDICES_MAPPING_POSITION = keccak256("lido.StakingRouter.stakingModuleIndicesOneBased");

    uint256 public constant FEE_PRECISION_POINTS = 10 ** 20; // 100 * 10 ** 18
    uint256 public constant TOTAL_BASIS_POINTS = 10000;
    uint256 public constant MAX_STAKING_MODULES_COUNT = 32;
    /// @dev Restrict the name size with 31 bytes to storage in a single slot.
    uint256 public constant MAX_STAKING_MODULE_NAME_LENGTH = 31;

}