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
import {MockERC721} from "../mocks/MockERC721.sol";

contract ERC721TransferWithPaymasterEndToEndTest is Test {
    IEntryPoint public constant entryPoint = IEntryPoint(MumbaiConfig.ENTRY_POINT_V6);
    IWallet public constant wallet = IWallet(MumbaiConfig.WALLET_PROXY);
    ITruePaymaster public constant paymaster = ITruePaymaster(MumbaiConfig.PAYMASTER);

    address payable public beneficiary = payable(MumbaiConfig.BENEFICIARY);
    uint256 ownerPrivateKey = vm.envUint("PRIVATE_KEY_TESTNET");
    address walletOwner = MumbaiConfig.WALLET_OWNER;

    MockERC721 public token;

    // Test case
    bytes32 public userOpHash;
    address aggregator;
    uint256 missingWalletFunds;
    address recipient = 0x9fD12be3448d73c4eF4B0ae189E090c4FD83C9A1;
    uint256 tokenId;

    UserOperation public userOp;

    function setUp() public {
        // 0. Deploy a MockERC721 and fund smart wallet with tokens
        tokenId = 1;
        token = new MockERC721("Token", "TKN");
        token.safeMint(address(wallet), tokenId);

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
        userOp.callData = abi.encodeWithSelector(
            wallet.execute.selector,
            address(token),
            0,
            abi.encodeWithSelector(token.transferFrom.selector, address(wallet), recipient, tokenId)
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
        vm.deal(address(MumbaiConfig.WALLET_OWNER), 5 ether);

        // 6. Deposit paymaster to pay for gas
        vm.startPrank(address(MumbaiConfig.WALLET_OWNER));
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
        assertEq(token.balanceOf(recipient), 0);
        assertEq(token.balanceOf(address(wallet)), 1);
        assertEq(token.ownerOf(tokenId), address(wallet));

        uint256 initialWalletETHBalance = address(wallet).balance;
        uint256 initialBeneficiaryETHBalance = address(beneficiary).balance;
        uint256 initialPaymasterDeposit = paymaster.getDeposit();
        assertEq(initialPaymasterDeposit, 2 ether);

        UserOperation[] memory userOps = new UserOperation[](1);
        userOps[0] = userOp;

        // Transfer ether through the entryPoint
        entryPoint.handleOps(userOps, beneficiary);

        // Verify that all ether funds are in place in the smart wallet
        uint256 finalWalletETHBalance = address(wallet).balance;
        assertEq(finalWalletETHBalance, initialWalletETHBalance);

        // Verify token transferred from wallet to recipient
        assertEq(token.balanceOf(address(wallet)), 0);
        assertEq(token.balanceOf(recipient), 1);
        assertEq(token.ownerOf(tokenId), address(recipient));

        // Verify paymaster deposit on entryPoint was used to pay for gas
        uint256 gasFeePaymasterPayed = initialPaymasterDeposit - paymaster.getDeposit();
        assertGt(initialPaymasterDeposit, paymaster.getDeposit());

        // Verify beneficiary(bundler) balance received gas fee
        uint256 gasFeeBeneficiaryCompensated = address(beneficiary).balance - initialBeneficiaryETHBalance;
        assertEq(gasFeeBeneficiaryCompensated, gasFeePaymasterPayed);
    }
}
