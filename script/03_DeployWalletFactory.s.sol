// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "forge-std/Script.sol";

import {TrueWalletFactory} from "src/wallet/TrueWalletFactory.sol";
import {IEntryPoint} from "account-abstraction/interfaces/IEntryPoint.sol";
import {MumbaiConfig} from "../config/MumbaiConfig.sol";

contract DeployWalletFactoryScript is Script {
    TrueWalletFactory public factory;
    address public entryPoint;
    address public walletImplementation;

    address public owner;
    uint256 public deployerPrivateKey;

    function setUp() public {
        owner = vm.envAddress("OWNER");
        deployerPrivateKey = vm.envUint("PRIVATE_KEY_TESTNET");
        entryPoint = MumbaiConfig.ENTRY_POINT_V6;
        walletImplementation = MumbaiConfig.WALLET_IMPL;
    }

    function run() public {
        vm.startBroadcast(deployerPrivateKey);
        factory = new TrueWalletFactory(address(walletImplementation), owner, entryPoint);
        vm.stopBroadcast();
    }
}
