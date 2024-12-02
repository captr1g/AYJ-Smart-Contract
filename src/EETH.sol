// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;
import { IeETH } from "./interfaces/IeETH.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract wASTR is ERC20 {
    constructor() ERC20("EETH", "eETH") {}

    function deposit() external payable {
        _mint(msg.sender, msg.value);
    }
    function withdraw(uint wad) external {
        _burn(msg.sender, wad);
        payable(msg.sender).transfer(wad);
    }
}