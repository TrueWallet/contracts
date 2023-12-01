// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import {TrueWallet} from "src/wallet/TrueWallet.sol";
import {TrueWalletProxy} from "src/wallet/TrueWalletProxy.sol";
import {TrueWalletFactory, WalletErrors} from "src/wallet/TrueWalletFactory.sol";
import {EntryPoint, IEntryPoint} from "test/mocks/protocol/EntryPoint.sol";
import {TrueWallet} from "src/wallet/TrueWallet.sol";
import {MockModule} from "../../mocks/MockModule.sol";

contract TrueWalletFactoryUnitTest is Test {
    TrueWalletFactory factory;
    TrueWallet wallet;
    EntryPoint entryPoint;
    address walletOwner = address(12);
    bytes32 salt;

    MockModule mockModule;
    bytes[] modules = new bytes[](1);

    address user;

    event AccountInitialized(address indexed account, address indexed entryPoint, address owner);

    event TrueWalletCreation(TrueWallet wallet);

    function setUp() public {
        wallet = new TrueWallet();
        entryPoint = new EntryPoint();
        factory = new TrueWalletFactory(address(wallet), address(this), address(entryPoint));

        mockModule = new MockModule();
        bytes memory initData = abi.encode(uint32(1));
        modules[0] = abi.encodePacked(mockModule, initData);

        salt = keccak256(abi.encodePacked(address(factory), address(entryPoint)));

        user = makeAddr("user");
    }

    function testSetupState() public {
        assertEq(factory.entryPoint(), address(entryPoint));
        assertEq(factory.walletImplementation(), address(wallet));
        assertEq(factory.owner(), address(this));
        assertEq(entryPoint.balanceOf(address(factory)), 0);
        assertFalse(factory.paused());
    }

    function testRevertsDeployFactory() public {
        vm.expectRevert(WalletErrors.ZeroAddressProvided.selector);
        factory = new TrueWalletFactory(address(0), address(this), address(entryPoint));

        vm.expectRevert(WalletErrors.ZeroAddressProvided.selector);
        factory = new TrueWalletFactory(address(wallet), address(0), address(entryPoint));

        vm.expectRevert(WalletErrors.ZeroAddressProvided.selector);
        factory = new TrueWalletFactory(address(wallet), address(this), address(0));

        vm.expectRevert(WalletErrors.ZeroAddressProvided.selector);
        factory = new TrueWalletFactory(address(0), address(0), address(0));
    }

    // Estimating gas for deployment
    function testDeployWallet() public {
        factory.createWallet(address(entryPoint), walletOwner, modules, salt);
    }

    function testCreateWallet() public {
        address computedWalletAddress = factory.getWalletAddress(address(entryPoint), walletOwner, modules, salt);

        // vm.expectEmit(true, true, true, true);
        // emit AccountInitialized(
        //     computedWalletAddress,
        //     address(entryPoint),
        //     address(walletOwner)
        // );
        // emit TrueWalletCreation(TrueWallet(payable(computedWalletAddress)));
        TrueWallet proxyWallet = factory.createWallet(address(entryPoint), walletOwner, modules, salt);

        assertEq(address(proxyWallet), computedWalletAddress);
        assertEq(address(proxyWallet.entryPoint()), address(entryPoint));
        assertTrue(proxyWallet.isOwner(walletOwner));
    }
    /*
    function testCreateWalletInCaseAlreadyDeployed() public {
        address walletAddress = factory.getWalletAddress(
            address(entryPoint),
            walletOwner,
            modules,
            salt
        );
        // Determine if a wallet is already deployed at this address
        uint256 codeSize = walletAddress.code.length;
        assertTrue(codeSize == 0);

        wallet = factory.createWallet(
            address(entryPoint),
            walletOwner,
            modules,
            salt
        );

        walletAddress = factory.getWalletAddress(
            address(entryPoint),
            walletOwner,
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
            modules,
            salt
        );
        assertTrue(wallet.isOwner(walletOwner));

        factory.pause();
        assertEq(factory.paused(), true);
        vm.expectRevert();
        factory.createWallet(
            address(entryPoint),
            walletOwner,
            modules,
            salt
        );
    }
    */

    function testDeposit() public {
        assertEq(address(entryPoint).balance, 0);
        assertEq(entryPoint.balanceOf(address(factory)), 0);

        vm.prank(address(this));
        factory.deposit{value: 0.5 ether}();

        assertEq(address(entryPoint).balance, 0.5 ether);
        assertEq(entryPoint.balanceOf(address(factory)), 0.5 ether);
    }

    function testWithdrawTo() public {
        testDeposit();

        assertEq(entryPoint.balanceOf(address(factory)), 0.5 ether);
        assertEq(address(user).balance, 0);

        vm.prank(address(this));
        factory.withdrawTo(payable(address(user)), 0.3 ether);

        assertEq(address(user).balance, 0.3 ether);
    }

    function testRevertsWithdrawToWhenNotOwner() public {
        testDeposit();

        assertEq(entryPoint.balanceOf(address(factory)), 0.5 ether);
        assertEq(address(user).balance, 0);

        vm.prank(address(user));
        vm.expectRevert();
        factory.withdrawTo(payable(address(user)), 0.3 ether);

        assertEq(entryPoint.balanceOf(address(factory)), 0.5 ether);
    }

    function testAddStake() public {
        assertFalse(entryPoint.getDepositInfo(address(factory)).staked);

        vm.prank(address(this));
        factory.addStake{value: 0.5 ether}(172800);

        assertTrue(entryPoint.getDepositInfo(address(factory)).staked);
        assertEq(entryPoint.getDepositInfo(address(factory)).stake, uint112(0.5 ether));
        assertEq(entryPoint.getDepositInfo(address(factory)).unstakeDelaySec, uint32(172800));
    }

    function testRevertsAddStakeIfNotOwner() public {
        assertFalse(entryPoint.getDepositInfo(address(factory)).staked);

        vm.prank(address(user));
        vm.expectRevert();
        factory.addStake{value: 0.5 ether}(172800);

        assertFalse(entryPoint.getDepositInfo(address(factory)).staked);
    }

    function testUnlockStake() public {
        testAddStake();
        assertTrue(entryPoint.getDepositInfo(address(factory)).staked);

        vm.prank(address(this));
        factory.unlockStake();
        assertFalse(entryPoint.getDepositInfo(address(factory)).staked);
    }

    function testRevertsUnlockStakeIfNotOwner() public {
        testAddStake();
        assertTrue(entryPoint.getDepositInfo(address(factory)).staked);

        vm.prank(address(user));
        vm.expectRevert();
        factory.unlockStake();
        assertTrue(entryPoint.getDepositInfo(address(factory)).staked);
    }

    function testWithdrawStake() public {
        assertEq(address(user).balance, 0);
        testUnlockStake();

        uint256 unstakeDelay = block.timestamp + 172800;
        vm.warp(unstakeDelay + 172800);
        vm.prank(address(this));
        factory.withdrawStake(payable(address(user)));

        assertEq(address(user).balance, 0.5 ether);
    }

    function testRevertsWithdrawStakeIfNotOwner() public {
        assertEq(address(user).balance, 0);
        testUnlockStake();

        uint256 unstakeDelay = block.timestamp + 172800;
        vm.warp(unstakeDelay + 172800);
        vm.prank(address(user));
        vm.expectRevert();
        factory.withdrawStake(payable(address(user)));

        assertEq(address(user).balance, 0);
    }
}
