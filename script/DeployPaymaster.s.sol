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

    address public ownerPublicKey;
    uint256 public ownerPrivateKey;

    function setUp() public {
        ownerPublicKey = vm.envAddress("OWNER");
        ownerPrivateKey = vm.envUint("PRIVATE_KEY_TESTNET");
        entryPoint = MumbaiConfig.ENTRY_POINT_V6;
    }

    function run() public {
        vm.startBroadcast(ownerPrivateKey);
        paymaster = new Paymaster(entryPoint, ownerPublicKey);
        vm.stopBroadcast();
    }
}
