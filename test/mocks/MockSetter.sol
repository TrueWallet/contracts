// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

contract MockSetter {
    uint256 public value;

    function setValue(uint256 _value) public {
        value = _value;
    }
}
