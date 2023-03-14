// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "forge-std/Test.sol";

import {TrueWallet} from "src/TrueWallet.sol";

contract TrueWalletTest is Test {
    TrueWallet wallet;

    function setUp() public {
        address entryPoint = address(11);
        wallet = new TrueWallet(entryPoint);
    }

    function testSetupState() public {
        assertEq(wallet.owner(), address(this));
        assertEq(wallet.entryPoint(), address(11));
    }
}