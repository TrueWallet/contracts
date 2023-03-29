// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "forge-std/Script.sol";

import {TrueWalletFactory} from "src/TrueWalletFactory.sol";
import {MumbaiConfig} from "../config/MumbaiConfig.sol";

contract DeployFactoryScript is Script {
    TrueWalletFactory public factory;
    address public entryPoint;

    address public owner;
    uint256 public deployerPrivateKey;

    function setUp() public {
        owner = vm.envAddress("OWNER");
        deployerPrivateKey = vm.envUint("PRIVATE_KEY_TESTNET");
    }

    function run() public {
        vm.broadcast(deployerPrivateKey);
        factory = new TrueWalletFactory(owner);
        vm.stopBroadcast();
    }
}
