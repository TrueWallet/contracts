// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

/// @notice Latest configuration of deployed contracts
library SepoliaConfig {
    uint256 public constant CHAIN_ID = 11155111;

    address public constant ENTRY_POINT_V6 = 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789;
    address public constant WALLET_OWNER = 0x8B2dc96fBEd0452f1386C8c2bfE713f11F88D623; // Admin EOA
    address public constant DEPLOYER_EOA = 0xDA2C01980bB59dD6b7Cb4D800007ea67c7282280;

    ///@dev Cross-Chain Deterministic Contract Addresses
    address public constant WALLET_IMPL_1 = 0x26c44D4bbb2208549958de195537BFCdD1a5a047;
    address public constant DEPLOYER_CONTRACT_1 = 0xe4E583dc4d0E96a1a00C97E3b5E03e296060fD8f;
    address public constant FACTORY_1 = 0x01745b9B7Eb2f9AD241EFE07AF9a2A16d78CA006;
    address public constant CONTRACT_MANAGER_1 = 0x3A7c67f5844c32C9f5c69d2d7AF8d9b3CabEE128;
    address public constant SECURITY_CONTROL_MODULE_1 = 0x4f9634fC0775E446406b6b426f9C45CF1D2e16BF;
    address public constant SOCIAL_RECOVERY_MODULE_1 = 0x24ec1D08f9D21AC0f7D46C705d080717F34eE947;
    address public constant WALLET_PROXY_1 = 0xb3Ec27B151807A2cf6c1CAd9BDb0B3D19668eC41;
}