// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "forge-std/Test.sol";

import {TrueWallet} from "src/TrueWallet.sol";
import {UserOperation} from "src/UserOperation.sol";
import {MockSetter} from "./mock/MockSetter.sol";
import {MockERC20} from "./mock/MockERC20.sol";
import {ECDSA} from "openzeppelin-contracts/utils/cryptography/ECDSA.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

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
        assertEq(address(wallet.entryPoint()), address(11));
    }

    function testUpdateEntryPoint() public {
        assertEq(address(wallet.entryPoint()), address(entryPoint));
        address newEntryPoint = address(12);
        vm.prank(address(ownerAddress));
        wallet.setEntryPoint(newEntryPoint);
        assertEq(address(wallet.entryPoint()), address(newEntryPoint));
    }

    function testUpdateEntryPointNotOwner() public {
        address newEntryPoint = address(12);
        address notOwner = address(13);
        vm.prank(address(notOwner));
        vm.expectRevert();
        wallet.setEntryPoint(newEntryPoint);
        assertEq(address(wallet.entryPoint()), address(entryPoint));
    }

    function testValidateUserOp() public {
        assertEq(wallet.nonce(), 0);

        (UserOperation memory userOp, bytes32 digest) = getUserOperation(
            address(wallet), wallet.nonce(), abi.encodeWithSignature("setValue(uint256)", 1), ownerPrivateKey, vm);

        address aggregator = address(12);
        uint256 missingWalletFunds = 0;

        vm.prank(address(entryPoint));
        uint256 deadline = wallet.validateUserOp(
            userOp,
            digest,
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

    function testPrefundEntryPoint() public {
        vm.deal(address(wallet), 1 ether);

        assertEq(wallet.nonce(), 0);

        uint256 balanceBefore = address(entryPoint).balance;

        (UserOperation memory userOp, bytes32 digest) = getUserOperation(
            address(wallet), wallet.nonce(), abi.encodeWithSignature("setValue(uint256)", 1), ownerPrivateKey, vm);

        address aggregator = address(12);
        uint256 missingWalletFunds = 0.001 ether;

        vm.prank(address(entryPoint));
        uint256 deadline = wallet.validateUserOp(
            userOp,
            digest,
            aggregator,
            missingWalletFunds
        );
        assertEq(deadline, 0);
        assertEq(wallet.nonce(), 1);

        assertEq(address(entryPoint).balance, balanceBefore + missingWalletFunds);
    }

    function testWithdrawERC20() public {
        MockERC20 token = new MockERC20();
        token.mint(address(wallet), 1 ether);

        assertEq(token.balanceOf(address(entryPoint)), 0);

        vm.prank(address(ownerAddress));
        wallet.withdrawERC20(address(token), address(entryPoint), 1 ether);

        assertEq(token.balanceOf(address(entryPoint)), 1 ether);
    }

    function testWithdrawERC20NotOwner() public {
        MockERC20 token = new MockERC20();
        token.mint(address(wallet), 1 ether);

        assertEq(token.balanceOf(address(entryPoint)), 0);

        address notOwner = address(13);
        vm.prank(address(notOwner));
        vm.expectRevert();
        wallet.withdrawERC20(address(token), address(entryPoint), 1 ether);

        assertEq(token.balanceOf(address(entryPoint)), 0 ether);
    }

    function testWithdrawETH() public {
        vm.deal(address(wallet), 1 ether);

        assertEq(address(entryPoint).balance, 0);

        vm.prank(address(ownerAddress));
        wallet.withdrawETH(address(entryPoint), 1 ether);

        assertEq(address(entryPoint).balance, 1 ether);
    }

    function testWithdrawETHNotOwner() public {
        vm.deal(address(wallet), 1 ether);

        assertEq(address(entryPoint).balance, 0);

        address notOwner = address(13);
        vm.prank(address(notOwner));
        vm.expectRevert();
        wallet.withdrawETH(address(entryPoint), 1 ether);

        assertEq(address(entryPoint).balance, 0 ether);
    }

    function getUserOperation(address sender, uint256 nonce, bytes memory callData, uint256 ownerPrivateKey, Vm vm)
        public
        returns (UserOperation memory, bytes32)
    {
        // Signature is generated over the userOperation, entryPoint and chainId
        bytes memory message = abi.encode(
            sender,
            nonce,
            "",     // initCode
            callData,
            1e6,    // callGasLimit
            1e6,    // verificationGasLimit
            1e6,    // preVerificationGas
            1e6,    // maxFeePerGas,
            1e6,    // maxPriorityFeePerGas,
            "",     // paymasterAndData,
            address(entryPoint), // entryPoint
            0x1     // chainId
        );
    
        bytes32 digest = ECDSA.toEthSignedMessageHash(message);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);
        bytes memory signature = bytes.concat(r, s, bytes1(v));

        UserOperation memory userOp = UserOperation({
            sender: sender,
            nonce: nonce,
            initCode: "",
            callData: callData,
            callGasLimit: 1e6,
            verificationGasLimit: 1e6,
            preVerificationGas: 1e6,
            maxFeePerGas: 1e6,
            maxPriorityFeePerGas: 1e6,
            paymasterAndData: "",
            signature: signature
        });

        return (userOp, digest);
    }
}