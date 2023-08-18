// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "forge-std/Script.sol";

import {TrueWallet} from "src/wallet/TrueWallet.sol";
import {Paymaster} from "src/paymaster/Paymaster.sol";
import {MumbaiConfig} from "../config/MumbaiConfig.sol";

contract DeployPaymasterScript is Script {
    TrueWallet public wallet;
    Paymaster public paymaster;
    address public entryPoint;

    address public owner;
    uint256 public deployerPrivateKey;

    function setUp() public {
        owner = vm.envAddress("OWNER");
        deployerPrivateKey = vm.envUint("PRIVATE_KEY_TESTNET");
        entryPoint = MumbaiConfig.ENTRY_POINT;
    }

    function run() public {
        vm.startBroadcast(deployerPrivateKey);
        paymaster = new Paymaster(entryPoint, owner);
        vm.stopBroadcast();
    }
}
