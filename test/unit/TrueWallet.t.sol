// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "forge-std/Test.sol";

import {TrueWallet} from "src/wallet/TrueWallet.sol";
import {UserOperation} from "src/interfaces/UserOperation.sol";
import {EntryPoint} from "src/entrypoint/EntryPoint.sol";
import {MockSetter} from "../mock/MockSetter.sol";
import {MockERC20} from "../mock/MockERC20.sol";
import {MockERC721} from "../mock/MockERC721.sol";
import {MockERC1155} from "../mock/MockERC1155.sol";
import {MockSignatureChecker} from "../mock/MockSignatureChecker.sol";
import {getUserOperation} from "./Fixtures.sol";
import {createSignature, createSignature2} from "test/utils/createSignature.sol";
import {ECDSA, SignatureChecker} from "openzeppelin-contracts/utils/cryptography/SignatureChecker.sol";

contract TrueWalletUnitTest is Test {
    TrueWallet wallet;
    MockSetter setter;
    EntryPoint entryPoint;
    address ownerAddress = 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720; // envil account (9)
    uint256 ownerPrivateKey = 
        uint256(0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6);
    uint256 chainId = block.chainid;

    MockERC20 erc20token;
    MockERC721 erc721token;
    MockERC1155 erc1155token;

    MockSignatureChecker signatureChecker;

    function setUp() public {
        entryPoint = new EntryPoint();
        wallet = new TrueWallet(address(entryPoint), ownerAddress);
        setter = new MockSetter();
        erc20token = new MockERC20();
        erc721token = new MockERC721("Token", "TKN");
        erc1155token = new MockERC1155();
        signatureChecker = new MockSignatureChecker();

        vm.deal(address(wallet), 5 ether);
    }

    function testSetupState() public {
        assertEq(wallet.owner(), address(ownerAddress));
        assertEq(address(wallet.entryPoint()), address(entryPoint));
    }

    function testUpdateEntryPoint() public {
        assertEq(address(wallet.entryPoint()), address(entryPoint));
        address newEntryPoint = address(12);
        vm.prank(address(ownerAddress));
        wallet.setEntryPoint(newEntryPoint);
        assertEq(address(wallet.entryPoint()), address(newEntryPoint));
    }

    function testUpdateEntryPointNotOwner() public {
        address newEntryPoint = address(12);
        address notOwner = address(13);
        vm.prank(address(notOwner));
        vm.expectRevert();
        wallet.setEntryPoint(newEntryPoint);
        assertEq(address(wallet.entryPoint()), address(entryPoint));
    }

    function testValidateUserOp() public {
        assertEq(wallet.nonce(), 0);

        (UserOperation memory userOp, bytes32 userOpHash) = getUserOperation(
            address(wallet),
            wallet.nonce(),
            abi.encodeWithSignature("setValue(uint256)", 1),
            address(entryPoint),
            uint8(chainId),
            ownerPrivateKey,
            vm
        );

        address aggregator = address(12);
        uint256 missingWalletFunds = 0;

        vm.prank(address(entryPoint));
        uint256 deadline = wallet.validateUserOp(
            userOp,
            userOpHash,
            aggregator,
            missingWalletFunds
        );
        assertEq(deadline, 0);
        assertEq(wallet.nonce(), 1);
    }

    function testExecuteByEntryPoint() public {
        assertEq(setter.value(), 0);

        bytes memory payload = 
            abi.encodeWithSelector(setter.setValue.selector, 1);

        vm.prank(address(entryPoint));
        wallet.execute(address(setter), 0, payload);

        assertEq(setter.value(), 1);
    }

    function testExecuteByOwner() public {
        assertEq(setter.value(), 0);

        bytes memory payload = 
            abi.encodeWithSelector(setter.setValue.selector, 1);

        vm.prank(address(ownerAddress));
        wallet.execute(address(setter), 0, payload);

        assertEq(setter.value(), 1);
    }

    function testExecuteNotEntryPoint() public {
        assertEq(setter.value(), 0);

        bytes memory payload = 
            abi.encodeWithSelector(setter.setValue.selector, 1);

        address notEntryPoint = address(13);
        vm.prank(address(notEntryPoint));
        vm.expectRevert();
        wallet.execute(address(setter), 0, payload);

        assertEq(setter.value(), 0);
    }

    function testExecuteBatchByEntryPoint() public {
        assertEq(setter.value(), 0);

        address[] memory target = new address[](2);
        target[0] = address(setter);
        target[1] = address(setter);
        bytes[] memory payloads = new bytes[](2);
        payloads[0] = abi.encodeWithSelector(setter.setValue.selector, 1);
        payloads[1] = abi.encodeWithSelector(setter.setValue.selector, 2);
        uint256[] memory values = new uint256[](2);
        values[0] = uint256(0);
        values[1] = uint256(0);

        vm.prank(address(entryPoint));
        wallet.executeBatch(target, values, payloads);

        assertEq(setter.value(), 2);
    }

    function testExecuteBatchByOwner() public {
        assertEq(setter.value(), 0);

        address[] memory target = new address[](2);
        target[0] = address(setter);
        target[1] = address(setter);
        bytes[] memory payloads = new bytes[](2);
        payloads[0] = abi.encodeWithSelector(setter.setValue.selector, 1);
        payloads[1] = abi.encodeWithSelector(setter.setValue.selector, 2);
        uint256[] memory values = new uint256[](2);
        values[0] = uint256(0);
        values[1] = uint256(0);

        vm.prank(address(ownerAddress));
        wallet.executeBatch(target, values, payloads);

        assertEq(setter.value(), 2);
    }

    function testExecuteBatchNotEntryPoint() public {
        assertEq(setter.value(), 0);

        address[] memory target = new address[](2);
        target[0] = address(setter);
        target[1] = address(setter);
        bytes[] memory payloads = new bytes[](2);
        payloads[0] = abi.encodeWithSelector(setter.setValue.selector, 1);
        payloads[1] = abi.encodeWithSelector(setter.setValue.selector, 2);
        uint256[] memory values = new uint256[](2);
        values[0] = uint256(0);
        values[1] = uint256(0);

        address notEntryPoint = address(13);
        vm.prank(address(notEntryPoint));
        vm.expectRevert();
        wallet.executeBatch(target, values, payloads);

        assertEq(setter.value(), 0);
    }

    function testPrefundEntryPoint() public {
        vm.deal(address(wallet), 1 ether);

        assertEq(wallet.nonce(), 0);

        uint256 balanceBefore = address(entryPoint).balance;

        (UserOperation memory userOp, bytes32 digest) = getUserOperation(
            address(wallet),
            wallet.nonce(),
            abi.encodeWithSignature("setValue(uint256)", 1),
            address(entryPoint),
            uint8(chainId),
            ownerPrivateKey,
            vm
        );

        address aggregator = address(12);
        uint256 missingWalletFunds = 0.001 ether;

        vm.prank(address(entryPoint));
        uint256 deadline = wallet.validateUserOp(
            userOp,
            digest,
            aggregator,
            missingWalletFunds
        );
        assertEq(deadline, 0);
        assertEq(wallet.nonce(), 1);

        assertEq(
            address(entryPoint).balance,
            balanceBefore + missingWalletFunds
        );
    }

    function testWithdrawERC20() public {
        MockERC20 token = new MockERC20();
        token.mint(address(wallet), 1 ether);

        assertEq(token.balanceOf(address(entryPoint)), 0);

        vm.prank(address(ownerAddress));
        wallet.withdrawERC20(address(token), address(entryPoint), 1 ether);

        assertEq(token.balanceOf(address(entryPoint)), 1 ether);
    }

    function testWithdrawERC20NotOwner() public {
        MockERC20 token = new MockERC20();
        token.mint(address(wallet), 1 ether);

        assertEq(token.balanceOf(address(entryPoint)), 0);

        address notOwner = address(13);
        vm.prank(address(notOwner));
        vm.expectRevert();
        wallet.withdrawERC20(address(token), address(entryPoint), 1 ether);

        assertEq(token.balanceOf(address(entryPoint)), 0 ether);
    }

    function testWithdrawETH() public {
        vm.deal(address(wallet), 1 ether);

        assertEq(address(entryPoint).balance, 0);

        vm.prank(address(ownerAddress));
        wallet.withdrawETH(payable(address(entryPoint)), 1 ether);

        assertEq(address(entryPoint).balance, 1 ether);
    }

    function testWithdrawETHNotOwner() public {
        vm.deal(address(wallet), 1 ether);

        assertEq(address(entryPoint).balance, 0);

        address notOwner = address(13);
        vm.prank(address(notOwner));
        vm.expectRevert();
        wallet.withdrawETH(payable(address(entryPoint)), 1 ether);

        assertEq(address(entryPoint).balance, 0 ether);
    }

    function testSafeMintERC721ToWallet() public {
        erc721token.safeMint(address(wallet), 1237);

        assertEq(erc721token.ownerOf(1237), address(wallet));
        assertEq(erc721token.balanceOf(address(wallet)), 1);
    }

    function testSafeTransferERC721FromToWallet() public {
        address from = address(0xABCD);
        
        erc721token.mint(from, 1237);

        vm.prank(from);
        erc721token.setApprovalForAll(address(this), true);

        erc721token.safeTransferFrom(from, address(wallet), 1237);

        assertEq(erc721token.getApproved(1237), address(0));
        assertEq(erc721token.ownerOf(1237), address(wallet));
        assertEq(erc721token.balanceOf(address(wallet)), 1);
        assertEq(erc721token.balanceOf(from), 0);
    }

    function testSafeTransferERC721FromToWalletWithData() public {
        address from = address(0xABCD);
        
        erc721token.mint(from, 1237);

        vm.prank(from);
        erc721token.setApprovalForAll(address(this), true);

        erc721token.safeTransferFrom(from, address(wallet), 1237, "testing 1237");

        assertEq(erc721token.getApproved(1237), address(0));
        assertEq(erc721token.ownerOf(1237), address(wallet));
        assertEq(erc721token.balanceOf(address(wallet)), 1);
        assertEq(erc721token.balanceOf(from), 0);
    }

    function testTransferERC721FromWalletTo() public {
        testSafeTransferERC721FromToWallet();

        address to = address(0xABCD);
        assertEq(erc721token.balanceOf(address(to)), 0);

        address target = address(erc721token);
        bytes memory payload = abi.encodeWithSelector(
            erc721token.transferFrom.selector,
            address(wallet),
            to,
            1237
        );

        vm.prank(address(entryPoint));
        wallet.execute(target, 0, payload);

        assertEq(erc721token.balanceOf(address(to)), 1);
        assertEq(erc721token.ownerOf(1237), address(to));
        assertEq(erc721token.balanceOf(address(wallet)), 0);
    }

    function testBatchTransferERC721FromWalletTo() public {
        testSafeTransferERC721FromToWallet();

        address from = address(0xABCD);
        erc721token.mint(from, 1238);

        vm.prank(from);
        erc721token.setApprovalForAll(address(this), true);
        erc721token.safeTransferFrom(from, address(wallet), 1238);

        address to = address(0xABCD);
        assertEq(erc721token.balanceOf(address(to)), 0);
        assertEq(erc721token.ownerOf(1237), address(wallet));
        assertEq(erc721token.ownerOf(1238), address(wallet));
        assertEq(erc721token.balanceOf(address(wallet)), 2);

        address[] memory target = new address[](2);
        target[0] = address(erc721token);
        target[1] = address(erc721token);
        bytes[] memory payloads = new bytes[](2);
        payloads[0] = abi.encodeWithSelector(
            erc721token.transferFrom.selector,
            address(wallet),
            to,
            1237
        );
        payloads[1] = abi.encodeWithSelector(
            erc721token.transferFrom.selector,
            address(wallet),
            to,
            1238
        );
        uint256[] memory values = new uint256[](2);
        values[0] = uint256(0);
        values[1] = uint256(0);

        vm.prank(address(entryPoint));
        wallet.executeBatch(target, values, payloads);

        assertEq(erc721token.balanceOf(address(to)), 2);
        assertEq(erc721token.ownerOf(1237), address(to));
        assertEq(erc721token.ownerOf(1238), address(to));
        assertEq(erc721token.balanceOf(address(wallet)), 0);
    }

    function testMintERC1155ToWallet() public {
        erc1155token.mint(address(wallet), 1237, 1, "testing 123");

        assertEq(erc1155token.balanceOf(address(wallet), 1237), 1);
    }

    function testSafeTransferERC1155TFromToWallet() public {
        address from = address(0xABCD);
        
        erc1155token.mint(from, 1237, 100, "");

        vm.prank(from);
        erc1155token.setApprovalForAll(address(this), true);

        erc1155token.safeTransferFrom(from, address(wallet), 1237, 70, "testing 1237");

        assertEq(erc1155token.balanceOf(address(wallet), 1237), 70);
        assertEq(erc1155token.balanceOf(from, 1237), 30);
    }

    function testTransferERC1155FromWalletTo() public {
        testSafeTransferERC1155TFromToWallet();

        address to = address(0xCDEF);
        assertEq(erc1155token.balanceOf(address(to), 1237), 0);
        assertEq(erc1155token.balanceOf(address(wallet), 1237), 70);

        address target = address(erc1155token);
        bytes memory payload = abi.encodeWithSelector(
            erc1155token.safeTransferFrom.selector,
            address(wallet),
            to,
            1237,
            40,
            "testing 1237"
        );

        vm.prank(address(entryPoint));
        wallet.execute(target, 0, payload);

        assertEq(erc1155token.balanceOf(address(to), 1237), 40);
        assertEq(erc1155token.balanceOf(address(wallet), 1237), 30);
    }

    function testBatchTransferERC1155FromWalletTo() public {
        testSafeTransferERC1155TFromToWallet();

        address to0 = address(0xCD);
        assertEq(erc1155token.balanceOf(address(to0), 1237), 0);
        address to1 = address(0xEF);
        assertEq(erc1155token.balanceOf(address(to1), 1237), 0);
        assertEq(erc1155token.balanceOf(address(wallet), 1237), 70);

        address[] memory target = new address[](2);
        target[0] = address(erc1155token);
        target[1] = address(erc1155token);
        bytes[] memory payloads = new bytes[](2);
        payloads[0] = abi.encodeWithSelector(
            erc1155token.safeTransferFrom.selector,
            address(wallet),
            to0,
            1237,
            35,
            "testing 1237"
        );
        payloads[1] = abi.encodeWithSelector(
            erc1155token.safeTransferFrom.selector,
            address(wallet),
            to1,
            1237,
            35,
            "testing 1237"
        );
        uint256[] memory values = new uint256[](2);
        values[0] = uint256(0);
        values[1] = uint256(0);

        vm.prank(address(entryPoint));
        wallet.executeBatch(target, values, payloads);

        assertEq(erc1155token.balanceOf(address(to0), 1237), 35);
        assertEq(erc1155token.balanceOf(address(to1), 1237), 35);
        assertEq(erc1155token.balanceOf(address(wallet), 1237), 0);
    }

    function testWithdrawERC721() public {
        testSafeMintERC721ToWallet();

        assertEq(erc721token.balanceOf(address(wallet)), 1);

        address to = address(0xCD);
        assertEq(erc721token.balanceOf(address(to)), 0);

        vm.prank(address(ownerAddress));
        wallet.withdrawERC721(address(erc721token), 1237, to);

        assertEq(erc721token.balanceOf(address(to)), 1);
        assertEq(erc721token.ownerOf(1237), address(to));
    }

    function testWithdrawERC721NotOwner() public {
        testSafeMintERC721ToWallet();

        assertEq(erc721token.balanceOf(address(wallet)), 1);

        address to = address(0xCD);
        assertEq(erc721token.balanceOf(address(to)), 0);

        address notOwner = address(13);
        vm.prank(address(notOwner));
        vm.expectRevert();
        wallet.withdrawERC721(address(erc721token), 1237, to);

        assertEq(erc721token.balanceOf(address(to)), 0);
        assertEq(erc721token.balanceOf(address(wallet)), 1);
    }

    function testWithdrawERC1155() public {
        testMintERC1155ToWallet();

        assertEq(erc1155token.balanceOf(address(wallet), 1237), 1);

        address to = address(0xCD);
        assertEq(erc1155token.balanceOf(address(to), 1237), 0);

        vm.prank(address(ownerAddress));
        wallet.withdrawERC1155(address(erc1155token), 1237, to, 1);

        assertEq(erc1155token.balanceOf(address(wallet), 1237), 0);
        assertEq(erc1155token.balanceOf(address(to), 1237), 1);
    }

    function testWithdrawERC1155NotOwner() public {
        testMintERC1155ToWallet();

        assertEq(erc1155token.balanceOf(address(wallet), 1237), 1);

        address to = address(0xCD);
        assertEq(erc1155token.balanceOf(address(to), 1237), 0);

        address notOwner = address(13);
        vm.prank(address(notOwner));
        vm.expectRevert();
        wallet.withdrawERC1155(address(erc1155token), 1237, to, 1);

        assertEq(erc1155token.balanceOf(address(wallet), 1237), 1);
        assertEq(erc1155token.balanceOf(address(to), 1237), 0);
    }

    function testIsValidSignature() public {
        bytes32 messageHash = keccak256(abi.encode("Signed Message"));
        bytes memory signature = createSignature2(messageHash, ownerPrivateKey, vm);

        bool _sigValid = signatureChecker.isValidSignatureNow(
            address(wallet),
            ECDSA.toEthSignedMessageHash(messageHash),
            signature
        );

        assertEq(_sigValid, true);
    }

    function testIsValidSignatureNotOwner() public {
        // address notContractOwnerAddress = 0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f; // envil account (8)
        uint256 notContractOwnerPrivateKey =
            uint256(0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97);
        bytes32 messageHash = keccak256(abi.encode("Signed Message"));

        bytes memory signature = createSignature2(messageHash, notContractOwnerPrivateKey, vm);

        bool _sigValid = signatureChecker.isValidSignatureNow(
            address(wallet),
            ECDSA.toEthSignedMessageHash(messageHash),
            signature
        );

        assertEq(_sigValid, false);
    }
}