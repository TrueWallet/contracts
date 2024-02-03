// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "forge-std/Script.sol";

import {TrueWallet} from "src/wallet/TrueWallet.sol";
import {TrueWalletFactory} from "src/wallet/TrueWalletFactory.sol";
import {EntryPoint} from "test/mocks/protocol/EntryPoint.sol";
import {MumbaiConfig} from "../config/MumbaiConfig.sol";
import {SecurityControlModule} from "src/modules/SecurityControlModule/SecurityControlModule.sol";

contract CreateWalletProxyScript is Script {
    TrueWallet public wallet;
    address public factory;
    address public entryPoint;
    address public ownerPublicKey;
    uint256 public ownerPrivateKey;
    bytes32 salt;

    address public securityModule;
    bytes[] modules = new bytes[](1);

    function setUp() public {
        ownerPublicKey = vm.envAddress("OWNER");
        ownerPrivateKey = vm.envUint("PRIVATE_KEY_TESTNET");
        entryPoint = MumbaiConfig.ENTRY_POINT_V6;
        factory = MumbaiConfig.FACTORY_1;
        securityModule = MumbaiConfig.SECURITY_CONTROL_MODULE_1;

        salt = keccak256(abi.encodePacked(address(factory), address(entryPoint), uint256(0)));
        bytes memory initData = abi.encode(uint32(1));
        modules[0] = abi.encodePacked(securityModule, initData);
    }

    function run() public {
        vm.startBroadcast(ownerPrivateKey);
        // abi.encodeWithSignature("initialize(address,address,bytes[])", address(entryPoint), ownerPublicKey, modules);
        bytes memory initializer = TrueWalletFactory(factory).getInitializer(address(entryPoint), ownerPublicKey, modules);
        wallet = TrueWalletFactory(factory).createWallet(initializer, salt);
        vm.stopBroadcast();
    }
}
