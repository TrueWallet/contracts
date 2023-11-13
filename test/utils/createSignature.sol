// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {Vm} from "forge-std/Test.sol";
import {ECDSA} from "openzeppelin-contracts/utils/cryptography/ECDSA.sol";
import {UserOperation} from "account-abstraction/interfaces/UserOperation.sol";
import {getUserOpHash} from "test/utils/getUserOpHash.sol";

/// @notice Create a signature over a user operation
function createSignature(
    UserOperation memory userOp,
    bytes32 messageHash, // in form of ECDSA.toEthSignedMessageHash
    uint256 ownerPrivateKey,
    Vm vm
) pure returns (bytes memory) {
    (userOp);
    bytes32 digest = ECDSA.toEthSignedMessageHash(messageHash);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);
    bytes memory signature = bytes.concat(r, s, bytes1(v));
    return signature;
}

/// @notice Create a signature for ERC-1271 support
function createSignature2(bytes32 messageHash, uint256 ownerPrivateKey, Vm vm) pure returns (bytes memory) {
    bytes32 digest = ECDSA.toEthSignedMessageHash(messageHash);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);
    bytes memory signature = bytes.concat(r, s, bytes1(v));
    return signature;
}

/// @notice Create a signature with ERC-712 support
function createSignature3(bytes32 messageHash, uint256 ownerPrivateKey, Vm vm) pure returns (bytes memory) {
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, messageHash);
    return abi.encodePacked(r, s, v);
}
