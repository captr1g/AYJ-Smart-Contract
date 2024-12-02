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
    IeETH public immutable eETH;
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
        eETH = IeETH(_eETH);
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
     * @notice Deposits ETH into the Liquidity Pool
     * @return shares Amount of LP shares received
     */
    function depositToLP(address _referral) external payable validateAmount(msg.value) returns (uint256 shares) {
        shares = liquidityPool.deposit(_referral);
        
        userLPStakes[msg.sender].push(LPStaking({
            lpShares: shares,
            depositAmount: msg.value,
            timestamp: block.timestamp
        }));
        totalLPStakes++;
        return shares;
    }

    /**
     * @notice Deposits ETH into the Vault
     * @return weETHAmount Amount of weETH received
     */
    function depositToVault() external payable validateAmount(msg.value) returns (uint256 weETHAmount) {
        uint256 exchangeRate = 1e18;
        // Calculate weETH amount
        weETHAmount = (msg.value * 1e18) / exchangeRate;

        userVaultStakes[msg.sender].push(VaultStaking({
            weETHAmount: weETHAmount,
            depositAmount: msg.value,
            timestamp: block.timestamp
        }));
        totalVaultStakes++;

        wETH.deposit{ value: msg.value }();
        wETH.approve(vault, msg.value);
        wETH.safeTransfer(vault, msg.value);
        weETH.wrap(weETHAmount);
        return weETHAmount;
    }

    /**
     * @notice Deposits ETH directly for staking through ETHerFi
     * @return eETHAmount Amount of eETH received
     */
    function depositForStaking() external payable validateAmount(msg.value) returns (uint256 eETHAmount) {
        // Assuming eETHAmount calculation will be implemented
        eETH.deposit{ value: msg.value }();
        wETH.deposit{ value: msg.value }();
        weETH.deposit{ value: msg.value }();
        // This should be adjusted based on actual conversion rate

        userEtherFiStakes[msg.sender].push(EtherFiStaking({
            eETHAmount: eETHAmount,
            depositAmount: msg.value,
            timestamp: block.timestamp
        }));
        totalEtherFiStakes++;

        return eETHAmount;
    }

    /**
     * @notice Withdraws ETH from the Liquidity Pool
     * @param _stakeIndex Index of the LP stake to withdraw
     * @return amount Amount of ETH withdrawn
     */
    function withdrawFromLP(uint256 _stakeIndex) external returns (uint256 amount) {
        if (_stakeIndex >= userLPStakes[msg.sender].length) revert IDepositRouter.InvalidInput();
        
        LPStaking memory stake = userLPStakes[msg.sender][_stakeIndex];
        if (stake.lpShares == 0) revert IDepositRouter.AlreadyWithdrawn();

        // Remove the stake by setting shares to 0
        userLPStakes[msg.sender][_stakeIndex].lpShares = 0;
        totalLPStakes--;

        // Withdraw from liquidity pool
        amount = liquidityPool.withdraw(stake.lpShares, msg.sender);
        return amount;
    }

    /**
     * @notice Withdraws ETH from the Vault
     * @param _stakeIndex Index of the vault stake to withdraw
     * @return amount Amount of ETH withdrawn
     */
    function withdrawFromVault(uint256 _stakeIndex) external returns (uint256 amount) {
        if (_stakeIndex >= userVaultStakes[msg.sender].length) revert IDepositRouter.InvalidInput();
        
        VaultStaking memory stake = userVaultStakes[msg.sender][_stakeIndex];
        if (stake.weETHAmount == 0) revert IDepositRouter.AlreadyWithdrawn();

        // Remove the stake by setting amount to 0
        userVaultStakes[msg.sender][_stakeIndex].weETHAmount = 0;
        totalVaultStakes--;

        // Burn weETH and withdraw ETH
        weETH.burn(msg.sender, stake.weETHAmount);
        amount = stake.weETHAmount * weETH.getExchangeRate() / 1e18;
        
        // Transfer ETH back to user
        (bool success, ) = msg.sender.call{ value: amount }("");
        if (!success) revert IDepositRouter.TransferFailed();
        
        return amount;
    }

    /**
     * @notice Withdraws ETH from EtherFi staking
     * @param _stakeIndex Index of the EtherFi stake to withdraw
     * @return amount Amount of ETH withdrawn
     */
    function withdrawFromStaking(uint256 _stakeIndex) external returns (uint256 amount) {
        if (_stakeIndex >= userEtherFiStakes[msg.sender].length) revert IDepositRouter.InvalidInput();
        
        EtherFiStaking memory stake = userEtherFiStakes[msg.sender][_stakeIndex];
        if (stake.eETHAmount == 0) revert IDepositRouter.AlreadyWithdrawn();

        // Remove the stake by setting amount to 0
        userEtherFiStakes[msg.sender][_stakeIndex].eETHAmount = 0;
        totalEtherFiStakes--;

        // Convert eETH back to ETH (implementation depends on EtherFi protocol)
        IeETH eeth = IeETH(address(eETH));
        amount = stake.eETHAmount; // This should be adjusted based on actual conversion rate
        eeth.burn(msg.sender, stake.eETHAmount);
        
        // Transfer ETH back to user
        (bool success, ) = msg.sender.call{ value: amount }("");
        if (!success) revert IDepositRouter.TransferFailed();

        return amount;
    }

    // Add these errors to your IDepositRouter interface
    /**
     * @notice View function to get all LP stakes for a user
     * @param _user Address of the user
     * @return LPStaking[] Array of LP stakes
     */
    function getUserLPStakes(address _user) external view returns (LPStaking[] memory) {
        return userLPStakes[_user];
    }

    /**
     * @notice View function to get all vault stakes for a user
     * @param _user Address of the user
     * @return VaultStaking[] Array of vault stakes
     */
    function getUserVaultStakes(address _user) external view returns (VaultStaking[] memory) {
        return userVaultStakes[_user];
    }

    /**
     * @notice View function to get all EtherFi stakes for a user
     * @param _user Address of the user
     * @return EtherFiStaking[] Array of EtherFi stakes
     */
    function getUserEtherFiStakes(address _user) external view returns (EtherFiStaking[] memory) {
        return userEtherFiStakes[_user];
    }
}