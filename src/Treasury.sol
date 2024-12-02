// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ITreasury.sol";

contract Treasury is Ownable, ITreasury {
    constructor() Ownable(msg.sender) {}
    
    // --- Functions Implementation ---
    
    function deposit(address token, uint256 amount) external payable override {
        if (token == address(0)) {
            require(msg.value == amount, "Mismatch between sent value and specified amount");
            emit ITreasury.FundsDeposited(msg.sender, amount, address(0));
        } else {
            require(amount > 0, "Amount must be greater than zero");
            IERC20(token).transferFrom(msg.sender, address(this), amount);
            emit ITreasury.FundsDeposited(msg.sender, amount, token);
        }
    }

    function withdraw(address token, address recipient, uint256 amount) external override onlyOwner {
        require(recipient != address(0), "Recipient cannot be zero address");
        require(amount > 0, "Amount must be greater than zero");

        if (token == address(0)) {
            require(address(this).balance >= amount, "Insufficient native currency balance");
            (bool success, ) = recipient.call{value: amount}("");
            require(success, "Native currency transfer failed");
        } else {
            require(IERC20(token).balanceOf(address(this)) >= amount, "Insufficient token balance");
            IERC20(token).transfer(recipient, amount);
        }

        emit ITreasury.FundsWithdrawn(recipient, amount, token);
    }

    function transferFunds(address token, address recipient, uint256 amount) external override onlyOwner {
        require(recipient != address(0), "Recipient cannot be zero address");
        require(amount > 0, "Amount must be greater than zero");

        if (token == address(0)) {
            require(address(this).balance >= amount, "Insufficient native currency balance");
            (bool success, ) = recipient.call{value: amount}("");
            require(success, "Native currency transfer failed");
        } else {
            require(IERC20(token).balanceOf(address(this)) >= amount, "Insufficient token balance");
            IERC20(token).transfer(recipient, amount);
        }

        emit FundsTransferred(recipient, amount, token);
    }

    function getBalance(address token) external view override returns (uint256 balance) {
        if (token == address(0)) {
            balance = address(this).balance;
        } else {
            balance = IERC20(token).balanceOf(address(this));
        }
    }

    // Fallback function to accept native currency
    receive() external payable {
    }
}
