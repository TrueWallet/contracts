// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

/// @notice Latest configuration of deployed contracts
library MumbaiConfig {
    uint256 public constant CHAIN_ID = 80001;
    
    address public constant ENTRY_POINT_V6 = 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789;
    address public constant WALLET_OWNER = 0x8B2dc96fBEd0452f1386C8c2bfE713f11F88D623;
    address public constant DEPLOYER_EOA = 0xDA2C01980bB59dD6b7Cb4D800007ea67c7282280;

    address public constant PAYMASTER = 0x63053B4923c6149cf1E4a67aC88a41E823967704;
    address public constant BENEFICIARY = 0xcC7d7D810132c44061d99928AA6e4D63c7c693c7;

    ///@dev Cross-Chain Deterministic Contract Addresses
    address public constant WALLET_IMPL = 0x26c44D4bbb2208549958de195537BFCdD1a5a047;
    address public constant DEPLOYER_CONTRACT = 0xe4E583dc4d0E96a1a00C97E3b5E03e296060fD8f;
    address public constant FACTORY = 0x01745b9B7Eb2f9AD241EFE07AF9a2A16d78CA006;
    address public constant CONTRACT_MANAGER = 0x3A7c67f5844c32C9f5c69d2d7AF8d9b3CabEE128;
    address public constant SECURITY_CONTROL_MODULE = 0x4f9634fC0775E446406b6b426f9C45CF1D2e16BF;
    address public constant SOCIAL_RECOVERY_MODULE = 0x24ec1D08f9D21AC0f7D46C705d080717F34eE947;
    address public constant WALLET_PROXY = 0xb3Ec27B151807A2cf6c1CAd9BDb0B3D19668eC41;
}
