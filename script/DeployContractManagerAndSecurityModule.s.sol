// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "forge-std/Script.sol";

import {TrueContractManager, ITrueContractManager} from "src/registry/TrueContractManager.sol";
import {SecurityControlModule} from "src/modules/SecurityControlModule/SecurityControlModule.sol";
import {MumbaiConfig} from "../config/MumbaiConfig.sol";

contract DeployContractManagerAndSecurityModule is Script {
    TrueContractManager public contractManager;
    SecurityControlModule public securityModule;

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
        address[] memory modules = new address[](1);
        modules[0] = address(securityModule);
        contractManager.add(modules);
        vm.stopBroadcast();
    }
}
