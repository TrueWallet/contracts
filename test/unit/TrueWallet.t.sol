// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "forge-std/Test.sol";

import {TrueWallet} from "src/TrueWallet.sol";
import {UserOperation} from "src/interfaces/UserOperation.sol";
import {EntryPoint} from "src/entrypoint/EntryPoint.sol";
import {MockSetter} from "../mock/MockSetter.sol";
import {MockERC20} from "../mock/MockERC20.sol";
import {ECDSA} from "openzeppelin-contracts/utils/cryptography/ECDSA.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {getUserOperation} from "./Fixtures.sol";

contract TrueWalletUnitTest is Test {
    TrueWallet wallet;
    MockSetter setter;
    EntryPoint entryPoint;
    address ownerAddress = 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720; // envil account (9)
    uint256 ownerPrivateKey =
        uint256(
            0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6
        );
    uint256 chainId = block.chainid;

    function setUp() public {
        entryPoint = new EntryPoint();
        wallet = new TrueWallet(address(entryPoint), ownerAddress);
        setter = new MockSetter();

        vm.deal(address(wallet), 5 ether);
    }

    function testSetupState() public {
        assertEq(wallet.owner(), address(ownerAddress));
        assertEq(address(wallet.entryPoint()), address(entryPoint));
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

        (UserOperation memory userOp, bytes32 userOpHash) = getUserOperation(
            address(wallet),
            wallet.nonce(),
            abi.encodeWithSignature("setValue(uint256)", 1),
            address(entryPoint),
            uint8(chainId),
            ownerPrivateKey,
            vm
        );

        address aggregator = address(12);
        uint256 missingWalletFunds = 0;

        vm.prank(address(entryPoint));
        uint256 deadline = wallet.validateUserOp(
            userOp,
            userOpHash,
            aggregator,
            missingWalletFunds
        );
        assertEq(deadline, 0);
        assertEq(wallet.nonce(), 1);
    }

    function testExecuteByEntryPoint() public {
        assertEq(setter.value(), 0);

        bytes memory payload = abi.encodeWithSelector(
            setter.setValue.selector,
            1
        );

        vm.prank(address(entryPoint));
        wallet.execute(address(setter), 0, payload);

        assertEq(setter.value(), 1);
    }

    function testExecuteByOwner() public {
        assertEq(setter.value(), 0);

        bytes memory payload = abi.encodeWithSelector(
            setter.setValue.selector,
            1
        );

        vm.prank(address(ownerAddress));
        wallet.execute(address(setter), 0, payload);

        assertEq(setter.value(), 1);
    }

    function testExecuteNotEntryPoint() public {
        assertEq(setter.value(), 0);

        bytes memory payload = abi.encodeWithSelector(
            setter.setValue.selector,
            1
        );

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
            address(wallet),
            wallet.nonce(),
            abi.encodeWithSignature("setValue(uint256)", 1),
            address(entryPoint),
            uint8(chainId),
            ownerPrivateKey,
            vm
        );

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

        assertEq(
            address(entryPoint).balance,
            balanceBefore + missingWalletFunds
        );
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
        wallet.withdrawETH(payable(address(entryPoint)), 1 ether);

        assertEq(address(entryPoint).balance, 1 ether);
    }

    function testWithdrawETHNotOwner() public {
        vm.deal(address(wallet), 1 ether);

        assertEq(address(entryPoint).balance, 0);

        address notOwner = address(13);
        vm.prank(address(notOwner));
        vm.expectRevert();
        wallet.withdrawETH(payable(address(entryPoint)), 1 ether);

        assertEq(address(entryPoint).balance, 0 ether);
    }
}