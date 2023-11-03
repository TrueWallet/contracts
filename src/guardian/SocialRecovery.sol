// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {AccountStorage} from "src/utils/AccountStorage.sol";
import {SocialRecoveryErrors} from "../common/Errors.sol";

/// @title Social Recovery - Allows to replace an owner if guardians approve the replacement
/// In this early version, recovery is possible to make at least by only one guardian
contract SocialRecovery is SocialRecoveryErrors {
    /// @notice All state variables are stored in AccountStorage.Layout with specific storage slot to avoid storage collision
    using AccountStorage for AccountStorage.Layout;

    /// @dev Recovery period after which recovery could be executed
    uint256 public constant RECOVERY_PERIOD = 2 days;

    /// @dev Emitted when guardians and threshold are added
    event GuardianAdded(address[] indexed guardians, uint16 threshold);
    /// @dev Emitted when guardian is revoked
    event GuardianRevoked(address indexed guardian);
    /// @dev Emitted when recovery is confirmed by guardian
    event RecoveryConfirmed(
        address indexed guardian,
        bytes32 indexed recoveryHash
    );
    /// @dev Emitted when recovery is executed by guardian
    event RecoveryExecuted(
        address indexed guardian,
        bytes32 indexed recoveryHash
    );
    /// @dev Emmited when recovey is canceled by owner
    event RecoveryCanceled(bytes32 recoveryHash);
    /// @dev Emitted when ownership is transfered after recovery execution
    event OwnershipRecovered(address indexed sender, address indexed newOwner);

    /// @dev Only guardian modifier
    modifier onlyGuardian() {
        if (!isGuardian(msg.sender)) revert InvalidGuardian();
        _;
    }

    /// @notice Allows a guardian to confirm a recovery transaction
    /// First call of this method initiate the recovery process
    /// @param recoveryHash transaction hash
    function confirmRecovery(bytes32 recoveryHash) public onlyGuardian {
        AccountStorage.Layout storage layout = AccountStorage.layout();
        if (layout.isExecuted[recoveryHash]) revert RecoveryAlreadyExecuted();
        layout.isConfirmed[recoveryHash][msg.sender] = true;
        layout.executeAfter = uint64(block.timestamp + RECOVERY_PERIOD);
        emit RecoveryConfirmed(msg.sender, recoveryHash);
    }

    /// @notice Lets the guardians execute the recovery request
    /// This method should be called once current recoveryHash is gathered all required count of confirmations
    /// @param newOwner The new owner address
    function executeRecovery(address newOwner) public onlyGuardian {
        AccountStorage.Layout storage layout = AccountStorage.layout();
        if (uint64(block.timestamp) < layout.executeAfter)
            revert RecoveryPeriodStillPending();
        bytes32 recoveryHash = getRecoveryHash(
            layout.guardians,
            newOwner,
            layout.threshold,
            _getWalletNonce()
        );
        if (layout.isExecuted[recoveryHash] == true)
            revert RecoveryAlreadyExecuted();
        if (!isConfirmedByRequiredGuardians(recoveryHash))
            revert RecoveryNotEnoughConfirmations();
        layout.isExecuted[recoveryHash] = true;
        layout.executeAfter = 0;
        _transferOwnership(newOwner);

        emit RecoveryExecuted(msg.sender, recoveryHash);
    }

    /// @dev Lets the owner add a guardian for its wallet
    /// @param _guardians List of guardians' addresses
    /// @param _threshold Required number of guardians to confirm replacement
    function _addGuardianWithThreshold(
        address[] calldata _guardians,
        uint16 _threshold
    ) internal {
        AccountStorage.Layout storage layout = AccountStorage.layout();
        if (_threshold > _guardians.length) revert InvalidThreshold();
        if (_threshold == 0) revert InvalidThreshold();
        uint256 guardiansSize = _guardians.length;
        for (uint256 i; i < guardiansSize; ) {
            address guardian = _guardians[i];
            if (guardian == address(0)) revert ZeroAddressForGuardianProvided();
            if (layout.isGuardian[guardian]) revert DuplicateGuardianProvided();
            layout.isGuardian[guardian] = true;
            unchecked {
                i++;
            }
        }
        layout.guardians = _guardians;
        layout.threshold = _threshold;

        emit GuardianAdded(_guardians, _threshold);
    }

    /// @notice Lets the owner revoke a guardian from the wallet
    /// @param _guardian The guardian address to revoke
    /// @param _threshold The new required number of guardians to confirm replacement
    function _revokeGuardianWithThreshold(
        address _guardian,
        uint16 _threshold
    ) internal {
        if (!isGuardian(_guardian)) revert InvalidGuardian();
        address[] storage guardians = AccountStorage.layout().guardians;
        uint256 guardiansSize = guardiansCount();
        if (_threshold > guardiansSize - 1) revert InvalidThreshold();
        uint256 index;
        unchecked {
            for (uint256 i; i < guardiansSize; i++) {
                if (guardians[i] == _guardian) {
                    index = i;
                    break;
                }
            }
            if (index == guardiansSize - 1) {
                guardians.pop();
            } else {
                for (uint256 j = index; j < guardiansSize - 1; j++) {
                    guardians[j] = guardians[j + 1];
                }
                guardians.pop();
            }
        }
        AccountStorage.layout().isGuardian[_guardian] = false;

        emit GuardianRevoked(_guardian);
    }

    /// @dev Transfer ownership once recovery requiest is completed successfully
    function _transferOwnership(address newOwner) internal {
        AccountStorage.Layout storage layout = AccountStorage.layout();
        layout.owner = newOwner;
        emit OwnershipRecovered(msg.sender, newOwner);
    }

    /// @dev Get wallet's nonce
    function _getWalletNonce() internal view returns (uint256) {
        AccountStorage.Layout storage layout = AccountStorage.layout();
        return (layout.entryPoint).getNonce(address(this), 0);
    }

    /// @notice Lets the owner cancel an ongoing recovery request
    /// @param recoveryHash hash of recovery requiest that is already initiated
    function cancelRecovery(bytes32 recoveryHash) public {
        AccountStorage.Layout storage layout = AccountStorage.layout();
        if (msg.sender != layout.owner) revert InvalidOwner();
        if (layout.executeAfter == 0) revert RecoveryNotInitiated();
        layout.isExecuted[recoveryHash] = true;
        layout.executeAfter = 0;
        emit RecoveryCanceled(recoveryHash);
    }

    /// @dev Returns true if confirmation count is enough
    /// @param recoveryHash Data hash
    /// @return confirmation status
    function isConfirmedByRequiredGuardians(
        bytes32 recoveryHash
    ) public view returns (bool) {
        AccountStorage.Layout storage layout = AccountStorage.layout();
        uint256 confirmationCount;
        uint256 guardiansSize = guardiansCount();
        unchecked {
            for (uint256 i; i < guardiansSize; i++) {
                if (layout.isConfirmed[recoveryHash][layout.guardians[i]])
                    confirmationCount++;
                if (confirmationCount == layout.threshold) return true;
            }
            return false;
        }
    }

    /// @dev Returns the bytes that are hashed
    function encodeRecoveryData(
        address[] memory _guardians,
        address _newOwner,
        uint16 _threshold,
        uint256 _nonce
    ) public pure returns (bytes memory) {
        bytes32 recoveryHash = keccak256(
            abi.encode(
                keccak256(abi.encodePacked(_guardians)),
                _newOwner,
                _threshold,
                _nonce
            )
        );
        return abi.encodePacked(bytes1(0x19), bytes1(0x01), recoveryHash);
    }

    /// @dev Generates the recovery hash that could be signed by the guardian to authorize a recovery
    /// @return recoveryHash of data encoding owner replacement
    function getRecoveryHash(
        address[] memory _guardians,
        address _newOwner,
        uint16 _threshold,
        uint256 _nonce
    ) public pure returns (bytes32) {
        return
            keccak256(
                encodeRecoveryData(_guardians, _newOwner, _threshold, _nonce)
            );
    }

    /// @dev Execute recovery after this period
    function executeAfter() public view returns (uint64) {
        return AccountStorage.layout().executeAfter;
    }

    /// @dev Retrieves the wallet threshold count. Required number of guardians to confirm recovery
    function threshold() public view returns (uint16) {
        return AccountStorage.layout().threshold;
    }

    /// @dev Gets the list of guaridans addresses
    function getGuardians() public view returns (address[] memory) {
        return AccountStorage.layout().guardians;
    }

    /// @dev Returns the number of guardians for a wallet
    function guardiansCount() public view returns (uint256) {
        return AccountStorage.layout().guardians.length;
    }

    /// @dev Checks if an account is a guardian for a wallet
    function isGuardian(address guardian) public view returns (bool) {
        return AccountStorage.layout().isGuardian[guardian];
    }

    function isConfirmedByGuardian(
        address guardian,
        bytes32 recoveryHash
    ) public view returns (bool) {
        return AccountStorage.layout().isConfirmed[recoveryHash][guardian];
    }

    /// @dev Checks if a recoveryHash is executed
    function isExecuted(bytes32 recoveryHash) public view returns (bool) {
        return AccountStorage.layout().isExecuted[recoveryHash];
    }
}
