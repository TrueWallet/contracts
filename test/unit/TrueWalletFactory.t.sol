// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "forge-std/Test.sol";

import {TrueWallet} from "src/TrueWallet.sol";
import {TrueWalletFactory} from "src/TrueWalletFactory.sol";
import {EntryPoint} from "src/entrypoint/EntryPoint.sol";

contract TrueWalletFactoryTest is Test {
    TrueWalletFactory factory;
    EntryPoint entryPoint;
    address walletOwner = address(12);
    bytes32 salt;

    function setUp() public {
        factory = new TrueWalletFactory(address(this));
        entryPoint = new EntryPoint();

        salt = keccak256(
            abi.encodePacked(address(factory), address(entryPoint))
        );
    }

    function testDeployWallet() public {
        TrueWallet wallet = factory.deployWallet(
            address(entryPoint),
            walletOwner,
            salt
        );

        address computedWalletAddress = factory.computeAddress(
            address(entryPoint),
            walletOwner,
            salt
        );
        assertEq(address(wallet), computedWalletAddress);
        assertEq(address(wallet.entryPoint()), address(entryPoint));
        assertEq(wallet.owner(), walletOwner);
    }

    function testDeployWalletInCaseAlreadyDeployed() public {
        address walletAddress = factory.computeAddress(
            address(entryPoint),
            walletOwner,
            salt
        );
        // Determine if a wallet is already deployed at this address
        uint256 codeSize = walletAddress.code.length;
        assertTrue(codeSize == 0);

        TrueWallet wallet = factory.deployWallet(
            address(entryPoint),
            walletOwner,
            salt
        );

        walletAddress = factory.computeAddress(
            address(entryPoint),
            walletOwner,
            salt
        );
        // Determine if a wallet is already deployed at this address
        codeSize = walletAddress.code.length;
        assertTrue(codeSize > 0);
        // Return the address even if the account is already deployed
        TrueWallet wallet2 = factory.deployWallet(
            address(entryPoint),
            walletOwner,
            salt
        );

        assertEq(address(wallet), address(wallet2));
    }

    function testDeployWalletWhenNotPaused() public {
        assertEq(factory.paused(), false);
        TrueWallet wallet = factory.deployWallet(
            address(entryPoint),
            walletOwner,
            salt
        );
        assertEq(wallet.owner(), walletOwner);

        factory.pause();
        assertEq(factory.paused(), true);
        vm.expectRevert();
        TrueWallet wallet2 = factory.deployWallet(
            address(entryPoint),
            walletOwner,
            salt
        );
    }
}