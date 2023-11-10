// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import {IWallet} from "src/wallet/IWallet.sol";
import {IWalletFactory} from "src/wallet/IWalletFactory.sol";
import {IEntryPoint} from "src/interfaces/IEntryPoint.sol";
import {UserOperation} from "src/interfaces/UserOperation.sol";
import {createSignature} from "test/utils/createSignature.sol";
import {getUserOpHash} from "test/utils/getUserOpHash.sol";
import {MumbaiConfig} from "config/MumbaiConfig.sol";
import {MockERC721} from "../mocks/MockERC721.sol";

contract WalletDeployAndTransferNoPaymasterEntToEndTest is Test {
    IEntryPoint public constant entryPoint =
        IEntryPoint(MumbaiConfig.ENTRY_POINT);
    IWalletFactory public constant walletFactory =
        IWalletFactory(MumbaiConfig.FACTORY);

    address payable public bundler = payable(MumbaiConfig.BENEFICIARY);
    uint256 ownerPrivateKey = vm.envUint("PRIVATE_KEY_TESTNET");
    address walletOwner = MumbaiConfig.WALLET_OWNER;
    address securityModule = MumbaiConfig.SECURITY_CONTROL_MODULE;

    // Test case
    MockERC721 public token;
    uint256 tokenId;
    address recipient = 0x9fD12be3448d73c4eF4B0ae189E090c4FD83C9A1;
    address wallet;
    bytes32 public userOpHash;
    uint256 missingWalletFunds;
    bytes32 salt =
        keccak256(
            abi.encodePacked(
                address(walletFactory),
                address(entryPoint),
                block.timestamp
            )
        );
    uint32 upgradeDelay = 172800; // 2 days in seconds
    bytes[] modules = new bytes[](1);

    UserOperation public userOp;

    function setUp() public {
        bytes memory initData = abi.encode(uint32(1));
        modules[0] = abi.encodePacked(securityModule, initData);

        // 0. Determine what the wallet account will be beforehand and fund ether to this address
        wallet = walletFactory.getWalletAddress(
            address(entryPoint),
            walletOwner,
            upgradeDelay,
            modules,
            salt
        );
        vm.deal(wallet, 1 ether);

        // 1. Deploy a MockERC721 and fund smart wallet with token
        tokenId = 1;
        token = new MockERC721("Token", "TKN");
        token.safeMint(address(wallet), tokenId);

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
        bytes memory initCode = abi.encodePacked(
            abi.encodePacked(address(walletFactory)),
            abi.encodeWithSelector(
                walletFactory.createWallet.selector,
                address(entryPoint),
                walletOwner,
                upgradeDelay,
                modules,
                salt
            )
        );
        userOp.initCode = initCode;

        // 4. Encode userOperation transfer
        userOp.callData = abi.encodeWithSelector(
            IWallet(wallet).execute.selector,
            address(token),
            0,
            abi.encodeWithSelector(
                token.transferFrom.selector,
                address(wallet),
                recipient,
                tokenId
            )
        );

        // 5. Sign userOperation and attach signature
        userOpHash = entryPoint.getUserOpHash(userOp);
        bytes memory signature = createSignature(
            userOp,
            userOpHash,
            ownerPrivateKey,
            vm
        );
        userOp.signature = signature;

        // 6. Set remainder of test case
        missingWalletFunds = 1096029019333521;

        // 7. Fund deployer with ETH
        vm.deal(address(MumbaiConfig.DEPLOYER), 5 ether);
    }

    /// @notice Validate that the AA wallet can receive assets before deployment.
    /// The AA wallet is only actually deployed when you send the first transaction with the wallet.
    function testWalletDeployAndTokenTransfer() public {
        // Verify wallet was not deployed yet
        address expectedWalletAddress = walletFactory.getWalletAddress(
            address(entryPoint),
            walletOwner,
            upgradeDelay,
            modules,
            salt
        );
        IWallet deployedWallet = IWallet(expectedWalletAddress);
        
        // Extract the code at the expected address
        uint256 codeSize = expectedWalletAddress.code.length;
        assertEq(codeSize, 0);

        // Verify the balances before deployment
        assertEq(address(wallet).balance, 1 ether);
        assertEq(token.balanceOf(address(wallet)), 1);
        assertEq(token.ownerOf(tokenId), address(wallet));
        assertEq(token.balanceOf(address(recipient)), 0);

        uint256 initialAccountDepositBalance = entryPoint.balanceOf(
            userOp.sender
        );
        assertEq(initialAccountDepositBalance, 0);

        UserOperation[] memory userOps = new UserOperation[](1);
        userOps[0] = userOp;

        assertEq(entryPoint.getNonce(address(wallet), 0), 0);

        // Deploy wallet and transfer token through the entryPoint
        entryPoint.handleOps(userOps, bundler);

        assertEq(entryPoint.getNonce(address(wallet), 0), 1);

        // Verify wallet was deployed as expected
        expectedWalletAddress = walletFactory.getWalletAddress(
            address(entryPoint),
            walletOwner,
            upgradeDelay,
            modules,
            salt
        );
        deployedWallet = IWallet(expectedWalletAddress);

        // Extract the code at the expected address after deployment
        codeSize = expectedWalletAddress.code.length;
        assertGt(codeSize, 0);
        assertTrue(deployedWallet.isOwner(walletOwner));
        assertEq(deployedWallet.entryPoint(), address(entryPoint));

        uint256 finalAccountDepositBalance = entryPoint.balanceOf(
            userOp.sender
        );
        assertGt(finalAccountDepositBalance, initialAccountDepositBalance);

        // Verify the balances after deployment
        assertLt(address(wallet).balance, 1 ether);
        assertEq(token.balanceOf(address(wallet)), 0);
        assertEq(token.balanceOf(address(recipient)), 1);
        assertEq(token.ownerOf(tokenId), address(recipient));
        // Verify wallet nonce incrementation
        assertEq(entryPoint.getNonce(address(deployedWallet), 0), 1);

        // Tx interaction with deployed wallet
        uint256 recipientEthBalanceBefore = address(recipient).balance;
        // Generate a  new userOperation
        uint256 currentNonce = IWallet(deployedWallet).nonce();

        UserOperation memory userOp2 = UserOperation({
            sender: address(deployedWallet),
            nonce: currentNonce,
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

        // Encode userOperation transfer
        uint256 etherTransferAmount = 1 ether;

        userOp2.callData = abi.encodeWithSelector(
            IWallet(deployedWallet).execute.selector,
            address(recipient),
            etherTransferAmount,
            ""
        );

        // Sign userOperation and attach signature
        userOpHash = entryPoint.getUserOpHash(userOp2);
        bytes memory signature = createSignature(
            userOp2,
            userOpHash,
            ownerPrivateKey,
            vm
        );
        userOp2.signature = signature;

        // Set remainder of test case
        missingWalletFunds = 1096029019333521;

        userOps[0] = userOp2;

        // Fund deployer with ETH
        vm.deal(address(deployedWallet), 5 ether);

        assertEq(address(wallet), address(deployedWallet));

        // Transfer ether through the entryPoint
        vm.prank(address(bundler));
        entryPoint.handleOps(userOps, bundler);

        // Verify the balance after tx execution
        assertEq(address(recipient).balance, recipientEthBalanceBefore + 1 ether);
        // Verify wallet nonce incrementation 
        assertEq(entryPoint.getNonce(address(deployedWallet), 0), 2);
    }
}
