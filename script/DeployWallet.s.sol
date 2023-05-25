// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "forge-std/Script.sol";

import {TrueWallet} from "src/wallet/TrueWallet.sol";
import {MumbaiConfig} from "../config/MumbaiConfig.sol";

contract DeployWalletScript is Script {
    TrueWallet public wallet;

    address public owner;
    uint256 public deployerPrivateKey;

    function setUp() public {
        owner = vm.envAddress("OWNER");
        deployerPrivateKey = vm.envUint("PRIVATE_KEY_TESTNET");
    }

    function run() public {
        vm.startBroadcast(deployerPrivateKey);
        wallet = new TrueWallet();
        vm.stopBroadcast();
    }
}