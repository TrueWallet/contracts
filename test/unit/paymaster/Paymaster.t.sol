// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import {IEntryPoint, UserOperation} from "account-abstraction/interfaces/IEntryPoint.sol";
import {TrueWalletFactory, WalletErrors} from "src/wallet/TrueWalletFactory.sol";
import {Paymaster} from "src/paymaster/Paymaster.sol";
import {TrueWallet} from "src/wallet/TrueWallet.sol";
import {TrueWalletProxy} from "src/wallet/TrueWalletProxy.sol";
import {EntryPoint} from "test/mocks/protocol/EntryPoint.sol";
import {IPaymaster} from "src/interfaces/IPaymaster.sol";
import {MockModule} from "../../mocks/MockModule.sol";

contract PaymasterUnitTest is Test {
    TrueWalletFactory factory;
    TrueWallet wallet;
    TrueWallet walletImpl;
    TrueWalletProxy proxy;
    Paymaster paymaster;
    EntryPoint entryPoint;
    address ownerAddress = 0x14dC79964da2C08b23698B3D3cc7Ca32193d9955; // anvil account (7)
    uint256 ownerPrivateKey = uint256(0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356);
    EntryPoint newEntryPoint;
    address user = address(12);
    address notOwner = address(13);

    MockModule mockModule;
    bytes[] modules = new bytes[](1);
    bytes32 salt;

    function setUp() public {
        entryPoint = new EntryPoint();
        walletImpl = new TrueWallet();
        paymaster = new Paymaster(address(entryPoint), ownerAddress);

        mockModule = new MockModule();
        bytes memory initData = abi.encode(uint32(1));
        modules[0] = abi.encodePacked(mockModule, initData);
        salt = keccak256(abi.encodePacked(address(factory), address(entryPoint)));

        factory = new TrueWalletFactory(address(walletImpl), address(ownerAddress), address(entryPoint));
        bytes memory initializer = abi.encodeWithSignature("initialize(address,address,bytes[])", address(entryPoint), ownerAddress, modules);
        wallet = factory.createWallet(initializer, salt);
    }

    function testSetupState() public {
        assertTrue(wallet.isOwner(ownerAddress));
        assertEq(address(wallet.entryPoint()), address(entryPoint));

        assertEq(paymaster.owner(), address(ownerAddress));
        assertEq(address(paymaster.entryPoint()), address(entryPoint));
    }

    function testUpdateEntryPoint() public {
        assertEq(address(paymaster.entryPoint()), address(entryPoint));
        newEntryPoint = new EntryPoint();
        vm.prank(address(ownerAddress));
        paymaster.setEntryPoint(address(newEntryPoint));
        assertEq(address(paymaster.entryPoint()), address(newEntryPoint));
    }

    function testUpdateEntryPointNotOwner() public {
        newEntryPoint = new EntryPoint();
        vm.prank(address(notOwner));
        vm.expectRevert();
        paymaster.setEntryPoint(address(newEntryPoint));
        assertEq(address(paymaster.entryPoint()), address(entryPoint));
    }

    function testDeposit() public {
        assertEq(address(entryPoint).balance, 0);
        assertEq(paymaster.getDeposit(), 0);

        hoax(address(ownerAddress), 1 ether);
        paymaster.deposit{value: 0.5 ether}();

        assertEq(address(entryPoint).balance, 0.5 ether);
        assertEq(paymaster.getDeposit(), 0.5 ether);
    }

    function testWithdraw() public {
        testDeposit();

        assertEq(address(entryPoint).balance, 0.5 ether);
        assertEq(address(user).balance, 0);

        vm.prank(address(ownerAddress));
        paymaster.withdraw(payable(address(user)), 0.3 ether);

        assertEq(address(user).balance, 0.3 ether);
    }

    function testWithdrawNotOwner() public {
        testDeposit();

        assertEq(address(entryPoint).balance, 0.5 ether);
        assertEq(address(user).balance, 0);

        vm.prank(address(notOwner));
        vm.expectRevert();
        paymaster.withdraw(payable(address(user)), 0.3 ether);

        assertEq(address(entryPoint).balance, 0.5 ether);
    }

    function testWithdrawAll() public {
        testDeposit();

        assertEq(address(entryPoint).balance, 0.5 ether);
        assertEq(address(user).balance, 0);

        vm.prank(address(ownerAddress));
        paymaster.withdrawAll(payable(address(user)));

        assertEq(address(user).balance, 0.5 ether);
        assertEq(address(entryPoint).balance, 0);
    }

    function testWithdrawAllNotOwner() public {
        testDeposit();

        assertEq(address(entryPoint).balance, 0.5 ether);
        assertEq(address(user).balance, 0);

        vm.prank(address(notOwner));
        vm.expectRevert();
        paymaster.withdrawAll(payable(address(user)));

        assertEq(address(user).balance, 0);
        assertEq(address(entryPoint).balance, 0.5 ether);
    }

    function testAddStake() public {
        assertEq(paymaster.getStake(), 0);

        hoax(address(ownerAddress), 1 ether);
        paymaster.addStake{value: 0.5 ether}(120);

        assertEq(paymaster.getStake(), 0.5 ether);
        assertEq(entryPoint.getDepositInfo(address(paymaster)).staked, true);
    }

    function testAddStakeNotOwner() public {
        assertEq(paymaster.getStake(), 0);

        hoax(address(notOwner), 1 ether);
        vm.expectRevert();
        paymaster.addStake{value: 0.5 ether}(120);

        assertEq(paymaster.getStake(), 0);
    }

    function testUnlockStake() public {
        testAddStake();
        assertEq(entryPoint.getDepositInfo(address(paymaster)).staked, true);
        assertEq(paymaster.getStake(), 0.5 ether);

        vm.prank(address(ownerAddress));
        paymaster.unlockStake();
        assertEq(entryPoint.getDepositInfo(address(paymaster)).staked, false);
    }

    function testUnlockStakeNotOwner() public {
        testAddStake();
        assertEq(paymaster.getStake(), 0.5 ether);

        hoax(address(notOwner), 1 ether);
        vm.expectRevert();
        paymaster.unlockStake();
    }

    function testWithdrawStake() public {
        assertEq(address(user).balance, 0);
        testUnlockStake();

        uint256 unstakeDelay = block.timestamp + 120;
        vm.warp(unstakeDelay + 200);
        vm.prank(address(ownerAddress));
        paymaster.withdrawStake(payable(address(user)));

        assertEq(address(user).balance, 0.5 ether);
    }

    function testWithdrawStakeNotOwner() public {
        assertEq(address(user).balance, 0);

        testUnlockStake();

        uint256 unstakeDelay = block.timestamp + 120;
        vm.warp(unstakeDelay + 200);
        hoax(address(notOwner), 1 ether);
        vm.expectRevert();
        paymaster.withdrawStake(payable(address(user)));

        assertEq(address(user).balance, 0);
    }
}
