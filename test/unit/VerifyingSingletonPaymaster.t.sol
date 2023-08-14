// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import {Paymaster} from "src/paymaster/Paymaster.sol";
import {TrueWallet} from "src/wallet/TrueWallet.sol";
import {TrueWalletProxy} from "src/wallet/TrueWalletProxy.sol";
import {UserOperation} from "src/interfaces/UserOperation.sol";
import {EntryPoint} from "src/entrypoint/EntryPoint.sol";
import {IPaymaster} from "src/interfaces/IPaymaster.sol";
import {IEntryPoint} from "src/interfaces/IEntryPoint.sol";
import {VerifyingPaymaster} from "src/paymaster/VerifyingPaymaster.sol";
import {VerifyingSingletonPaymaster} from "src/paymaster/VerifyingSingletonPaymaster.sol";
import {createSignature, createSignature2} from "test/utils/createSignature.sol";
import "src/helper/Helpers.sol";

import {TrueWalletFactory} from "src/wallet/TrueWalletFactory.sol";

import "lib/forge-std/src/console.sol";

contract VerifyingSingletonPaymasterUnitTest is Test {
    TrueWallet wallet;
    TrueWallet walletImpl;
    VerifyingSingletonPaymaster paymaster;
    EntryPoint entryPoint;
    address ownerAddress = 0x14dC79964da2C08b23698B3D3cc7Ca32193d9955; // anvil account (7)
    uint256 ownerPrivateKey =
        uint256(
            0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356
        );
    EntryPoint newEntryPoint;
    address user = address(12);
    address notOwner = address(13);
    uint32 upgradeDelay = 172800; // 2 days in seconds
    uint256 chainId = block.chainid;

    TrueWalletFactory factory;

    function setUp() public {
        entryPoint = new EntryPoint();
        walletImpl = new TrueWallet();
        paymaster = new VerifyingSingletonPaymaster(
            address(entryPoint),
            ownerAddress,
            ownerAddress
        );

        bytes memory data = abi.encodeCall(
            TrueWallet.initialize,
            (address(entryPoint), ownerAddress, upgradeDelay)
        );

        TrueWalletProxy proxy = new TrueWalletProxy(address(walletImpl), data);
        wallet = TrueWallet(payable(address(proxy)));

        factory = new TrueWalletFactory(address(wallet), address(this));
    }

    function testSetupState() public {
        assertEq(paymaster.owner(), address(ownerAddress));
        assertEq(paymaster.verifyingSigner(), address(ownerAddress));
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
        vm.expectRevert(); // check revert message
        paymaster.deposit{value: 0.5 ether}();

        assertEq(address(entryPoint).balance, 0 ether);
        assertEq(paymaster.getDeposit(), 0 ether);
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

    function testGetBalance() public {
        address paymasterId1 = address(14);
        assertEq(paymaster.getBalance(paymasterId1), 0);
    }

    // TODO
    function testValidatePaymasterUserOp() public {
        address paymasterId1 = address(14);
        uint256 maxCost = 1096029019333521;

        bytes32 salt = keccak256(
            abi.encodePacked(
                address(factory),
                address(entryPoint),
                upgradeDelay
            )
        );

        UserOperation memory userOp;
        // userOp = generateUserOp();
        // userOp.paymasterAndData = abi.encodePacked(address(paymaster));
        // // userOp.signature = createSignature2()

        // vm.prank(address(wallet));
        // bytes32 userOpHash = paymaster.getHash(userOp, paymasterId1);
        // bytes memory sign = createSignature(userOp, userOpHash, ownerPrivateKey, vm);
        // userOp.signature = sign;

        userOp = generateUserOp();

        // 2. Set initCode, to trigger wallet deploy
        bytes memory initCode = abi.encodePacked(
            abi.encodePacked(address(factory)),
            abi.encodeWithSelector(
                factory.createWallet.selector,
                address(entryPoint),
                ownerAddress,
                upgradeDelay,
                salt
            )
        );
        userOp.initCode = initCode;

        bytes32 userOpHash = entryPoint.getUserOpHash(userOp);
        bytes memory signature = createSignature2(
            userOpHash,
            ownerPrivateKey,
            vm
        );
        userOp.signature = signature;

        bytes memory paymasterAndData = abi.encode(
            address(paymaster),
            signature
        );
        userOp.paymasterAndData = paymasterAndData;

        // console.log("paymaster.code.length ", address(paymaster).code.length);

        vm.prank(address(entryPoint));
        paymaster.validatePaymasterUserOp(userOp, userOpHash, maxCost);

        // entryPoint.simulateValidation(userOp);
    }

    // helper for testValidatePaymasterUserOp()
    function generateUserOp() public returns (UserOperation memory userOp) {
        UserOperation memory userOp;

        // console.log("wallet.code.length ", address(wallet).code.length);

        userOp = UserOperation({
            sender: address(wallet),
            nonce: wallet.nonce(),
            initCode: "",
            callData: "",
            callGasLimit: 2_000_000,
            verificationGasLimit: 3_000_000,
            preVerificationGas: 1_000_000,
            maxFeePerGas: 1_000_105_660,
            maxPriorityFeePerGas: 1_000_000_000,
            paymasterAndData: "",
            signature: ""
        });
    }
}
