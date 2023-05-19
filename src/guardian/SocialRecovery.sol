// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {AccountStorage} from "src/utils/AccountStorage.sol";

import "forge-std/console.sol";

/// @title Social Recovery - Allows to replace an owner if guardians approve the replacement
contract SocialRecovery {
    /// @notice All state variables are stored in AccountStorage.Layout with specific storage slot to avoid storage collision
    using AccountStorage for AccountStorage.Layout;

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

    /// @dev Emitted when guardians and threshold are set
    event GuardianSet(address[] indexed guardians, uint256 threshold);
    /// @dev Emitted when ownership is transfered after recovery execution
    event OwnershipRecovered(address indexed sender, address indexed newOwner);

    /// @dev Only guardian modifier
    modifier onlyGuardian() {
        if (!isGuardian(msg.sender)) revert InvalidGuardian();
        _;
    }

    /// @notice Allows a guardian to confirm a recovery transaction
    /// @param recoveryHash transaction hash
    function confirmRecovery(bytes32 recoveryHash) public onlyGuardian {
        AccountStorage.Layout storage layout = AccountStorage.layout();
        if (layout.isExecuted[recoveryHash]) revert RecoveryAlreadyExecuted();
        layout.isConfirmed[recoveryHash][msg.sender] = true;
    }

    /// @notice Lets the guardians execute the recovery request
    /// @param newOwner The new owner address
    function executeRecovery(address newOwner) public onlyGuardian {
        AccountStorage.Layout storage layout = AccountStorage.layout();
        bytes32 recoveryHash = getRecoveryHash(layout.guardians, newOwner, layout.threshold, _getWalletNonce());
        if (layout.isExecuted[recoveryHash] == true) revert RecoveryAlreadyExecuted();
        if (!isConfirmedByRequiredGuardians(recoveryHash)) revert RecoveryNotEnoughConfirmations();
        layout.isExecuted[recoveryHash] = true;
        _transferOwnership(newOwner);
    }

    /// @dev Lets the owner add a guardian for its wallet
    /// @param _guardians List of guardians' addresses
    /// @param _threshold Required number of guardians to confirm replacement
    function _setGuardianWithThreshold(address[] calldata _guardians, uint256 _threshold) internal {
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

        emit GuardianSet(_guardians, _threshold);
    }

    /// @dev Transfer ownership once recovery requiest is completed successfully
    function _transferOwnership(address newOwner) internal {
        AccountStorage.Layout storage layout = AccountStorage.layout();
        layout.owner = newOwner;
        emit OwnershipRecovered(msg.sender, newOwner);
    }

    /// @dev Get wallet's nonce
    function _getWalletNonce() internal returns (uint96) {
        return AccountStorage.layout().nonce;
    }

    /// @dev Returns true if confirmation count is enough
    /// @param recoveryHash Data hash
    /// @return confirmation status
    function isConfirmedByRequiredGuardians(bytes32 recoveryHash) public view returns (bool) {
        AccountStorage.Layout storage layout = AccountStorage.layout();
        uint256 confirmationCount;
        uint256 guardiansSize = guardiansCount();
        unchecked {
            for (uint256 i; i < guardiansSize; i++) {
                if (layout.isConfirmed[recoveryHash][layout.guardians[i]])
                    confirmationCount++;
                if (confirmationCount == layout.threshold)
                    return true;
            }
            return false;            
        }
    }

    /// @dev Returns the bytes that are hashed
    function encodeRecoveryData(
        address[] memory _guardians, 
        address _newOwner,
        uint256 _threshold,
        uint256 _nonce
    ) public view returns (bytes memory) {
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
    function getRecoveryHash(
        address[] memory _guardians, 
        address _newOwner,
        uint256 _threshold,
        uint256 _nonce
    ) public view returns (bytes32) {
        return keccak256(encodeRecoveryData(_guardians, _newOwner, _threshold, _nonce));
    }

    /// @dev Retrieves the wallet threshold count. Required number of guardians to confirm recovery
    function threshold() public view returns (uint256) {
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

    /// @dev Checks if a recoveryHash is executed
    function isExecuted(bytes32 recoveryHash) public view returns (bool) {
        return AccountStorage.layout().isExecuted[recoveryHash];
    }
}