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
        0x85b7Da1179f8FF2B466737b1275D2551b0af0Abd; // 0x9bD998675E887d11386d0bFa067132951e3418B4; // 0xbb37a6dFfC9158C909e7d26f32F335886294C5Dd;
    address public constant WALLET_IMPL =
        0xD52154bd4b275D7D6059D68A730003E5E85F42b6; // 0x404189d9De710829a21b8c684FCcfdB4C7E9a50A; // 0x9fE7495ACbeE05Eb5A6FDF4B24BB3c5343C1c65B;
    address public constant WALLET_PROXY =
        0xA2972a3Fc9bb832fad1c0449A35696795BC89d45; // 0x77230962B3C4451dA208194a73A609934CEa2b83; // 0xA2972a3Fc9bb832fad1c0449A35696795BC89d45;

    address public constant CONTRACT_MANAGER =
        0x406AB3ff00B6Ef7cCd0F707C61f2b82494022AA1; // TrueContractManager
    address public constant SECURITY_CONTROL_MODULE =
        0xA9344567aF3704D16EAa4c7862FC53E4AeeF9bD6; // SecurityControlModule

    address public constant DEPLOYER =
        0x8B2dc96fBEd0452f1386C8c2bfE713f11F88D623;
    address public constant WALLET_OWNER =
        0x8B2dc96fBEd0452f1386C8c2bfE713f11F88D623;
    address public constant BENEFICIARY =
        0xcC7d7D810132c44061d99928AA6e4D63c7c693c7;
}
