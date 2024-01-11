// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "forge-std/Script.sol";

import {TrueContractManager, ITrueContractManager} from "src/registry/TrueContractManager.sol";
import {SecurityControlModule} from "src/modules/SecurityControlModule/SecurityControlModule.sol";
import {SocialRecoveryModule} from "src/modules/SocialRecoveryModule/SocialRecoveryModule.sol";
import {TrueWallet} from "src/wallet/TrueWallet.sol";
import {TrueWalletFactory} from "src/wallet/TrueWalletFactory.sol";
import {MumbaiConfig} from "../config/MumbaiConfig.sol";


contract DeployFullScript is Script {
    TrueContractManager public contractManager;
    SecurityControlModule public securityModule;
    SocialRecoveryModule public recoveryModule;
    TrueWallet public walletImplementation;
    TrueWalletFactory public factory;
    address public entryPoint;

    address public owner;
    uint256 public deployerPrivateKey;

    function setUp() public {
        owner = vm.envAddress("OWNER");
        deployerPrivateKey = vm.envUint("PRIVATE_KEY_TESTNET");
        entryPoint = MumbaiConfig.OFFICIAL_ENTRY_POINT;
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

        walletImplementation = new TrueWallet();
        factory = new TrueWalletFactory(address(walletImplementation), owner, entryPoint);
        factory.addStake{value: 1 ether}(84600);

        console.log("==securityModule addr=%s", address(securityModule));
        console.log("==recoveryModule addr=%s", address(recoveryModule));
        console.log("==factory addr=%s", address(factory));

        vm.stopBroadcast();
    }
}
