// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {AccountStorage} from "src/utils/AccountStorage.sol";

import "forge-std/console.sol";

/// @title Social Recovery - Allows to replace an owner if guardians approve the replacement
contract SocialRecovery {
    /// @notice All state variables are stored in AccountStorage.Layout with specific storage slot to avoid storage collision
    using AccountStorage for AccountStorage.Layout;

    /// @dev Required number of guardians to confirm recovery
    uint256 public threshold;
    /// @dev The list of guardians addresses
    address[] public guardians;

    /// @dev isGuardian mapping maps guardian's address to guardian status
    mapping (address => bool) public isGuardian;
    /// @dev isExecuted mapping maps data hash to execution status
    mapping (bytes32 => bool) public isExecuted;
    /// @dev isConfirmed mapping maps data hash to guardian's address to confirmation status
    mapping (bytes32 => mapping (address => bool)) public isConfirmed;

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
        if (!isGuardian[msg.sender]) revert InvalidGuardian();
        _;
    }

    /// @notice Allows a guardian to confirm a recovery transaction
    /// @param recoveryHash transaction hash
    function confirmRecovery(bytes32 recoveryHash) public onlyGuardian {
        if (isExecuted[recoveryHash]) revert RecoveryAlreadyExecuted();
        isConfirmed[recoveryHash][msg.sender] = true;
    }

    /// @notice Lets the guardians execute the recovery request
    /// @param newOwner The new owner address
    function executeRecovery(address newOwner) public onlyGuardian {
        bytes32 recoveryHash = getRecoveryHash(guardians, newOwner, threshold, _getWalletNonce());
        if (isExecuted[recoveryHash] == true) revert RecoveryAlreadyExecuted();
        if (!isConfirmedByRequiredGuardians(recoveryHash)) revert RecoveryNotEnoughConfirmations();
        isExecuted[recoveryHash] = true;
        _transferOwnership(newOwner);
    }

    /// @dev Lets the owner add a guardian for its wallet
    /// @param _guardians List of guardians' addresses
    /// @param _threshold Required number of guardians to confirm replacement
    function _setGuardianWithThreshold(address[] calldata _guardians, uint256 _threshold) internal {
        // if (_threshold <= _guardians.length);
        if (_threshold == 0) revert InvalidThreshold(); // _threshold >= 2
        uint256 guardiansSize = _guardians.length;
        for (uint256 i; i < guardiansSize; ) {
            address guardian = _guardians[i];
            if (guardian == address(0)) revert ZeroAddressForGuardianProvided();
            if (isGuardian[guardian]) revert DuplicateGuardianProvided();
            isGuardian[guardian] = true;
            unchecked {
                i++;
            }
        }
        guardians = _guardians;
        threshold = _threshold;

        emit GuardianSet(guardians, threshold);
    }

    /// @dev Transfer ownership once recovery requiest is completed successfully
    function _transferOwnership(address newOwner) internal {
        AccountStorage.Layout storage layout = AccountStorage.layout();
        layout.owner = newOwner;
        emit OwnershipRecovered(msg.sender, newOwner);
    }

    /// @dev Get wallet's nonce
    function _getWalletNonce() internal returns (uint256) {
        return AccountStorage.layout().nonce;
    }

    /// @dev Returns true if confirmation count is enough
    /// @param recoveryHash Data hash
    /// @return Confirmation status
    function isConfirmedByRequiredGuardians(bytes32 recoveryHash) public view returns (bool) {
        uint256 confirmationCount;
        uint256 guardiansSize = guardiansCount();
        unchecked {
            for (uint256 i; i < guardiansSize; i++) {
                if (isConfirmed[recoveryHash][guardians[i]])
                    confirmationCount++;
                if (confirmationCount == threshold)
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

    /// @dev Returns the number of guardians for a wallet
    function guardiansCount() public view returns (uint256) {
        return guardians.length;
    }
}