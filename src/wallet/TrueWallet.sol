// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {ECDSA} from "openzeppelin-contracts/utils/cryptography/ECDSA.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {IAccount} from "src/interfaces/IAccount.sol";
import {IEntryPoint} from "src/interfaces/IEntryPoint.sol";
import {UserOperation} from "src/interfaces/UserOperation.sol";
import {DefaultCallbackHandler} from "./DefaultCallbackHandler.sol";

/// @title TrueWallet - Smart contract wallet compatible with ERC-4337
contract TrueWallet is IAccount, DefaultCallbackHandler {
    /// @notice EntryPoint contract in ERC-4337 system
    IEntryPoint public entryPoint;

    /// @notice Nonce used for replay protection
    /// @dev Explicit sizes of nonce, to fit a single storage cell with "owner"
    uint96 public nonce;
    address public owner;

    /////////////////  EVENTS ///////////////

    event UpdateEntryPoint(address indexed newEntryPoint, address indexed oldEntryPoint);
    event PayPrefund(address indexed payee, uint256 amount);
    event OwnershipTransferred(address indexed sender, address indexed newOwner);
    event WithdrawERC20(address token, address indexed to, uint256 amount);
    event WithdrawETH(address indexed to, uint256 amount);

    /////////////////  MODIFIERS ///////////////

    /// @notice Validate that only the entryPoint or Owner is able to call a method
    modifier onlyEntryPointOrOwner() {
        if (msg.sender != address(entryPoint) && msg.sender != owner && msg.sender != address(this)) {
            revert InvalidEntryPointOrOwner();
        }
        _;
    }

    /// @dev Only from EOA owner, or through the account itself (which gets redirected through execute())
    modifier onlyOwner() {
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
        entryPoint = IEntryPoint(_entryPoint);
        owner = _owner;
    }

    /////////////////  FUNCTIONS ///////////////

    /// @notice Able to receive ETH
    receive() external payable {}

    /// @notice Set the entrypoint contract, restricted to onlyOwner
    function setEntryPoint(address _newEntryPoint) external onlyOwner {
        if (_newEntryPoint == address(0)) revert ZeroAddressProvided();
        emit UpdateEntryPoint(_newEntryPoint, address(entryPoint));
        entryPoint = IEntryPoint(_newEntryPoint);
    }

    /// @notice Validate that the userOperation is valid. Requirements:
    // 1. Only calleable by EntryPoint or owner
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
        _validateSignature(userOp, userOpHash);

        // UserOp may have initCode to deploy a wallet, in which case do not validate the nonce. Used in accountCreation
        if (userOp.initCode.length == 0) {
            // Validate and update the nonce storage variable - protect against replay attacks
            require(nonce++ == userOp.nonce, "TrueWallet: Invalid nonce");
        }

        _prefundEntryPoint(missingWalletFunds);
        return 0;
    }

    /// @notice Method called by entryPoint or owner to execute the calldata supplied by a wallet
    /// @param target - Address to send calldata payload for execution
    /// @param value - Amount of ETH to forward to target
    /// @param payload - Calldata to send to target for execution
    function execute(address target, uint256 value, bytes calldata payload) external onlyEntryPointOrOwner {
        _call(target, value, payload);
    }

    /// @notice Execute a sequence of transactions, called directly by owner or by entryPoint
    function executeBatch(address[] calldata target, bytes[] calldata payload) external onlyEntryPointOrOwner {
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

    /////////////////  EMERGENCY RECOVERY ///////////////

    /// @notice Withdraw ERC20 tokens from the wallet. Permissioned to only the owner
    function withdrawERC20(address token, address to, uint256 amount) external onlyOwner {
        SafeTransferLib.safeTransfer(ERC20(token), to, amount);
        emit WithdrawERC20(token, to, amount);
    }

    /// @notice Withdraw ETH from the wallet. Permissioned to only the owner
    function withdrawETH(address payable to, uint256 amount) external onlyOwner {
        SafeTransferLib.safeTransferETH(to, amount);
        emit WithdrawETH(to, amount);
    }

    /////////////////  INTERNAL METHODS ///////////////

    /// @notice Validate the signature of the userOperation
    function _validateSignature(UserOperation calldata userOp, bytes32 userOpHash) internal view {
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(userOpHash);
        address signer = ECDSA.recover(messageHash, userOp.signature);
        if (signer != owner) revert InvalidSignature();
    }

    /// @notice Pay the EntryPoint in ETH ahead of time for the transaction that it will execute
    ///         Amount to pay may be zero, if the entryPoint has sufficient funds or if a paymaster is used
    ///         to pay the entryPoint through other means
    /// @param amount - Amount of ETH to pay the entryPoint
    function _prefundEntryPoint(uint256 amount) internal {
        if (amount == 0) {
            return;
        }

        (bool success, ) = payable(address(entryPoint)).call{value: amount}("");
        require(success, "TrueWallet: ETH entrypoint payment failed");
        emit PayPrefund(address(this), amount);
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

    /// @notice Support ERC165, query if a contract implements an interface
    function supportsInterface(bytes4 _interfaceID) public view override(DefaultCallbackHandler) returns (bool) {
        return supportsInterface(_interfaceID);
    }
}