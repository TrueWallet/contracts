// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {IWallet} from "./IWallet.sol";
import {UserOperation} from "./UserOperation.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {ECDSA} from "openzeppelin-contracts/utils/cryptography/ECDSA.sol";

/// @notice TrueWallet - Smart contract wallet compatible with ERC-4337

// Wallet features:
// 1. Updateable entrypoint
// 2. Nonce for replay detection
// 3. ECDSA for signature validation
contract TrueWallet is IWallet, Owned {

    event UpdateEntryPoint(address indexed _newEntryPoint, address indexed _oldEntryPoint);

    /// @notice Constant ENTRY_POINT contract in ERC-4337 system
    address public entryPoint;

    /// @notice Nonce used for replay protection
    uint256 public nonce;


    /// @notice Able to receive ETH
    receive() external payable {}

    constructor(address _entryPoint) Owned(msg.sender) {
        entryPoint = _entryPoint;
    }



    /// @notice Set the entrypoint contract, restricted to onlyOwner
    function setEntryPoint(address _newEntryPoint) external onlyOwner {
        entryPoint = _newEntryPoint;
        emit UpdateEntryPoint(_newEntryPoint, entryPoint);
    }

    /// @notice Validate that the userOperation is valid. Requirements:
    // 1. Only calleable by EntryPoint
    // 2. Signature is that of the contract owner
    // 3. Nonce is correct
    /// @param userOp - ERC-4337 User Operation
    /// @param userOpHash - Hash of the user operation, entryPoint address and chainId
    /// @param aggregator - Signature aggregator
    /// @param missingWalletFunds - Amount of ETH to pay the EntryPoint for processing the transaction
    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        address aggregator,
        uint256 missingWalletFunds
    ) external override returns (uint256 deadline) {
        // Ensure the request comes from the known entrypoint
         _requireFromEntryPoint();
        // Validate signature
        _validateSignature(userOp, userOpHash);
        // Validate nonce is correct - protect against replay attacks
        _validateAndUpdateNonce(userOp);
    }

    /// @notice Method called by entryPoint or owner to execute the calldata supplied by a wallet
    /// @param target - Address to send calldata payload for execution
    /// @param value - Amount of ETH to forward to target
    /// @param payload - Calldata to send to target for execution
    function execute(address target, uint256 value, bytes calldata payload) external {
        _requireFromEntryPointOrOwner();
        _call(target, value, payload);
    }

    /// @notice Execute a sequence of transactions, called directly by owner or by entryPoint
    function executeBatch(address[] calldata target, bytes[] calldata payload) external {
        _requireFromEntryPointOrOwner();
        require(target.length == payload.length, "TrueWallet: Wrong array length");
        for (uint256 i; i < target.length; ) {
            _call(target[i], 0, payload[i]);
            unchecked { i++; }
        }
    }


    /////////////////  INTERNAL METHODS ///////////////
    

    /// @notice Validate that only the entryPoint or Owner is able to call a method
    function _requireFromEntryPointOrOwner() internal view {
        require(msg.sender == address(entryPoint) || msg.sender == owner, "TrueWallet: Only entryPoint or owner can call this method");
    }

    /// @notice Validate that only the entryPoint is able to call a method
    function _requireFromEntryPoint() internal view {
        require(msg.sender == address(entryPoint), "TrueWallet: Only entryPoint can call this method");
    }

    /// @notice Validate the signature of the userOperation
    function _validateSignature(UserOperation calldata userOp, bytes32 userOpHash) internal view {
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(userOpHash);
        address signer = ECDSA.recover(messageHash, userOp.signature);
        require(signer == owner, "TrueWallet: Invalid signature");
    }

    /// @notice Validate and update the nonce storage variable
    function _validateAndUpdateNonce(UserOperation calldata userOp) internal {
        require(nonce++ == userOp.nonce, "TrueWallet: Invalid nonce");
    }

    /// @notice Perform and validate the function call
    function _call(address target, uint256 value, bytes memory data) internal {
        (bool success, bytes memory result) = target.call{value : value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }
}