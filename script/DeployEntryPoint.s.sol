// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "forge-std/Script.sol";

import {EntryPoint} from "test/mocks/protocol/EntryPoint.sol";

contract DeployEntryPointScript is Script {
    EntryPoint public entryPoint;

    address public owner;
    uint256 public deployerPrivateKey;

    function setUp() public {
        owner = vm.envAddress("OWNER");
        deployerPrivateKey = vm.envUint("PRIVATE_KEY_TESTNET");
    }

    function run() public {
        vm.startBroadcast(deployerPrivateKey);
        entryPoint = new EntryPoint();
        vm.stopBroadcast();
    }
}
