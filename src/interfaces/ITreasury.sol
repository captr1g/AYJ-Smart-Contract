// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ITreasury {
    // --- Events ---
    
    /// @dev Emitted when funds are deposited into the treasury.
    /// @param depositor The address of the depositor.
    /// @param amount The amount deposited.
    /// @param token The address of the ERC20 token (address(0) for native currency).
    event FundsDeposited(address indexed depositor, uint256 amount, address indexed token);

    /// @dev Emitted when funds are withdrawn from the treasury.
    /// @param recipient The address of the recipient.
    /// @param amount The amount withdrawn.
    /// @param token The address of the ERC20 token (address(0) for native currency).
    event FundsWithdrawn(address indexed recipient, uint256 amount, address indexed token);

    /// @dev Emitted when funds are transferred from the treasury.
    /// @param recipient The address of the recipient.
    /// @param amount The amount transferred.
    /// @param token The address of the ERC20 token (address(0) for native currency).
    event FundsTransferred(address indexed recipient, uint256 amount, address indexed token);

    // --- Functions ---
    
    /**
     * @dev Deposit funds into the treasury.
     * @param token The address of the ERC20 token (address(0) for native currency).
     * @param amount The amount to deposit.
     */
    function deposit(address token, uint256 amount) external payable;

    /**
     * @dev Withdraw funds from the treasury.
     * @param token The address of the ERC20 token (address(0) for native currency).
     * @param recipient The address of the recipient.
     * @param amount The amount to withdraw.
     */
    function withdraw(address token, address recipient, uint256 amount) external;

    /**
     * @dev Transfer funds from the treasury.
     * @param token The address of the ERC20 token (address(0) for native currency).
     * @param recipient The address of the recipient.
     * @param amount The amount to transfer.
     */
    function transferFunds(address token, address recipient, uint256 amount) external;

    /**
     * @dev Get the balance of a specific token or native currency in the treasury.
     * @param token The address of the ERC20 token (address(0) for native currency).
     * @return balance The balance of the specified token in the treasury.
     */
    function getBalance(address token) external view returns (uint256 balance);
}
