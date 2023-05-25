// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.17;

contract WalletErrors {
    /// @dev Reverts in case not valid entryPoint or owner
    error InvalidEntryPointOrOwner();

    /// @dev Reverts when zero address is assigned
    error ZeroAddressProvided();

    /// @dev Reverts when upgrade delay is invalid
    error InvalidUpgradeDelay();

    /// @dev Reverts when array argument size mismatch
    error LengthMismatch();

    /// @dev Reverts in case not valid signature
    error InvalidSignature();
}

contract SocialRecoveryErrors {
    /// @dev Reverts in case not valid owner
    error InvalidOwner();

    /// @dev Reverts in case not valid guardian
    error InvalidGuardian();

    /// @dev Reverts in case not valid threshold
    error InvalidThreshold();

    /// @dev Reverts when zero address is assigned for guardian
    error ZeroAddressForGuardianProvided();

    /// @dev Reverts when guardian provided is already in the list
    error DuplicateGuardianProvided();

    /// @dev Reverts when the particular recovery requist is already executed
    error RecoveryAlreadyExecuted();

    /// @dev Reverts when not enough confirmation from guardians for recovery requist
    error RecoveryNotEnoughConfirmations();

    /// @dev Reverts when recovery period is still pending before execution
    error RecoveryPeriodStillPending();

    /// @dev Reverts when no ongoing recovery requiests 
    error RecoveryNotInitiated();
}

contract UpgradeWalletErrors {
    /// @dev Reverts when perform implementation upgrade in an inappropriate activateTime
    error UpgradeDelayNotElapsed();
}