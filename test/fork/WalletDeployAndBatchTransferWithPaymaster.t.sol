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
import {MockERC1155} from "../mocks/MockERC1155.sol";

contract WalletDeployAndBatchTransferWithPaymasterEndToEndTest is Test {
    IEntryPoint public constant entryPoint = IEntryPoint(MumbaiConfig.ENTRY_POINT_V6);
    IWalletFactory public constant walletFactory = IWalletFactory(MumbaiConfig.FACTORY);
    ITruePaymaster public constant paymaster = ITruePaymaster(MumbaiConfig.PAYMASTER);

    address payable public bundler = payable(MumbaiConfig.BENEFICIARY);
    uint256 ownerPrivateKey = vm.envUint("PRIVATE_KEY_TESTNET");
    address walletOwner = MumbaiConfig.WALLET_OWNER;
    address securityModule = MumbaiConfig.SECURITY_CONTROL_MODULE;

    // Test case
    MockERC1155 public token;
    uint256 tokenId;
    uint256 amount;
    uint256 etherTransferAmount;
    address wallet;
    address recipient = 0x9fD12be3448d73c4eF4B0ae189E090c4FD83C9A1;
    bytes32 public userOpHash;
    uint256 missingWalletFunds;
    bytes32 salt = keccak256(abi.encodePacked(address(walletFactory), address(entryPoint), block.timestamp));
    uint32 upgradeDelay = 172800; // 2 days in seconds
    bytes[] modules = new bytes[](1);

    UserOperation public userOp;

    function setUp() public {
        bytes memory initData = abi.encode(uint32(1));
        modules[0] = abi.encodePacked(securityModule, initData);

        // 0. Determine what the wallet account will be beforehand and fund ether to this address
        wallet = walletFactory.getWalletAddress(salt);
        vm.deal(wallet, 1 ether);

        // 1. Deploy a MockERC1155 and fund smart wallet with this tokens
        tokenId = 1;
        amount = 100;
        token = new MockERC1155();
        token.mint(address(wallet), tokenId, amount, "");

        // 2. Generate a userOperation
        userOp = UserOperation({
            sender: wallet,
            nonce: 0, // 0 nonce, wallet is not deployed and won't be called
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

        // 3. Set initCode, to trigger wallet deploy
        bytes memory initializer = walletFactory.getInitializer(address(entryPoint), walletOwner, modules);
        bytes memory initCode = abi.encodePacked(
            abi.encodePacked(address(walletFactory)),
            abi.encodeWithSelector(walletFactory.createWallet.selector, initializer, salt)
        );
        userOp.initCode = initCode;

        // 4. Encode userOperation batch transfer
        etherTransferAmount = 0.7 ether;
        (address[] memory target, uint256[] memory values, bytes[] memory payloads) = createBatchData();

        userOp.callData = abi.encodeWithSelector(IWallet(wallet).executeBatch.selector, target, values, payloads);

        // 5. Set paymaster on UserOperation
        userOp.paymasterAndData = abi.encodePacked(address(paymaster));

        // 6. Sign userOperation and attach signature
        userOpHash = entryPoint.getUserOpHash(userOp);
        bytes memory signature = createSignature(userOp, userOpHash, ownerPrivateKey, vm);
        userOp.signature = signature;

        // 7. Set remainder of test case
        missingWalletFunds = 1096029019333521;

        // 8. Fund deployer with ETH
        vm.deal(address(MumbaiConfig.WALLET_OWNER), 5 ether);

        // 9. Deposit paymaster to pay for gas
        vm.startPrank(address(MumbaiConfig.WALLET_OWNER));
        paymaster.deposit{value: 2 ether}();
        paymaster.addStake{value: 1 ether}(1);
        vm.stopPrank();
    }

    // helper
    function createBatchData() public view returns (address[] memory, uint256[] memory, bytes[] memory) {
        address[] memory target = new address[](2);
        target[0] = address(token);
        target[1] = address(recipient);

        uint256[] memory values = new uint256[](2);
        values[0] = uint256(0);
        values[1] = uint256(etherTransferAmount);

        bytes[] memory payloads = new bytes[](2);
        payloads[0] =
            abi.encodeWithSelector(token.safeTransferFrom.selector, address(wallet), recipient, tokenId, amount, "");
        payloads[1] = "";

        return (target, values, payloads);
    }

    /// @notice Validate that the AA wallet can receive assets before deployment.
    /// The AA wallet is only actually deployed when you send the first transaction with the wallet.
    /// The wallet executes batch assets transfer and Paymaster pays for gas.
    function testWalletDeployAndAssetsBatchTransferWithPaymaster() public {
        // Verify wallet was not deployed yet
        address expectedWalletAddress = walletFactory.getWalletAddress(salt);
        IWallet deployedWallet = IWallet(expectedWalletAddress);

        // Extract the code at the expected address
        uint256 codeSize = expectedWalletAddress.code.length;
        assertEq(codeSize, 0);

        // Verify the balances before deployment
        assertEq(token.balanceOf(recipient, tokenId), 0);
        assertEq(token.balanceOf(address(wallet), tokenId), amount);

        uint256 initialWalletETHBalance = address(wallet).balance;
        assertEq(initialWalletETHBalance, 1 ether);
        uint256 initialRecipientETHBalance = address(recipient).balance;
        uint256 initialPaymasterDeposit = paymaster.getDeposit();
        assertGt(initialPaymasterDeposit, 0);
        uint256 initialBundlerETHBalance = address(bundler).balance;

        UserOperation[] memory userOps = new UserOperation[](1);
        userOps[0] = userOp;

        // Deploy wallet through the entryPoint
        entryPoint.handleOps(userOps, bundler);

        // Verify wallet was deployed as expected
        expectedWalletAddress = walletFactory.getWalletAddress(salt);
        deployedWallet = IWallet(expectedWalletAddress);

        // Extract the code at the expected address after deployment
        codeSize = expectedWalletAddress.code.length;
        assertGt(codeSize, 0);
        assertTrue(deployedWallet.isOwner(walletOwner));
        assertEq(deployedWallet.entryPoint(), address(entryPoint));

        // Verify paymaster deposit on entryPoint was used to pay for gas
        uint256 gasFeePaymasterPayed = initialPaymasterDeposit - paymaster.getDeposit();
        assertGt(initialPaymasterDeposit, paymaster.getDeposit());

        // Verify bundler balance received gas fee
        uint256 gasFeeBundlerCompensated = address(bundler).balance - initialBundlerETHBalance;
        assertEq(gasFeeBundlerCompensated, gasFeePaymasterPayed);

        // Verify smart contract wallet did not use it's gas deposit
        uint256 gasFeeWalletPayed = initialWalletETHBalance - address(wallet).balance - etherTransferAmount;
        assertEq(gasFeeWalletPayed, 0);

        // Verify the wallet and recipient balances after deployment
        assertEq(address(wallet).balance, initialWalletETHBalance - etherTransferAmount);
        assertEq(address(recipient).balance, initialRecipientETHBalance + etherTransferAmount);
        assertEq(token.balanceOf(recipient, tokenId), amount);
        assertEq(token.balanceOf(address(wallet), tokenId), 0);
    }
}
