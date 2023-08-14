// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "forge-std/Script.sol";

import {TrueWallet} from "src/wallet/TrueWallet.sol";
import {TrueWalletFactory} from "src/wallet/TrueWalletFactory.sol";
import {EntryPoint} from "src/entrypoint/EntryPoint.sol";
import {MumbaiConfig} from "../config/MumbaiConfig.sol";

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

    function setUp() public {
        owner = vm.envAddress("OWNER");
        deployerPrivateKey = vm.envUint("PRIVATE_KEY_TESTNET");
        factory = TrueWalletFactory(MumbaiConfig.FACTORY);
        entryPoint = MumbaiConfig.ENTRY_POINT;
    }

    function run() public {
        vm.startBroadcast(deployerPrivateKey);
        wallet = factory.createWallet(
            address(entryPoint),
            owner,
            upgradeDelay,
            salt
        );
        vm.stopBroadcast();
    }
}
