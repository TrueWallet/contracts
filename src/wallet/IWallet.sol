// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {IAccount} from "account-abstraction/interfaces/IAccount.sol";
import {UserOperation} from "account-abstraction/interfaces/UserOperation.sol";

// import {UserOperation} from "src/interfaces/UserOperation.sol";
import {IModuleManager} from "../interfaces/IModuleManager.sol";
import {IOwnerManager} from "src/interfaces/IOwnerManager.sol";

interface IWallet is IAccount, IModuleManager, IOwnerManager {
    // /**
    //  * Validate user's signature and nonce
    //  * the entryPoint will make the call to the recipient only if this validation call returns successfully.
    //  * signature failure should be reported by returning SIG_VALIDATION_FAILED (1).
    //  * This allows making a "simulation call" without a valid signature
    //  * Other failures (e.g. nonce mismatch, or invalid signature format) should still revert to signal failure.
    //  *
    //  * @dev Must validate caller is the entryPoint.
    //  *      Must validate the signature and nonce
    //  * @param userOp the operation that is about to be executed.
    //  * @param userOpHash hash of the user's request data. can be used as the basis for signature.
    //  * @param missingAccountFunds missing funds on the account's deposit in the entrypoint.
    //  *      This is the minimum amount to transfer to the sender(entryPoint) to be able to make the call.
    //  *      The excess is left as a deposit in the entrypoint, for future calls.
    //  *      can be withdrawn anytime using "entryPoint.withdrawTo()"
    //  *      In case there is a paymaster in the request (or the current deposit is high enough), this value will be zero.
    //  * @return validationData packaged ValidationData structure. use `_packValidationData` and `_unpackValidationData` to encode and decode
    //  *      <20-byte> sigAuthorizer - 0 for valid signature, 1 to mark signature failure,
    //  *         otherwise, an address of an "authorizer" contract.
    //  *      <6-byte> validUntil - last timestamp this operation is valid. 0 for "indefinite"
    //  *      <6-byte> validAfter - first timestamp this operation is valid
    //  *      If an account doesn't use time-range, it is enough to return SIG_VALIDATION_FAILED value (1) for signature failure.
    //  *      Note that the validation code cannot use block.timestamp (or block.number) directly.
    //  */
    // function validateUserOp(
    //     UserOperation calldata userOp,
    //     bytes32 userOpHash,
    //     uint256 missingAccountFunds
    // ) external returns (uint256 validationData);

    /// @notice Entrypoint connected to the wallet
    function entryPoint() external view returns (address);

    /// @notice Get the nonce on the wallet
    function nonce() external view returns (uint256);

    /// @notice Method called by the entryPoint to execute a userOperation
    function execute(
        address target,
        uint256 value,
        bytes calldata payload
    ) external;

    /// @notice Method called by the entryPoint to execute a userOperation with a sequence of transactions
    function executeBatch(
        address[] calldata target,
        uint256[] calldata value,
        bytes[] calldata payload
    ) external;

    /// @notice Verifies that the signer is the owner of the signing contract
    function isValidSignature(
        bytes32 messageHash,
        bytes memory signature
    ) external view returns (bytes4);
}
