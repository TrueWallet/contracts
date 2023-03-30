// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "forge-std/Test.sol";

import {Paymaster} from "src/paymaster/Paymaster.sol";
import {TrueWallet} from "src/wallet/TrueWallet.sol";
import {UserOperation} from "src/interfaces/UserOperation.sol";
import {EntryPoint} from "src/entrypoint/EntryPoint.sol";
import {IPaymaster} from "src/interfaces/IPaymaster.sol";
import {IEntryPoint} from "src/interfaces/IEntryPoint.sol";

contract PaymasterUnitTest is Test {
    TrueWallet wallet;
    Paymaster paymaster;
    EntryPoint entryPoint;
    address ownerAddress = 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720; // envil account (9)
    uint256 ownerPrivateKey =
        uint256(
            0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6
        );
    EntryPoint newEntryPoint;
    address user = address(12);
    address notOwner = address(13);

    function setUp() public {
        entryPoint = new EntryPoint();
        wallet = new TrueWallet(address(entryPoint), ownerAddress);
        paymaster = new Paymaster(address(entryPoint), ownerAddress);
    }

    function testSetupState() public {
        assertEq(wallet.owner(), address(ownerAddress));
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
