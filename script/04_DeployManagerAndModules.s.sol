// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "forge-std/Script.sol";

import {TrueContractManager, ITrueContractManager} from "src/registry/TrueContractManager.sol";
import {SecurityControlModule} from "src/modules/SecurityControlModule/SecurityControlModule.sol";
import {SocialRecoveryModule} from "src/modules/SocialRecoveryModule/SocialRecoveryModule.sol";
import {MumbaiConfig} from "../config/MumbaiConfig.sol";

contract DeployManagerAndModules is Script {
    TrueContractManager public contractManager;
    // TrueContractManager public contractManager =
    //     TrueContractManager(MumbaiConfig.CONTRACT_MANAGER);
    SecurityControlModule public securityModule;
    SocialRecoveryModule public recoveryModule;

    address public owner;
    uint256 public deployerPrivateKey;

    function setUp() public {
        owner = vm.envAddress("OWNER");
        deployerPrivateKey = vm.envUint("PRIVATE_KEY_TESTNET");
    }

    function run() public {
        vm.startBroadcast(deployerPrivateKey);
        contractManager = new TrueContractManager(address(owner));
        securityModule = new SecurityControlModule(ITrueContractManager(contractManager));
        recoveryModule = new SocialRecoveryModule();
        address[] memory modules = new address[](2);
        modules[0] = address(securityModule);
        modules[1] = address(recoveryModule);
        contractManager.add(modules);
        vm.stopBroadcast();
    }
}
