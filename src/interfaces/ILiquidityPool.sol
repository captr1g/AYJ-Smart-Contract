// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface ILiquidityPool {
    function deposit(address _referral) external payable returns (uint256);
    function rebase(int128 _accruedRewards) external;
}