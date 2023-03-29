// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

/// @notice Latest configuration of deployed contracts
library MumbaiConfig {
    uint256 public constant CHAIN_ID = 80001;
    address public constant ENTRY_POINT = 0xD0b4bD942f6874adb2Fe59870ba7F9441afa93d6;
    address public constant PAYMASTER = 0x1f61AD9Ce28F6A97bdcfe185918a0B7B116D4E3B;
    address public constant FACTORY = 0xa5586a932a2F3E0148fAa5d1B772b9BF02EEE9EE;
    address public constant WALLET = 0x3722C008Eb0ce8ba68542C9f3D55ebC132E31210;
}