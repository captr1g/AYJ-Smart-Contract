// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title IWETH Interface
interface IWETH is IERC20 {
    /// @notice Allows users to deposit ETH tokens and receive wETH tokens in return.
    function deposit() external payable;

    /// @notice Allows users to withdraw ETH tokens by burning their wETH tokens.
    function withdraw(uint wad) external;
}