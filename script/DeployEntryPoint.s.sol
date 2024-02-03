// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "forge-std/Script.sol";

import {EntryPoint} from "test/mocks/protocol/EntryPoint.sol";

contract DeployEntryPointScript is Script {
    EntryPoint public entryPoint;

    address public ownerPublicKey;
    uint256 public ownerPrivateKey;

    function setUp() public {
        ownerPublicKey = vm.envAddress("OWNER");
        ownerPrivateKey = vm.envUint("PRIVATE_KEY_TESTNET");
    }

    function run() public {
        vm.startBroadcast(ownerPrivateKey);
        entryPoint = new EntryPoint();
        vm.stopBroadcast();
    }
}
