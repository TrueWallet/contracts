// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.19;

contract WalletErrors {
    /// @notice Throws when an invalid entry point or owner is provided or detected.
    error InvalidEntryPointOrOwner();

    /// @notice Throws when an address provided is the zero address.
    error ZeroAddressProvided();

    /// @notice Throws when an invalid delay is provided for an upgrade.
    error InvalidUpgradeDelay();

    /// @notice Throws when the lengths of two comparable arrays or sets of data do not match.
    error LengthMismatch();

    /// @notice Throws when a provided signature is not valid.
    error InvalidSignature();
}

contract SocialRecoveryErrors {
    /// @notice Throws when an invalid owner address is provided or detected.
    error InvalidOwner();

    /// @notice Throws when an invalid guardian address is provided or detected.
    error InvalidGuardian();

    /// @notice Throws when an invalid threshold value is provided or detected.
    error InvalidThreshold();

    /// @notice Throws when a zero address is provided where a guardian address is required.
    error ZeroAddressForGuardianProvided();

    /// @notice Throws when a duplicate guardian address is provided.
    error DuplicateGuardianProvided();

    /// @notice Throws when a recovery operation has already been executed.
    error RecoveryAlreadyExecuted();

    /// @notice Throws when there are not enough confirmations for a recovery operation.
    error RecoveryNotEnoughConfirmations();

    /// @notice Throws when the recovery period is still pending.
    error RecoveryPeriodStillPending();

    /// @notice Throws when attempting to execute a recovery operation that has not been initiated.
    error RecoveryNotInitiated();
}

contract UpgradeWalletErrors {
    /// @notice Throws when attempting to perform an upgrade before the delay period has elapsed.
    error UpgradeDelayNotElapsed();
}

contract ModuleManagerErrors {
    /// @notice Throws when the caller of a function must be a module but is not.
    error CallerMustBeModule();

    /// @notice Throws when the address of the module is required but not provided.
    error ModuleAddressEmpty();

    /// @notice Throws when a module tries to recursively call `executeFromModule`.
    error ModuleExecuteFromModuleRecursive();

    /// @notice Throws when a module is not authorized to perform a specific operation.
    error ModuleNotAuthorized();

    /// @notice Throws when a module is already authorized for a specific operation.
    error ModuleAuthorized();

    /// @notice Throws when a module does not support the expected interface.
    error ModuleNotSupportInterface();

    /// @notice Throws when the selectors of a module are required but not provided.
    error ModuleSelectorsEmpty();
}

contract OwnerManagerErrors {
    /// @dev Throws when an operation requires an owner but none exist.
    error OwnerManager__NoOwner();

    /// @dev Throws when the caller must be the contract itself or one of its modules.
    error OwnerManager__CallerMustBeSelfOfModule();
}
