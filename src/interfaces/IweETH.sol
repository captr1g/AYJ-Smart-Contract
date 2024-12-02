// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IweETH
 * @notice Interface for interacting with the IweETH token contract.
 * @author neemo
 */
interface IweETH is IERC20 {
    function wrap(uint256 _amount) external returns (uint256);
    function unwrap(uint256 _amount) external returns (uint256);
    function getRate() external view returns (uint256);
    function getEETHByWeETH(uint256 _weEthAmount) external view returns (uint256);
    function getWeETHByEETH(uint256 _eEthAmount) external view returns (uint256);
    function mint(address to, uint256 amount) external returns (bool);
    function deposit() external payable;
    function getExchangeRate() external view returns (uint256);
    function burn(address from, uint256 amount) external;
}