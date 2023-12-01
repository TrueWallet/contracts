// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {IAccount} from "account-abstraction/interfaces/IAccount.sol";
import {UserOperation} from "account-abstraction/interfaces/UserOperation.sol";
import {IModuleManager} from "../interfaces/IModuleManager.sol";
import {IOwnerManager} from "src/interfaces/IOwnerManager.sol";

/// @title IWallet
/// @notice Interface for a smart wallet contract, providing functionalities like executing transactions, managing nonce, and validating signatures.
interface IWallet is IAccount, IModuleManager, IOwnerManager {
    /**
    * @notice Retrieves the address of the EntryPoint connected to the wallet.
    * @return The address of the EntryPoint contract.
    */
    function entryPoint() external view returns (address);

    /**
    * @notice Gets the current nonce of the wallet.
    * @return The current nonce value.
    */
    function nonce() external view returns (uint256);

    /**
    * @notice Executes a single user operation.
    * @param target The address of the contract to be called.
    * @param value The amount of Ether to send with the call.
    * @param payload The calldata for the operation.
    */
    function execute(
        address target,
        uint256 value,
        bytes calldata payload
    ) external;

    /**
    * @notice Executes a batch of user operations.
    * @param target An array of addresses of the contracts to be called.
    * @param value An array of amounts of Ether to send with each call.
    * @param payload An array of call data for each operation.
    */
    function executeBatch(
        address[] calldata target,
        uint256[] calldata value,
        bytes[] calldata payload
    ) external;

    /**
    * @notice Verifies if a given signature is valid for a given message hash.
    * @param messageHash The hash of the message that was signed.
    * @param signature The signature to validate.
    * @return Returns `bytes4(0x1626ba7e)` if the signature is valid, otherwise reverts.
    */
    function isValidSignature(
        bytes32 messageHash,
        bytes memory signature
    ) external view returns (bytes4);
}
