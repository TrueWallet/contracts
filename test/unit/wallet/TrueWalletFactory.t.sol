// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import {TrueWallet} from "src/wallet/TrueWallet.sol";
import {TrueWalletProxy} from "src/wallet/TrueWalletProxy.sol";
import {TrueWalletFactory} from "src/wallet/TrueWalletFactory.sol";
import {EntryPoint} from "src/entrypoint/EntryPoint.sol";
import {TrueWallet} from "src/wallet/TrueWallet.sol";
import {MockModule} from "../../mocks/MockModule.sol";

contract TrueWalletFactoryUnitTest is Test {
    TrueWalletFactory factory;
    TrueWallet wallet;
    EntryPoint entryPoint;
    address walletOwner = address(12);
    bytes32 salt;
    uint32 upgradeDelay = 172800; // 2 days in seconds

    MockModule mockModule;
    bytes[] modules = new bytes[](1);

    event AccountInitialized(
        address indexed account,
        address indexed entryPoint,
        address owner,
        uint32 upgradeDelay
    );

    function setUp() public {
        wallet = new TrueWallet();
        factory = new TrueWalletFactory(address(wallet), address(this));
        entryPoint = new EntryPoint();

        mockModule = new MockModule();
        bytes memory initData = abi.encode(uint32(1));
        modules[0] = abi.encodePacked(mockModule, initData);

        salt = keccak256(
            abi.encodePacked(
                address(factory),
                address(entryPoint),
                upgradeDelay
            )
        );
    }

    // Estimating gas for deployment
    function testDeployWallet() public {
        factory.createWallet(
            address(entryPoint),
            walletOwner,
            upgradeDelay,
            modules,
            salt
        );
    }

    function testCreateWallet() public {
        address computedWalletAddress = factory.getWalletAddress(
            address(entryPoint),
            walletOwner,
            upgradeDelay,
            modules,
            salt
        );

        vm.expectEmit(true, true, true, true);
        emit AccountInitialized(
            computedWalletAddress,
            address(entryPoint),
            address(walletOwner),
            upgradeDelay
        );
        TrueWallet proxyWallet = factory.createWallet(
            address(entryPoint),
            walletOwner,
            upgradeDelay,
            modules,
            salt
        );

        assertEq(address(proxyWallet), computedWalletAddress);
        assertEq(address(proxyWallet.entryPoint()), address(entryPoint));
        assertEq(proxyWallet.owner(), walletOwner);
        // assertEq(proxyWallet.upgradeDelay(), upgradeDelay);
    }

    function testCreateWalletInCaseAlreadyDeployed() public {
        address walletAddress = factory.getWalletAddress(
            address(entryPoint),
            walletOwner,
            upgradeDelay,
            modules,
            salt
        );
        // Determine if a wallet is already deployed at this address
        uint256 codeSize = walletAddress.code.length;
        assertTrue(codeSize == 0);

        wallet = factory.createWallet(
            address(entryPoint),
            walletOwner,
            upgradeDelay,
            modules,
            salt
        );

        walletAddress = factory.getWalletAddress(
            address(entryPoint),
            walletOwner,
            upgradeDelay,
            modules,
            salt
        );
        // Determine if a wallet is already deployed at this address
        codeSize = walletAddress.code.length;
        assertTrue(codeSize > 0);
        // Return the address even if the account is already deployed
        TrueWallet wallet2 = factory.createWallet(
            address(entryPoint),
            walletOwner,
            upgradeDelay,
            modules,
            salt
        );

        assertEq(address(wallet), address(wallet2));
    }

    function testCreateWalletWhenNotPaused() public {
        assertEq(factory.paused(), false);
        wallet = factory.createWallet(
            address(entryPoint),
            walletOwner,
            upgradeDelay,
            modules,
            salt
        );
        assertEq(wallet.owner(), walletOwner);

        factory.pause();
        assertEq(factory.paused(), true);
        vm.expectRevert();
        factory.createWallet(
            address(entryPoint),
            walletOwner,
            upgradeDelay,
            modules,
            salt
        );
    }
}