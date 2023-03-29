// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "forge-std/Script.sol";

import {TrueWallet} from "src/TrueWallet.sol";
import {MumbaiConfig} from "../config/MumbaiConfig.sol";

contract DeployWalletScript is Script {
    TrueWallet public wallet;
    address public entryPoint;

    address public owner;
    uint256 public deployerPrivateKey;

    function setUp() public {
        owner = vm.envAddress("OWNER");
        deployerPrivateKey = vm.envUint("PRIVATE_KEY_TESTNET");
        entryPoint = MumbaiConfig.ENTRY_POINT;
    }

    function run() public {
        vm.broadcast(deployerPrivateKey);
        wallet = new TrueWallet(entryPoint, owner);
        vm.stopBroadcast();
    }
}
