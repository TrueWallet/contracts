// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "forge-std/Script.sol";

import {TrueWallet} from "src/wallet/TrueWallet.sol";
import {TrueWalletFactory} from "src/wallet/TrueWalletFactory.sol";
import {EntryPoint} from "src/entrypoint/EntryPoint.sol";
import {MumbaiConfig} from "../config/MumbaiConfig.sol";

import {MockModule} from "test/mock/MockModule.sol";

contract DeployWalletProxyScript is Script {
    TrueWalletFactory public factory;
    TrueWallet public wallet;
    address public entryPoint;
    address public owner;
    uint256 public deployerPrivateKey;
    bytes32 salt =
        keccak256(
            abi.encodePacked(
                address(factory),
                address(entryPoint),
                upgradeDelay,
                block.timestamp
            )
        );
    uint32 upgradeDelay = 172800;

    MockModule mockModule;
    bytes[] modules = new bytes[](1);

    function setUp() public {
        owner = vm.envAddress("OWNER");
        deployerPrivateKey = vm.envUint("PRIVATE_KEY_TESTNET");
        factory = TrueWalletFactory(MumbaiConfig.FACTORY);
        entryPoint = MumbaiConfig.ENTRY_POINT;

        // mock
        bytes memory initData = abi.encode(uint32(1));
        mockModule = new MockModule();
        modules[0] = abi.encodePacked(mockModule, initData);
    }

    function run() public {
        vm.startBroadcast(deployerPrivateKey);
        wallet = factory.createWallet(
            address(entryPoint),
            owner,
            upgradeDelay,
            modules,
            salt
        );
        vm.stopBroadcast();
    }
}
