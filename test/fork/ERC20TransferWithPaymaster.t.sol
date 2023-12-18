// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import {IEntryPoint, UserOperation} from "account-abstraction/interfaces/IEntryPoint.sol";
import {IWallet} from "src/interfaces/IWallet.sol";
import {IWalletFactory} from "src/interfaces/IWalletFactory.sol";
import {ITruePaymaster} from "src/paymaster/ITruePaymaster.sol";
import {createSignature} from "test/utils/createSignature.sol";
import {getUserOpHash} from "test/utils/getUserOpHash.sol";
import {MumbaiConfig} from "config/MumbaiConfig.sol";
import {MockERC20} from "../mocks/MockERC20.sol";

contract ERC20TransferWithPaymasterEndToEndTest is Test {
    IEntryPoint public constant entryPoint = IEntryPoint(MumbaiConfig.OFFICIAL_ENTRY_POINT);
    IWallet public constant wallet = IWallet(MumbaiConfig.WALLET_PROXY);
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
    uint256 tokenTransferAmount;

    UserOperation public userOp;

    function setUp() public {
        // 0. Deploy a MockERC20 and fund smart wallet with tokens
        token = new MockERC20();
        token.mint(address(wallet), 1000);

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
        tokenTransferAmount = 100;

        userOp.callData = abi.encodeWithSelector(
            wallet.execute.selector,
            address(token),
            0,
            abi.encodeWithSelector(token.transfer.selector, recipient, tokenTransferAmount)
        );

        // 3. Set paymaster on UserOperation
        userOp.paymasterAndData = abi.encodePacked(address(paymaster));

        // 4. Sign userOperation and attach signature
        userOpHash = entryPoint.getUserOpHash(userOp);
        bytes memory signature = createSignature(userOp, userOpHash, ownerPrivateKey, vm);
        userOp.signature = signature;

        // Set remainder of test case
        missingWalletFunds = 1096029019333521;

        // 5. Fund deployer with ETH
        vm.deal(address(MumbaiConfig.DEPLOYER), 5 ether);

        // 6. Deposite paymaster to pay for gas
        vm.startPrank(address(MumbaiConfig.DEPLOYER));
        paymaster.deposit{value: 2 ether}();
        paymaster.addStake{value: 1 ether}(1);
        vm.stopPrank();

        // 7. Fund wallet with etherTransferAmount
        vm.deal(address(wallet), 1 ether);
    }

    /// @notice Validate that the smart wallet can validate a userOperation
    function testWalletValidateUserOp() public {
        vm.prank(address(entryPoint));
        wallet.validateUserOp(userOp, userOpHash, missingWalletFunds);
    }

    /// @notice Validate that the EntryPoint can execute a userOperation.
    ///         Paymaster pays for gas
    function testHandleOpsWithPaymaster() public {
        uint256 initialRecipientERC20Balance = token.balanceOf(recipient);
        uint256 initialWalletERC20Balance = token.balanceOf(address(wallet));
        uint256 initialWalletETHBalance = address(wallet).balance;
        uint256 initialBeneficiaryETHBalance = address(beneficiary).balance;
        uint256 initialPaymasterDeposite = paymaster.getDeposit();
        assertEq(initialPaymasterDeposite, 2 ether);

        UserOperation[] memory userOps = new UserOperation[](1);
        userOps[0] = userOp;

        // Transfer ether through the entryPoint
        entryPoint.handleOps(userOps, beneficiary);

        // Verify that all ether funds are in place in the smart wallet
        uint256 finalWalletETHBalance = address(wallet).balance;
        assertEq(finalWalletETHBalance, initialWalletETHBalance);

        // Verify respective token amount transfered from wallet to recipient
        uint256 finalWalletERC20Balance = token.balanceOf(address(wallet));
        assertEq(finalWalletERC20Balance, initialWalletERC20Balance - tokenTransferAmount);
        assertEq(token.balanceOf(recipient), initialRecipientERC20Balance + tokenTransferAmount);

        // Verify paymaster deposit on entryPoint was used to pay for gas
        uint256 gasFeePaymasterPayd = initialPaymasterDeposite - paymaster.getDeposit();
        assertGt(initialPaymasterDeposite, paymaster.getDeposit());

        // Verify beneficiary(bundler) balance received gas fee
        uint256 gasFeeBeneficiaryCompensated = address(beneficiary).balance - initialBeneficiaryETHBalance;
        assertEq(gasFeeBeneficiaryCompensated, gasFeePaymasterPayd);
    }
}
