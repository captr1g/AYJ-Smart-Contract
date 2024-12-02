// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IDepositRouter.sol";
import "./interfaces/IwETH.sol";
import "./interfaces/IweETH.sol";
import "./interfaces/ILiquidityPool.sol";
import "./interfaces/IeETH.sol";
import "./interfaces/IStakingManager.sol";
/**
 * @title DepositRouter
 * @notice Handles deposits of multiple token types and conversion into `weETH` for staking.
 */
contract DepositRouter {
    using SafeERC20 for IERC20;
    using SafeERC20 for IWETH;
    using SafeERC20 for IeETH;

    // Structs for different types of deposits
    struct LPStaking {
        uint256 lpShares;
        uint256 depositAmount;
        uint256 timestamp;
    }

    struct VaultStaking {
        uint256 weETHAmount;
        uint256 depositAmount;
        uint256 timestamp;
    }

    struct EtherFiStaking {
        uint256 eETHAmount;
        uint256 depositAmount;
        uint256 timestamp;
    }

    // Mappings for each type of staking
    mapping(address => LPStaking[]) public userLPStakes;
    mapping(address => VaultStaking[]) public userVaultStakes;
    mapping(address => EtherFiStaking[]) public userEtherFiStakes;

    // Counters for each type
    uint256 public totalLPStakes;
    uint256 public totalVaultStakes;
    uint256 public totalEtherFiStakes;

    //---------------------------------  State Vars  ----------------------------------------//
    IWETH public immutable wETH;
    IERC20 public immutable eETH;
    IweETH public immutable weETH;
    ILiquidityPool public immutable liquidityPool;
    address public immutable treasury;
    address vault;

    //---------------------------------  Initializer  ----------------------------------------//
    /**
     * @dev Initializes the DepositRouter contract with required dependencies.
     * @param _wETH Address of the wETH token.
     * @param _eETH Address of the eETH token.
     * @param _weETH Address of the wrapped eEth token.
     * @param _LP Address of liquidity pool.
     * @param _treasury Address of the treasury.
     * @param _vault Address of the vault.
     **/
    constructor(
        address _wETH,
        address _eETH,
        address _weETH,
        address _LP,
        address _treasury,
        address _vault
    ) {
        if (
            _wETH == address(0x0) ||
            _eETH == address(0x0) ||
            _weETH == address(0x0) ||
            _LP == address(0x0) ||
            _vault == address(0x0) ||
            _treasury == address(0x0)
        ) revert IDepositRouter.InvalidInput();

        wETH = IWETH(_wETH);
        eETH = IERC20(_eETH);
        weETH = IweETH(_weETH);
        vault = _vault;
        treasury = _treasury;
        liquidityPool = ILiquidityPool(_LP);
    }

    modifier validateAmount(uint256 _amount) {
        if (_amount <= 0) revert IDepositRouter.InvalidInput();
        _;
    }

    /**
     * @notice Deposits ETH and receives eETH tokens for EtherFi staking
     * @dev User must send ETH with this transaction
     */
    function etherfiDeposit() external payable validateAmount(msg.value) {
        // Convert ETH to eETH
        uint256 eETHAmount = IStakingManager(vault).deposit{ value: msg.value }();
        
        // Record the stake
        userEtherFiStakes[msg.sender].push(
            EtherFiStaking({
                eETHAmount: eETHAmount,
                depositAmount: msg.value,
                timestamp: block.timestamp
            })
        );
        totalEtherFiStakes++;
    }

    /**
     * @notice Deposits LP tokens for staking
     * @param _amount Amount of LP tokens to deposit
     */
    function lpDeposit(uint256 _amount) external validateAmount(_amount) {
        // Transfer LP tokens from user
        liquidityPool.transferFrom(msg.sender, address(this), _amount);
        
        // Record the stake
        userLPStakes[msg.sender].push(
            LPStaking({
                lpShares: _amount,
                depositAmount: _amount,
                timestamp: block.timestamp
            })
        );
        totalLPStakes++;
    }

    /**
     * @notice Deposits wETH tokens for vault staking
     * @param _amount Amount of wETH to deposit
     */
    function vaultDeposit(uint256 _amount) external validateAmount(_amount) {
        // Transfer wETH from user
        wETH.safeTransferFrom(msg.sender, address(this), _amount);
        
        // Approve vault to use wETH
        wETH.safeApprove(vault, _amount);
        
        // Convert wETH to weETH through vault
        uint256 weETHAmount = IStakingManager(vault).depositWETH(_amount);
        
        // Record the stake
        userVaultStakes[msg.sender].push(
            VaultStaking({
                weETHAmount: weETHAmount,
                depositAmount: _amount,
                timestamp: block.timestamp
            })
        );
        totalVaultStakes++;
    }

    function calculateWeeklyReward(uint256 rate) external view returns (uint256 reward) {
        uint256 totalPrincipal = 0;
        
        // Sum up LP stakes
        LPStaking[] memory lpStakes = userLPStakes[msg.sender];
        for (uint256 i = 0; i < lpStakes.length; i++) {
            totalPrincipal += lpStakes[i].depositAmount;
        }
        
        // Sum up Vault stakes
        VaultStaking[] memory vaultStakes = userVaultStakes[msg.sender];
        for (uint256 i = 0; i < vaultStakes.length; i++) {
            totalPrincipal += vaultStakes[i].depositAmount;
        }
        
        // Sum up EtherFi stakes
        EtherFiStaking[] memory etherFiStakes = userEtherFiStakes[msg.sender];
        for (uint256 i = 0; i < etherFiStakes.length; i++) {
            totalPrincipal += etherFiStakes[i].depositAmount;
        }

        // Calculate reward based on total principal
        // rate is divided by 10,000 to convert basis points to a percentage
        reward = (totalPrincipal * rate * SECONDS_IN_A_WEEK) / (SECONDS_IN_A_YEAR * 10000);
    }
}