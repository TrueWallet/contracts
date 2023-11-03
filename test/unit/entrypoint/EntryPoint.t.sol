// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import {TrueWallet} from "src/wallet/TrueWallet.sol";
import {TrueWalletProxy} from "src/wallet/TrueWalletProxy.sol";
import {UserOperation} from "src/interfaces/UserOperation.sol";
import {EntryPoint, IEntryPoint} from "src/entrypoint/EntryPoint.sol";
import {MockSetter} from "../../mocks/MockSetter.sol";

import {MockSignatureChecker} from "../../mocks/MockSignatureChecker.sol";
import {getUserOperation} from "../../utils/Fixtures.sol";
import {createSignature, createSignature2} from "test/utils/createSignature.sol";
import {ECDSA, SignatureChecker} from "openzeppelin-contracts/utils/cryptography/SignatureChecker.sol";

import {IWallet} from "src/wallet/IWallet.sol";
import {IWalletFactory} from "src/wallet/IWalletFactory.sol";
import {TrueWalletFactory} from "src/wallet/TrueWalletFactory.sol";

import {MockModule} from "../../mocks/MockModule.sol";

contract EntryPointUnitTest is Test {
    TrueWallet wallet;
    TrueWallet walletImpl;
    TrueWalletProxy proxy;
    MockSetter setter;
    EntryPoint entryPoint;
    address ownerAddress = 0x14dC79964da2C08b23698B3D3cc7Ca32193d9955; // anvil account (7)
    uint256 ownerPrivateKey = uint256(0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356);
    uint256 chainId = block.chainid;

    TrueWalletFactory factory;
    bytes32 salt = keccak256(abi.encodePacked(address(factory), address(entryPoint)));
    UserOperation public userOp;

    MockSignatureChecker signatureChecker;

    MockModule mockModule;
    bytes[] modules = new bytes[](1);

    uint32 upgradeDelay = 172800; // 2 days in seconds

    event ReceivedETH(address indexed sender, uint256 indexed amount);

    function setUp() public {
        wallet = new TrueWallet();
        entryPoint = new EntryPoint();
        mockModule = new MockModule();

        mockModule = new MockModule();
        bytes memory initData = abi.encode(uint32(1));
        modules[0] = abi.encodePacked(mockModule, initData);

        factory = new TrueWalletFactory(address(wallet), address(this), address(entryPoint));
    }

    function encodeError(
        string memory error
    ) internal pure returns (bytes memory encoded) {
        encoded = abi.encodeWithSignature(error);
    }

    function testSimulateValidation() public {
        // 0. Determine what the sender account will be beforehand
        address sender = factory.getWalletAddress(
            address(entryPoint),
            ownerAddress,
            upgradeDelay,
            modules,
            salt
        );
        vm.deal(address(sender), 1 ether);

        // 1. Generate a userOperation
        userOp = UserOperation({
            sender: address(sender),
            nonce: 0, // 0 nonce, wallet is not deployed and won't be called
            initCode: "",
            callData: "",
            callGasLimit: 2_000_000,
            verificationGasLimit: 5_000_000,
            preVerificationGas: 1_000_000,
            maxFeePerGas: 1_000_105_660,
            maxPriorityFeePerGas: 1_000_000_000,
            paymasterAndData: "",
            signature: ""
        });

        // 2. Set initCode, to trigger wallet deploy
        bytes memory initCode = abi.encodePacked(
            abi.encodePacked(address(factory)),
            abi.encodeWithSelector(
                factory.createWallet.selector,
                address(entryPoint),
                ownerAddress,
                upgradeDelay,
                modules,
                salt
            )
        );
        userOp.initCode = initCode;

        // 3. Sign userOperation and attach signature
        bytes32 userOpHash = entryPoint.getUserOpHash(userOp);
        bytes memory signature = createSignature(
            userOp,
            userOpHash,
            ownerPrivateKey,
            vm
        );
        userOp.signature = signature;

        UserOperation[] memory userOps = new UserOperation[](1);
        userOps[0] = userOp;

        // Successful result is ValidationResult error
        vm.expectRevert();
        entryPoint.simulateValidation(userOp);
    }

    function testHandleOps() public {
        // 0. Determine what the sender account will be beforehand
        address sender = factory.getWalletAddress(
            address(entryPoint),
            ownerAddress,
            upgradeDelay,
            modules,
            salt
        );
        vm.deal(address(sender), 1 ether);

        // console.log(address(sender).balance);

        // 1. Generate a userOperation
        userOp = UserOperation({
            sender: address(sender),
            nonce: 0, // 0 nonce, wallet is not deployed and won't be called
            initCode: "",
            callData: "",
            callGasLimit: 2_000_000,
            verificationGasLimit: 5_000_000,
            preVerificationGas: 1_000_000,
            maxFeePerGas: 1_000_105_660,
            maxPriorityFeePerGas: 1_000_000_000,
            paymasterAndData: "",
            signature: ""
        });

        // 2. Set initCode, to trigger wallet deploy
        bytes memory initCode = abi.encodePacked(
            abi.encodePacked(address(factory)),
            abi.encodeWithSelector(
                factory.createWallet.selector,
                address(entryPoint),
                ownerAddress,
                upgradeDelay,
                modules,
                salt
            )
        );
        userOp.initCode = initCode;

        // 3. Sign userOperation and attach signature
        bytes32 userOpHash = entryPoint.getUserOpHash(userOp);
        bytes memory signature = createSignature(
            userOp,
            userOpHash,
            ownerPrivateKey,
            vm
        );
        userOp.signature = signature;

        UserOperation[] memory userOps = new UserOperation[](1);
        userOps[0] = userOp;

        assertEq(entryPoint.getNonce(address(sender), 0), 0);

        // // Deploy wallet through the entryPoint
        entryPoint.handleOps(userOps, payable(address(ownerAddress)));
        // Verify wallet nonce incrementation 
        assertEq(entryPoint.getNonce(address(sender), 0), 1);
    }
}
