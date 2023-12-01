// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import {IEntryPoint, UserOperation} from "account-abstraction/interfaces/IEntryPoint.sol";
import {IWallet} from "src/wallet/IWallet.sol";
import {IWalletFactory} from "src/wallet/IWalletFactory.sol";
import {createSignature} from "test/utils/createSignature.sol";
import {getUserOpHash} from "test/utils/getUserOpHash.sol";
import {Bundler} from "test/mocks/protocol/Bundler.sol";
import {MumbaiConfig} from "config/MumbaiConfig.sol";

contract WalletDeployNoPaymasterEndToEndTest is Test {
    IEntryPoint public constant entryPoint = IEntryPoint(MumbaiConfig.ENTRY_POINT);
    IWalletFactory public constant walletFactory = IWalletFactory(MumbaiConfig.FACTORY);

    address payable public beneficiary = payable(MumbaiConfig.BENEFICIARY);
    uint256 ownerPrivateKey = vm.envUint("PRIVATE_KEY_TESTNET");
    address walletOwner = MumbaiConfig.WALLET_OWNER;
    address securityModule = MumbaiConfig.SECURITY_CONTROL_MODULE;

    // Test case
    bytes32 public userOpHash;
    uint256 missingWalletFunds;
    bytes32 salt = keccak256(abi.encodePacked(address(walletFactory), address(entryPoint), block.timestamp));
    uint32 upgradeDelay = 172800; // 2 days in seconds
    bytes[] modules = new bytes[](1);

    UserOperation public userOp;
    Bundler public bundler;
    address sender;

    function setUp() public {
        bytes memory initData = abi.encode(uint32(1));
        modules[0] = abi.encodePacked(securityModule, initData);

        // Determine what the sender account will be beforehand
        sender = walletFactory.getWalletAddress(address(entryPoint), walletOwner, upgradeDelay, modules, salt);

        // Generate a userOperation
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

        // Set initCode, to trigger wallet deploy
        bytes memory initCode = abi.encodePacked(
            abi.encodePacked(address(walletFactory)),
            abi.encodeWithSelector(
                walletFactory.createWallet.selector, address(entryPoint), walletOwner, upgradeDelay, modules, salt
            )
        );
        userOp.initCode = initCode;

        // Sign userOperation and attach signature
        userOpHash = entryPoint.getUserOpHash(userOp);
        bytes memory signature = createSignature(userOp, userOpHash, ownerPrivateKey, vm);
        userOp.signature = signature;

        // Set remainder of test case
        missingWalletFunds = 1096029019333521;

        bundler = new Bundler();
    }

    /// @notice Validate that the WalletFactory deploys a smart wallet
    function testWalletDeploy() public {
        uint256 initialAccountDepositBalance = entryPoint.balanceOf(userOp.sender);
        uint256 initialBeneficiaryBalance = address(beneficiary).balance;

        UserOperation[] memory userOps = new UserOperation[](1);
        userOps[0] = userOp;

        vm.expectRevert(abi.encodeWithSelector(IEntryPoint.FailedOp.selector, 0, "AA21 didn't pay prefund"));

        // Deploy wallet through the bundler
        vm.prank(beneficiary);
        bundler.post(entryPoint, userOp);
        // Deploy wallet through the entryPoint
        // entryPoint.handleOps(userOps, beneficiary);

        assertEq(sender.code.length, 0, "sender.code.length != 0");

        // Fund sender with ETH to pay prefund
        vm.deal(sender, 1 ether);
        // Deploy wallet through the bundler
        vm.prank(beneficiary);
        bundler.post(entryPoint, userOp);
        // Deploy wallet through the entryPoint
        // entryPoint.handleOps(userOps, beneficiary);

        assertEq(sender.code.length > 0, true, "sender.code.length == 0");

        // Verify wallet was deployed as expected
        address expectedWalletAddress =
            walletFactory.getWalletAddress(address(entryPoint), walletOwner, upgradeDelay, modules, salt);
        IWallet deployedWallet = IWallet(expectedWalletAddress);

        // Extract the code at the expected address
        assertEq(address(sender), address(expectedWalletAddress));
        assertEq(deployedWallet.entryPoint(), address(entryPoint));
        assertEq(deployedWallet.nonce(), 1);
        assertTrue(deployedWallet.isOwner(walletOwner));

        uint256 finalAccountDepositBalance = entryPoint.balanceOf(userOp.sender);
        assertGt(finalAccountDepositBalance, initialAccountDepositBalance);

        uint256 finalBeneficiaryBalance = address(beneficiary).balance;
        assertEq(finalBeneficiaryBalance > initialBeneficiaryBalance, true, "beneficiary didn't receive payment");
    }
}