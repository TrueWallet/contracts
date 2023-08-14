// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

/// @notice Latest configuration of deployed contracts
library MumbaiConfig {
    uint256 public constant CHAIN_ID = 80001;
    address public constant ENTRY_POINT =
        0x3d38C34Fd8972B8e6c831C447ECbb58A66b77D2C; // 0xD0b4bD942f6874adb2Fe59870ba7F9441afa93d6;
    address public constant PAYMASTER =
        0x1f61AD9Ce28F6A97bdcfe185918a0B7B116D4E3B;
    address public constant FACTORY =
        0x8c93CfaA4D5f9e08BCDCDBF285ddd7dDAa07a062; // 0xa5586a932a2F3E0148fAa5d1B772b9BF02EEE9EE
    address public constant WALLET_IMPL =
        0x35125a5f1f27D0950E0CAeDbb9A5418C739f14DA; // 0x65d5f31A1e313c4325B369b47DBf7F301F38608E; // 0xf041f38D1961C99A8925e88Fc978EdfD31c5264b
    address public constant WALLET_PROXY =
        0xa4b18f299471b60dD209a49D3d42cb2D4E5Ae691; // 0x6591dbAa59586d6216F34c997235ff0BfcbAd7Cc;

    address public constant DEPLOYER =
        0x8B2dc96fBEd0452f1386C8c2bfE713f11F88D623;
    address public constant WALLET_OWNER =
        0x8B2dc96fBEd0452f1386C8c2bfE713f11F88D623;
    address public constant BENEFICIARY =
        0xcC7d7D810132c44061d99928AA6e4D63c7c693c7;
}
