// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "forge-std/Test.sol";

import {TrueWallet} from "src/TrueWallet.sol";
import {UserOperation} from "src/UserOperation.sol";
import {MockSetter} from "./mock/MockSetter.sol";

contract TrueWalletTest is Test {
    TrueWallet wallet;
    MockSetter setter;
    address entryPoint = address(11);
    address ownerAddress = 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720; // envil account (9)
    uint256 ownerPrivateKey =uint256(0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6);

    function setUp() public {
        wallet = new TrueWallet(entryPoint, ownerAddress);
        setter = new MockSetter();
    }

    function testSetupState() public {
        assertEq(wallet.owner(), address(ownerAddress));
        assertEq(wallet.entryPoint(), address(11));
    }

    function testUpdateEntryPoint() public {
        assertEq(wallet.entryPoint(), address(entryPoint));
        address newEntryPoint = address(12);
        vm.prank(address(ownerAddress));
        wallet.setEntryPoint(newEntryPoint);
        assertEq(wallet.entryPoint(), address(newEntryPoint));
    }

    function testUpdateEntryPointNotOwner() public {
        address newEntryPoint = address(12);
        address notOwner = address(13);
        vm.prank(address(notOwner));
        vm.expectRevert();
        wallet.setEntryPoint(newEntryPoint);
        assertEq(wallet.entryPoint(), address(entryPoint));
    }

    function testValidateUserOp() public {
        assertEq(wallet.nonce(), 0);
        bytes memory payload = abi.encodeWithSignature("setValue(uint256)", 1);

        UserOperation memory userOp = UserOperation({
            sender: address(wallet),
            nonce: wallet.nonce(),
            initCode: "",
            callData: payload,
            callGasLimit: 1e6,
            verificationGasLimit: 1e6,
            preVerificationGas: 1e6,
            maxFeePerGas: 1e6,
            maxPriorityFeePerGas: 1e6,
            paymasterAndData: "",
            signature: ""
        });

        address aggregator = address(12);
        uint256 missingWalletFunds = 5e6;

        vm.prank(address(entryPoint));
        uint256 deadline = wallet.validateUserOp(
            userOp,
            keccak256(payload),
            aggregator,
            missingWalletFunds
        );
        assertEq(deadline, 0);
        assertEq(wallet.nonce(), 1);
    }

    function testExecuteByEntryPoint() public {
        assertEq(setter.value(), 0);

        bytes memory payload = abi.encodeWithSelector(setter.setValue.selector, 1);

        vm.prank(address(entryPoint));
        wallet.execute(address(setter), 0, payload);

        assertEq(setter.value(), 1);
    }

    function testExecuteByOwner() public {
        assertEq(setter.value(), 0);

        bytes memory payload = abi.encodeWithSelector(setter.setValue.selector, 1);

        vm.prank(address(ownerAddress));
        wallet.execute(address(setter), 0, payload);

        assertEq(setter.value(), 1);
    }

    function testExecuteNotEntryPoint() public {
        assertEq(setter.value(), 0);

        bytes memory payload = abi.encodeWithSelector(setter.setValue.selector, 1);

        address notEntryPoint = address(13);
        vm.prank(address(notEntryPoint));
        vm.expectRevert();
        wallet.execute(address(setter), 0, payload);

        assertEq(setter.value(), 0);
    }

    function testExecuteBatchByEntryPoint() public {
        assertEq(setter.value(), 0);

        address[] memory target = new address[](2);
        target[0] = address(setter);
        target[1] = address(setter);
        bytes[] memory payloads = new bytes[](2);
        payloads[0] = abi.encodeWithSelector(setter.setValue.selector, 1);
        payloads[1] = abi.encodeWithSelector(setter.setValue.selector, 2);

        vm.prank(address(entryPoint));
        wallet.executeBatch(target, payloads);

        assertEq(setter.value(), 2);
    }

    function testExecuteBatchByOwner() public {
        assertEq(setter.value(), 0);

        address[] memory target = new address[](2);
        target[0] = address(setter);
        target[1] = address(setter);
        bytes[] memory payloads = new bytes[](2);
        payloads[0] = abi.encodeWithSelector(setter.setValue.selector, 1);
        payloads[1] = abi.encodeWithSelector(setter.setValue.selector, 2);

        vm.prank(address(ownerAddress));
        wallet.executeBatch(target, payloads);

        assertEq(setter.value(), 2);
    }

    function testExecuteBatchNotEntryPoint() public {
        assertEq(setter.value(), 0);

        address[] memory target = new address[](2);
        target[0] = address(setter);
        target[1] = address(setter);
        bytes[] memory payloads = new bytes[](2);
        payloads[0] = abi.encodeWithSelector(setter.setValue.selector, 1);
        payloads[1] = abi.encodeWithSelector(setter.setValue.selector, 2);

        address notEntryPoint = address(13);
        vm.prank(address(notEntryPoint));
        vm.expectRevert();
        wallet.executeBatch(target, payloads);

        assertEq(setter.value(), 0);
    }
}