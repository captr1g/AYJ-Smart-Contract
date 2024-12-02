// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title IDepositRouter
 * @notice Interface for the DepositRouter contract
 */
interface IDepositRouter {
    /// @notice Thrown when an invalid input is provided.
    error InvalidInput();

    /// @notice Thrown when authentication fails.
    error AuthenticationFailed();

    /// @notice Thrown when an action is paused.
    error ActionPaused();

    /// @notice Thrown when there is an insufficient balance.
    error InsufficientBalance();

    /// @notice Deposits eETH tokens.
    function depositEEth(
        uint256 _tokenAmount,
        address _delegateTo,
        address _referredBy,
        bool _lazyMint
    ) external returns (uint256);

    /// @notice Deposits ETH.
    function depositEth(address _delegateTo, address _referredBy, bool _lazyMint) external payable returns (uint256);

    /// @notice Deposits WETH tokens.
    function depositWEth(
        uint256 _tokenAmount,
        address _delegateTo,
        address _referredBy,
        bool _lazyMint
    ) external returns (uint256);

    /// @notice Deposits stETH tokens.
    function depositStEth(
        uint256 _tokenAmount,
        address _delegateTo,
        address _referredBy,
        bool _lazyMint
    ) external returns (uint256);

    /// @notice Deposits wstETH tokens.
    function depositWstEth(
        uint256 _tokenAmount,
        address _delegateTo,
        address _referredBy,
        bool _lazyMint
    ) external returns (uint256);
}