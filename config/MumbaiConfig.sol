// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

/// @notice Latest configuration of deployed contracts
library MumbaiConfig {
    uint256 public constant CHAIN_ID = 80001;
    address public constant ENTRY_POINT = 0x3d38C34Fd8972B8e6c831C447ECbb58A66b77D2C;
    address public constant PAYMASTER = 0x63053B4923c6149cf1E4a67aC88a41E823967704;
    address public constant FACTORY = 0x1C600Da645a3bC0A951C9839E49e541D49ea7688;
    address public constant WALLET_IMPL = 0xeafbAc31B04F0a178612604060C1100a3321632D;
    address public constant WALLET_PROXY = 0x399f10066B2aD2D3aeA227A792E73D6322b29ED9;

    address public constant CONTRACT_MANAGER = 0x406AB3ff00B6Ef7cCd0F707C61f2b82494022AA1; // TrueContractManager
    address public constant SECURITY_CONTROL_MODULE = 0x3735BA2b6193E5da3B57785cCb0372b0031b4A06;
    address public constant SOCIAL_RECOVERY_MODULE = 0xE680adEF8d3ac23e0434217278d311f88a7319e5;

    address public constant DEPLOYER = 0x8B2dc96fBEd0452f1386C8c2bfE713f11F88D623;
    address public constant BENEFICIARY = 0xcC7d7D810132c44061d99928AA6e4D63c7c693c7;
    
    address public constant ENTRY_POINT_V6 = 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789;
    address public constant WALLET_OWNER = 0x8B2dc96fBEd0452f1386C8c2bfE713f11F88D623;
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
