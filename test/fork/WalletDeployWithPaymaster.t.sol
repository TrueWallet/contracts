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

contract WalletDeployWithPaymasterEndToEndTest is Test {
    IEntryPoint public constant entryPoint = IEntryPoint(MumbaiConfig.ENTRY_POINT_V6);
    IWallet public constant wallet = IWallet(MumbaiConfig.FACTORY);
    IWalletFactory public constant walletFactory = IWalletFactory(MumbaiConfig.FACTORY);
    ITruePaymaster public constant paymaster = ITruePaymaster(MumbaiConfig.PAYMASTER);

    address payable public beneficiary = payable(MumbaiConfig.BENEFICIARY);
    uint256 ownerPrivateKey = vm.envUint("PRIVATE_KEY_TESTNET");
    address walletOwner = MumbaiConfig.WALLET_OWNER;
    address securityModule = MumbaiConfig.SECURITY_CONTROL_MODULE;

    // Test case
    bytes32 public userOpHash;
    address aggregator;
    uint256 missingWalletFunds;
    bytes32 salt = keccak256(abi.encodePacked(address(walletFactory), address(entryPoint), block.timestamp));
    uint32 upgradeDelay = 172800; // 2 days in seconds
    bytes[] modules = new bytes[](1);

    UserOperation public userOp;

    function setUp() public {
        bytes memory initData = abi.encode(uint32(1));
        modules[0] = abi.encodePacked(securityModule, initData);

        // 0. Determine what the sender account will be beforehand
        address sender = walletFactory.getWalletAddress(salt);
        vm.deal(sender, 1 ether);

        // 1. Generate a userOperation
        userOp = UserOperation({
            sender: sender,
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

        // 2. Set initCode, to trigger wallet deploy
        bytes memory initializer = walletFactory.getInitializer(address(entryPoint), walletOwner, modules);
        bytes memory initCode = abi.encodePacked(
            abi.encodePacked(address(walletFactory)),
            abi.encodeWithSelector(walletFactory.createWallet.selector, initializer, salt)
        );
        userOp.initCode = initCode;

        // 3. Set paymaster on UserOperation
        userOp.paymasterAndData = abi.encodePacked(address(paymaster));

        // 4. Sign userOperation and attach signature
        userOpHash = entryPoint.getUserOpHash(userOp);
        bytes memory signature = createSignature(userOp, userOpHash, ownerPrivateKey, vm);
        userOp.signature = signature;

        // 5. Set remainder of test case
        missingWalletFunds = 1096029019333521;

        // 6. Fund deployer with ETH
        vm.deal(address(MumbaiConfig.WALLET_OWNER), 5 ether);

        // 7. Deposit paymaster to pay for gas
        vm.startPrank(address(MumbaiConfig.WALLET_OWNER));
        paymaster.deposit{value: 2 ether}();
        paymaster.addStake{value: 1 ether}(1);
        vm.stopPrank();
    }

    /// @notice Validate that the WalletFactory deploys a smart wallet and Paymaster pays for gas
    function testWalletDeployWithPaymaster() public {
        uint256 initialWalletETHBalance = address(wallet).balance;
        uint256 initialPaymasterDeposit = paymaster.getDeposit();
        assertGt(initialPaymasterDeposit, 0);

        UserOperation[] memory userOps = new UserOperation[](1);
        userOps[0] = userOp;

        // Deploy wallet through the entryPoint
        entryPoint.handleOps(userOps, beneficiary);

        // Verify wallet was deployed as expected
        address expectedWalletAddress = walletFactory.getWalletAddress(salt);
        IWallet deployedWallet = IWallet(expectedWalletAddress);

        // Extract the code at the expected address
        uint256 codeSize = expectedWalletAddress.code.length;
        assertGt(codeSize, 0);
        assertTrue(deployedWallet.isOwner(walletOwner));
        assertEq(deployedWallet.entryPoint(), address(entryPoint));

        // Verify paymaster deposit on entryPoint was used to pay for gas
        // uint256 gasFeePaymasterPayed = initialPaymasterDeposit -
        //     paymaster.getDeposit();
        assertGt(initialPaymasterDeposit, paymaster.getDeposit());

        // Verify smart contract wallet did not use it's gas deposit
        uint256 gasFeeWalletPayed = initialWalletETHBalance - address(wallet).balance;
        assertEq(gasFeeWalletPayed, 0);
    }
}
