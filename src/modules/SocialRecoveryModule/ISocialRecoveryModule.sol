// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.19;

/// @title Interface for Social Recovery Module.
/// @notice This contract allows wallet owners to set guardians for their wallets
/// and use these guardians for recovery purposes.

struct GuardianInfo {
    mapping(address => address) guardians; // Address of guardians mapped to associated accounts or other guardians
    uint256 threshold; // Minimum number of guardians required for recovery
    bytes32 guardianHash; // Hash related to the guardians for verification purposes
}

struct PendingGuardianEntry {
    uint256 pendingUntil; // Timestamp when the pending guardians will become active
    uint256 threshold; // Minimum number of guardians required for recovery
    bytes32 guardianHash; // Hash related to the guardians for verification purposes
    address[] guardians; // List of guardian addresses that are pending approval
}

struct RecoveryEntry {
    address[] newOwners; // New owners of the wallet after recovery
    uint256 executeAfter; // Timestamp when the recovery process can be executed
    uint256 nonce; // Unique nonce to ensure each recovery process is unique
}

/// @dev If a user is already in a recovery process, they cannot change guardians.
/// If a user starts the recovery process while guardians are being changed, the change of guardians will be canceled.

interface ISocialRecoveryModule {
    /// @dev Throws when an operation is attempted by an unauthorized entity.
    error SocialRecovery__Unauthorized();

    /// @dev Throws when an operation related to an ongoing recovery is attempted, but no recovery is in progress.
    error SocialRecovery__NoOngoingRecovery();

    /// @dev Throws when an operation that requires no ongoing recovery is attempted, but a recovery is currently in progress.
    error SocialRecovery__OngoingRecovery();

    /// @dev Throws when there's an attempt to set an anonymous guardian alongside an on-chain guardian.
    error SocialRecovery__OnchainGuardianConfigError();

    /// @dev Throws when there's a configuration error related to anonymous guardians.
    error SocialRecovery__AnonymousGuardianConfigError();

    /// @dev Throws when the threshold is not within the valid range.
    error SocialRecovery__InvalidThreshold();

    /// @dev Throws when no pending guardian is set.
    error SocialRecovery__NoPendingGuardian();

    /// @notice Emitted when guardians for a wallet are revealed without disclosing their identity
    event AnonymousGuardianRevealed(address indexed wallet, address[] indexed guardians, bytes32 guardianHash);

    /// @notice Emitted when a guardian approves a recovery
    event ApproveRecovery(address indexed wallet, address indexed guardian, bytes32 indexed recoveryHash);

    /// @notice Indicates a recovery process is pending and waiting for approval or execution
    event PendingRecovery(address indexed wallet, address[] indexed newOwners, uint256 nonce, uint256 executeAfter);

    /// @notice Indicates a recovery process has been executed successfully
    event SocialRecovery(address indexed wallet, address[] indexed newOwners);

    /// @notice Indicates a recovery process has been canceled
    event SocialRecoveryCanceled(address indexed wallet, uint256 nonce);

    /// @notice Fetch the guardians set for a given wallet
    /// @param wallet The address of the wallet for which guardians are being fetched
    /// @return An array of guardian addresses
    function getGuardians(address wallet) external returns (address[] memory);

    /// @dev Begin the process of updating guardians. The change becomes effective after 2 days.
    /// @notice Begin the process to update guardians, changes are effective after a waiting period
    /// @param guardians List of new guardian addresses
    /// @param threshold The new threshold of guardians required
    /// @param guardianHash Hash related to the new set of guardians
    function updateGuardians(address[] calldata guardians, uint256 threshold, bytes32 guardianHash) external;

    /// @notice Cancel the process of updating guardians
    /// @param wallet The address of the wallet for which the process is being canceled
    function cancelSetGuardians(address wallet) external; // owner or guardian

    /// @notice A single guardian approves the recovery process
    /// @param wallet The address of the wallet being recovered
    /// @param newOwners The new owner(s) of the wallet post recovery
    function approveRecovery(address wallet, address[] calldata newOwners) external;

    /// @dev A function where multiple guardians can approve a recovery.
    /// If over half the guardians confirm, there's a 2-day waiting period.
    /// If all guardians confirm, the recovery is executed immediately.
    /// @notice Multiple guardians approve a recovery process
    /// @param wallet The address of the wallet being recovered
    /// @param newOwner The new owner(s) of the wallet post recovery
    /// @param signatureCount The count of signatures from guardians
    /// @param signatures The actual signatures from the guardians
    function batchApproveRecovery(
        address wallet,
        address[] calldata newOwner,
        uint256 signatureCount,
        bytes memory signatures
    ) external;

    /// @notice Execute the recovery process for a wallet
    /// @param wallet The address of the wallet being recovered
    function executeRecovery(address wallet) external;

    /// @notice Cancel an ongoing recovery process for a wallet
    /// @param wallet The address of the wallet for which the recovery process is being canceled
    function cancelRecovery(address wallet) external;
}
