// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("","") {}

    function mint(address account, uint256 amount) public returns (bool) {
        _mint(account, amount);
        return true;
    }

    function burn(address from, uint256 value) public returns (bool) {
        _burn(from, value);
        return true;
    }
}
