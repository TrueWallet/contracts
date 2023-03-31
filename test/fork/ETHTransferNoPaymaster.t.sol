// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "forge-std/Test.sol";

import {IWallet} from "src/wallet/IWallet.sol";
import {IWalletFactory} from "src/wallet/IWalletFactory.sol";
import {IEntryPoint} from "src/interfaces/IEntryPoint.sol";
import {ITruePaymaster} from "src/paymaster/ITruePaymaster.sol";
import {UserOperation} from "src/interfaces/UserOperation.sol";
import {createSignature} from "test/utils/createSignature.sol";
import {getUserOpHash} from "test/utils/getUserOpHash.sol";
import {MumbaiConfig} from "config/MumbaiConfig.sol";
import {MockERC20} from "../mock/MockERC20.sol";

contract ETHTransferNoPaymasterEntToEndTest is Test {
    IEntryPoint public constant entryPoint = IEntryPoint(MumbaiConfig.ENTRY_POINT);
    IWallet public constant wallet = IWallet(MumbaiConfig.WALLET);
    ITruePaymaster public constant paymaster = ITruePaymaster(MumbaiConfig.PAYMASTER);

    address payable public beneficiary = payable(MumbaiConfig.BENEFICIARY);
    uint256 ownerPrivateKey = vm.envUint("PRIVATE_KEY_TESTNET");
    address walletOwner = MumbaiConfig.WALLET_OWNER;

    MockERC20 public token;

    // Test case
    bytes32 public userOpHash;
    address aggregator;
    uint256 missingWalletFunds;
    address recipient = 0x9fD12be3448d73c4eF4B0ae189E090c4FD83C9A1;
    uint256 etherTransferAmount;

    UserOperation public userOp;

    function setUp() public {
        // 1. Generate a userOperation
        // UserOperation callData transfers a tokenTransferAmount of token to recipient
        userOp = UserOperation({
            sender: address(wallet),
            nonce: wallet.nonce(),
            initCode: "",
            callData: "",
            callGasLimit: 70_000,
            verificationGasLimit: 958666,
            preVerificationGas: 115256,
            maxFeePerGas: 1000105660,
            maxPriorityFeePerGas: 1000000000,
            paymasterAndData: "",
            signature: ""
        });

        // 2. Encode userOperation transfer
        etherTransferAmount = 1 ether;

        userOp.callData = abi.encodeWithSelector(
            wallet.execute.selector,
            address(recipient),
            etherTransferAmount,
            ""
        );

        // Sign userOperation and attach signature
        userOpHash = entryPoint.getUserOpHash(userOp);
        bytes memory signature = createSignature(userOp, userOpHash, ownerPrivateKey, vm);
        userOp.signature = signature;

        // Set remainder of test case
        aggregator = address(0);
        missingWalletFunds = 1096029019333521;

        // 3. Fund deployer with ETH
        vm.deal(address(wallet), 5 ether);
    }

    /// @notice Validate that the smart wallet can validate a userOperation
    function testWalletValidateUserOp() public {
        vm.prank(address(entryPoint));
        wallet.validateUserOp(userOp, userOpHash, aggregator, missingWalletFunds);
    }

    /// @notice Validate that the EntryPoint can execute a userOperation.
    ///         No Paymaster, smart wallet pays for gas
    function testHandleOpsNoPaymaster() public {
        uint256 initialRecipientETHBalance = address(recipient).balance;
        uint256 initialWalletETHBalance = address(wallet).balance;

        UserOperation[] memory userOps = new UserOperation[](1);
        userOps[0] = userOp;

        // Transfer ether through the entryPoint
        entryPoint.handleOps(userOps, beneficiary);

        // Verify ether transfer from wallet to recipient
        uint256 finalRecipientETHBalance = address(recipient).balance;
        assertEq(finalRecipientETHBalance, initialRecipientETHBalance + etherTransferAmount);

        uint256 finalWalletETHBalance = address(wallet).balance;
        assertLt(finalWalletETHBalance, initialWalletETHBalance);

        // Verify wallet paid for gas
        uint256 walletEthGasPaid = initialWalletETHBalance - finalWalletETHBalance - etherTransferAmount;
        assertGt(walletEthGasPaid, 0);
    }
}