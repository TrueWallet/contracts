// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "forge-std/Test.sol";

import {Paymaster} from "src/paymaster/Paymaster.sol";
import {TrueWallet} from "src/wallet/TrueWallet.sol";
import {TrueWalletProxy} from "src/wallet/TrueWalletProxy.sol";
import {UserOperation} from "src/interfaces/UserOperation.sol";
import {EntryPoint} from "src/entrypoint/EntryPoint.sol";
import {IPaymaster} from "src/interfaces/IPaymaster.sol";
import {IEntryPoint} from "src/interfaces/IEntryPoint.sol";
import {VerifyingPaymaster} from "src/paymaster/VerifyingPaymaster.sol";
import {createSignature, createSignature2} from "test/utils/createSignature.sol";
import "src/helper/Helpers.sol";

import "lib/forge-std/src/console.sol";

contract VerifyingPaymasterUnitTest is Test {
    TrueWallet wallet;
    TrueWallet walletImpl;
    VerifyingPaymaster paymaster;
    EntryPoint entryPoint;
    address ownerAddress = 0x14dC79964da2C08b23698B3D3cc7Ca32193d9955; // anvil account (7)
    uint256 ownerPrivateKey =
        uint256(0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356);
    EntryPoint newEntryPoint;
    address user = address(12);
    address notOwner = address(13);
    uint32 upgradeDelay = 172800; // 2 days in seconds

    function setUp() public {
        entryPoint = new EntryPoint();
        walletImpl = new TrueWallet();
        paymaster = new VerifyingPaymaster(entryPoint, ownerAddress, ownerAddress);

        bytes memory data = abi.encodeCall(
            TrueWallet.initialize,
            (address(entryPoint), ownerAddress, upgradeDelay)
        ); 

        TrueWalletProxy proxy = new TrueWalletProxy(address(walletImpl), data);
        wallet = TrueWallet(payable(address(proxy)));
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

    ///
    function generateUserOp() public returns(UserOperation memory userOp) {
        UserOperation memory userOp;

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

    uint48 MOCK_VALID_UNTIL = 0x00000000deadbeef;
    uint48 MOCK_VALID_AFTER = 0x0000000000001234;

    function testParsePaymasterAndData() public {
        UserOperation memory userOp;

        userOp = generateUserOp();
        bytes32 userOpHash = entryPoint.getUserOpHash(userOp);
        bytes memory signature = createSignature(userOp, userOpHash, ownerPrivateKey, vm);
        userOp.signature = signature;

        bytes memory paymasterAndData = abi.encodePacked(
            address(paymaster),
            abi.encode(
                MOCK_VALID_UNTIL,
                MOCK_VALID_AFTER
            ),
            signature
        );

        (uint48 validUntil, uint48 validAfter, bytes memory sign) = 
            paymaster.parsePaymasterAndData(paymasterAndData);

        assertEq(validUntil, MOCK_VALID_UNTIL);
        assertEq(validAfter, MOCK_VALID_AFTER);
        assertEq(signature, sign);
    }

    function testValidatePaymasterUserOp() public {
        UserOperation memory userOp;

        userOp = generateUserOp();

        bytes32 opHash = paymaster.getHash(userOp, MOCK_VALID_UNTIL, MOCK_VALID_AFTER);
        bytes memory sign = createSignature2(opHash, ownerPrivateKey, vm);

        userOp.paymasterAndData = abi.encodePacked(
            address(paymaster),
            abi.encode(
                MOCK_VALID_UNTIL,
                MOCK_VALID_AFTER
            ),
            sign
        );

        // Set remainder of test case
        // address aggregator = address(0);
        uint256 missingWalletFunds = 1096029019333521;

        // Validate that the smart wallet can validate a userOperation
        vm.prank(address(entryPoint));
        (, uint256 validationData) = paymaster.validatePaymasterUserOp(userOp, opHash, missingWalletFunds);
        
        // entryPoint.simulateValidation(userOp);

        ValidationData memory data;
        data = _parseValidationData(validationData);
        
        console.log(data.aggregator);
        console.log(data.validAfter);
        console.log(data.validUntil);

        assertEq(data.validUntil, MOCK_VALID_UNTIL);
        assertEq(data.validAfter, MOCK_VALID_AFTER);
    }
}