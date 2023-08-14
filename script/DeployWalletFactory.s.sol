// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "forge-std/Script.sol";

import {TrueWalletFactory} from "src/wallet/TrueWalletFactory.sol";
import {MumbaiConfig} from "../config/MumbaiConfig.sol";

contract DeployWalletFactoryScript is Script {
    TrueWalletFactory public factory;
    address public walletImplementaion;

    address public owner;
    uint256 public deployerPrivateKey;

    function setUp() public {
        owner = vm.envAddress("OWNER");
        deployerPrivateKey = vm.envUint("PRIVATE_KEY_TESTNET");
        walletImplementaion = MumbaiConfig.WALLET_IMPL;
    }

    function run() public {
        vm.startBroadcast(deployerPrivateKey);
        factory = new TrueWalletFactory(address(walletImplementaion), owner);
        vm.stopBroadcast();
    }
}
