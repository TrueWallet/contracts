// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

/// @notice Latest configuration of deployed contracts
library MumbaiConfig {
    uint256 public constant CHAIN_ID = 80001;
    address public constant ENTRY_POINT = 0x3d38C34Fd8972B8e6c831C447ECbb58A66b77D2C; // 0xD0b4bD942f6874adb2Fe59870ba7F9441afa93d6;
    address public constant PAYMASTER = 0x63053B4923c6149cf1E4a67aC88a41E823967704; // 0x4864fF82c22c2B473EdbFaBE7eac880B0Ad57F9e;
    address public constant FACTORY = 0x1C600Da645a3bC0A951C9839E49e541D49ea7688; //0xd4c83DF44115999261b97A9321D44467FA12A94e;
    address public constant WALLET_IMPL = 0xeafbAc31B04F0a178612604060C1100a3321632D; //0xe418f2Ab2fE248BAc5349a6FAbF338824Cd0a10A;
    address public constant WALLET_PROXY = 0x6Eb7A65e3166A221C7746dE4D53463aaBA54a86B; //0x72dFbeCE20BbE2260Ca1F6f689c2543d53268C51;

    address public constant CONTRACT_MANAGER = 0x406AB3ff00B6Ef7cCd0F707C61f2b82494022AA1; // TrueContractManager
    address public constant SECURITY_CONTROL_MODULE = 0xA9344567aF3704D16EAa4c7862FC53E4AeeF9bD6; // SecurityControlModule
    address public constant SOCIAL_RECOVERY_MODULE = 0xA6bE902E27788E36ac7a180cDaAB176a6B88935f; // SocialRecoveryModule

    address public constant DEPLOYER = 0x8B2dc96fBEd0452f1386C8c2bfE713f11F88D623;
    address public constant WALLET_OWNER = 0x8B2dc96fBEd0452f1386C8c2bfE713f11F88D623;
    address public constant BENEFICIARY = 0xcC7d7D810132c44061d99928AA6e4D63c7c693c7;

    address public constant OFFICIAL_ENTRY_POINT = 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789;
}
