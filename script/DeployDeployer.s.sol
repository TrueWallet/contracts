// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "forge-std/Script.sol";

import {Deployer} from "src/deployer/Deployer.sol";
import {MumbaiConfig} from "../config/MumbaiConfig.sol";

contract DeployDeployerScript is Script {
    Deployer public deployer;
    address public entryPoint;
    address public walletImplementation;

    address public owner;
    uint256 public deployerPrivateKey;

    function setUp() public {
        owner = vm.envAddress("OWNER");
        deployerPrivateKey = vm.envUint("PRIVATE_KEY_TESTNET");
        walletImplementation = MumbaiConfig.WALLET_IMPL;
        entryPoint = MumbaiConfig.ENTRY_POINT_V6;
    }

    function run() public {
        vm.startBroadcast(deployerPrivateKey);
        deployer = new Deployer();
        vm.stopBroadcast();
    }
}
