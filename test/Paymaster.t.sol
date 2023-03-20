// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "forge-std/Test.sol";

import {Paymaster} from "src/Paymaster.sol";
import {TrueWallet} from "src/TrueWallet.sol";
import {UserOperation} from "src/UserOperation.sol";
import {IPaymaster} from "src/interfaces/IPaymaster.sol";
import {IEntryPoint} from "src/interfaces/IEntryPoint.sol";

contract PaymasterTest is Test {
    TrueWallet wallet;
    Paymaster paymaster;
    address entryPoint = address(11);
    address ownerAddress = 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720; // envil account (9)
    uint256 ownerPrivateKey =uint256(0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6);

    function setUp() public {
        wallet = new TrueWallet(entryPoint, ownerAddress);
        paymaster = new Paymaster(entryPoint, ownerAddress);
    }

    function testSetupState() public {
        assertEq(wallet.owner(), address(ownerAddress));
        assertEq(address(wallet.entryPoint()), address(11));

        assertEq(paymaster.owner(), address(ownerAddress));
        assertEq(address(paymaster.entryPoint()), address(11));
    }

    function testUpdateEntryPoint() public {
        assertEq(address(paymaster.entryPoint()), address(entryPoint));
        address newEntryPoint = address(12);
        vm.prank(address(ownerAddress));
        paymaster.setEntryPoint(newEntryPoint);
        assertEq(address(paymaster.entryPoint()), address(newEntryPoint));
    }

    function testUpdateEntryPointNotOwner() public {
        address newEntryPoint = address(12);
        address notOwner = address(13);
        vm.prank(address(notOwner));
        vm.expectRevert();
        paymaster.setEntryPoint(newEntryPoint);
        assertEq(address(paymaster.entryPoint()), address(entryPoint));
    }

    // function testDeposit() public {
    //     // entryPoint.depositTo{value: msg.value}(address(this));

    //     assertEq(address(entryPoint).balance, 0);

    //     hoax(address(ownerAddress), 1 ether);
    //     paymaster.deposit{value: 0.5 ether}();
    // }

}