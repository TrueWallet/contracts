// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {IAccount} from "./interfaces/IAccount.sol";
import {UserOperation} from "./UserOperation.sol";
import {ECDSA} from "openzeppelin-contracts/utils/cryptography/ECDSA.sol";

/// @notice TrueWallet - Smart contract wallet compatible with ERC-4337

// Wallet features:
// 1. Updateable entrypoint
// 2. Nonce for replay detection
// 3. ECDSA for signature validation
contract TrueWallet is IAccount {
    /// @notice EntryPoint contract in ERC-4337 system
    address public entryPoint;

    /// @notice Nonce used for replay protection
    uint96 public nonce;
    address public owner;

    /////////////////  EVENTS ///////////////

    event UpdateEntryPoint(
        address indexed newEntryPoint,
        address indexed oldEntryPoint
    );
    event OwnershipTransferred(
        address indexed sender,
        address indexed newOwner
    );

    /////////////////  MODIFIERS ///////////////

    /// @notice Validate that only the entryPoint or Owner is able to call a method
    modifier onlyEntryPointOrOwner() {
        if (msg.sender != address(entryPoint) && msg.sender != owner) {
            revert InvalidEntryPointOrOwner();
        }
        _;
    }

    modifier onlyOwner() {
        // directly from EOA owner, or through the account itself (which gets redirected through execute())
        if (msg.sender != owner && msg.sender != address(this)) {
            revert InvalidOwner();
        }
        _;
    }

    /////////////////  ERRORS ///////////////

    /// @dev Reverts in case not valid entryPoint or owner
    error InvalidEntryPointOrOwner();

    /// @dev Reverts in case not valid owner
    error InvalidOwner();

    /// @dev Reverts when zero address is assigned
    error ZeroAddressProvided();

    /// @dev Reverts when array argument size mismatch
    error LengthMismatch();

    /// @dev Reverts in case not valid signature
    error InvalidSignature();

    /////////////////  CONSTRUCTOR ///////////////

    constructor(address _entryPoint, address _owner) {
        if (_entryPoint == address(0) || _owner == address(0)) {
            revert ZeroAddressProvided();
        }
        entryPoint = _entryPoint;
        owner = _owner;
    }

    /////////////////  FUNCTIONS ///////////////

    /// @notice Able to receive ETH
    receive() external payable {}

    /// @notice Set the entrypoint contract, restricted to onlyOwner
    function setEntryPoint(address _newEntryPoint) external onlyOwner {
        if (_newEntryPoint == address(0)) revert ZeroAddressProvided();
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
    ) external override onlyEntryPointOrOwner returns (uint256 deadline) {
        // Validate signature
        // _validateSignature(userOp, userOpHash);  // TBD: signature creator

        // Validate and update the nonce storage variable - protect against replay attacks
        require(nonce++ == userOp.nonce, "TrueWallet: Invalid nonce");
    }

    /// @notice Method called by entryPoint or owner to execute the calldata supplied by a wallet
    /// @param target - Address to send calldata payload for execution
    /// @param value - Amount of ETH to forward to target
    /// @param payload - Calldata to send to target for execution
    function execute(
        address target,
        uint256 value,
        bytes calldata payload
    ) external onlyEntryPointOrOwner {
        _call(target, value, payload);
    }

    /// @notice Execute a sequence of transactions, called directly by owner or by entryPoint
    function executeBatch(
        address[] calldata target,
        bytes[] calldata payload
    ) external onlyEntryPointOrOwner {
        if (target.length != payload.length) revert LengthMismatch();
        for (uint256 i; i < target.length; ) {
            _call(target[i], 0, payload[i]);
            unchecked {
                i++;
            }
        }
    }

    /// @notice Transfer ownership by owner
    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;
        emit OwnershipTransferred(msg.sender, newOwner);
    }

    /////////////////  INTERNAL METHODS ///////////////

    /// @notice Validate the signature of the userOperation
    function _validateSignature(
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) internal view {
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(userOpHash);
        address signer = ECDSA.recover(messageHash, userOp.signature);
        if (signer != owner) revert InvalidSignature();
        // require(signer == owner, "TrueWallet: Invalid signature");
    }

    /// @notice Perform and validate the function call
    function _call(address target, uint256 value, bytes memory data) internal {
        (bool success, bytes memory result) = target.call{value: value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }
}