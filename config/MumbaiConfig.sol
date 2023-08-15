// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

/// @notice Latest configuration of deployed contracts
library MumbaiConfig {
    uint256 public constant CHAIN_ID = 80001;
    address public constant ENTRY_POINT =
        0x3d38C34Fd8972B8e6c831C447ECbb58A66b77D2C; // 0xD0b4bD942f6874adb2Fe59870ba7F9441afa93d6;
    address public constant PAYMASTER =
        0x63053B4923c6149cf1E4a67aC88a41E823967704; // 0x1f61AD9Ce28F6A97bdcfe185918a0B7B116D4E3B;
    address public constant FACTORY =
        0x7dfC28B0ed5C4979b5466fb46f81F51d929E2765; // 0x8c93CfaA4D5f9e08BCDCDBF285ddd7dDAa07a062;
    address public constant WALLET_IMPL =
        0x9fE7495ACbeE05Eb5A6FDF4B24BB3c5343C1c65B; // 0x35125a5f1f27D0950E0CAeDbb9A5418C739f14DA;
    address public constant WALLET_PROXY =
        0x5EA22FBF9B5479CC067bDe28fB75B3e043654E28; // 0xa4b18f299471b60dD209a49D3d42cb2D4E5Ae691;

    address public constant DEPLOYER =
        0x8B2dc96fBEd0452f1386C8c2bfE713f11F88D623;
    address public constant WALLET_OWNER =
        0x8B2dc96fBEd0452f1386C8c2bfE713f11F88D623;
    address public constant BENEFICIARY =
        0xcC7d7D810132c44061d99928AA6e4D63c7c693c7;
}
