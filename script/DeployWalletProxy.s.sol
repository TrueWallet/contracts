// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "forge-std/Script.sol";

import {TrueWallet} from "src/wallet/TrueWallet.sol";
import {TrueWalletFactory} from "src/wallet/TrueWalletFactory.sol";
import {EntryPoint} from "test/mocks/entrypoint/EntryPoint.sol";
import {MumbaiConfig} from "../config/MumbaiConfig.sol";
import {SecurityControlModule} from "src/modules/SecurityControlModule/SecurityControlModule.sol";

contract DeployWalletProxyScript is Script {
    TrueWalletFactory public factory;
    TrueWallet public wallet;
    address public entryPoint;
    address public owner;
    uint256 public deployerPrivateKey;
    bytes32 salt = keccak256(abi.encodePacked(address(factory), address(entryPoint), block.timestamp));

    address public securityModule;
    bytes[] modules = new bytes[](1);

    function setUp() public {
        owner = vm.envAddress("OWNER");
        deployerPrivateKey = vm.envUint("PRIVATE_KEY_TESTNET");
        factory = TrueWalletFactory(MumbaiConfig.FACTORY);
        entryPoint = MumbaiConfig.ENTRY_POINT;
        securityModule = MumbaiConfig.SECURITY_CONTROL_MODULE;

        // mock
        bytes memory initData = abi.encode(uint32(1));
        modules[0] = abi.encodePacked(securityModule, initData);
    }

    function run() public {
        vm.startBroadcast(deployerPrivateKey);
        wallet = factory.createWallet(address(entryPoint), owner, modules, salt);
        vm.stopBroadcast();
    }
}
