// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "lib/forge-std/src/console.sol";

/// @title Social Recovery - Allows to replace an owner if guardians approve the replacement
contract SocialRecovery {
    /// @dev Required number of guardians to confirm recovery
    uint256 public threshold; //uint16
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

    error InvalidThreshold();

    /// @dev Reverts when zero address is assigned for guardian
    error ZeroAddressForGuardianProvided();

    error DuplicateGuardianProvided();

    error RecoveryAlreadyExecuted();

    error RecoveryNotEnoughConfirmations();

    error OwnershipTransferredFailed();

    modifier onlyGuardian() {
        console.log("modifier onlyGuardian msg.sender", msg.sender);
        if (!isGuardian[msg.sender]) revert InvalidGuardian();
        _;
    }

    /// @dev Lets the owner add a guardian for its wallet
    /// @param _guardians List of guardians' addresses
    /// @param _threshold Required number of guardians to confirm replacement
    function _addGuardianWithThreshold(address[] calldata _guardians, uint256 _threshold) internal {
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

        // emit event
    }

    /// @dev Allows a guardian to confirm a recovery transaction
    /// @param dataHash transaction hash
    function confirmRecovery(bytes32 dataHash) public onlyGuardian {
        if (isExecuted[dataHash]) revert RecoveryAlreadyExecuted();
        isConfirmed[dataHash][msg.sender] = true;
    }


    /// @notice Lets the guardians execute the recovery request
    /// @param newOwner The new owner address
    function executeRecovery(address newOwner) public onlyGuardian {
        bytes memory data = abi.encodeWithSignature("transferOwnershipAfterRecovery(address)", newOwner);
        bytes32 dataHash = getDataHash(data);
        if (isExecuted[dataHash]) revert RecoveryAlreadyExecuted();
        if (!isConfirmedByRequiredGuardians(dataHash)) revert RecoveryNotEnoughConfirmations();
        isExecuted[dataHash] = true;
        (bool req, ) = (address(this)).call(abi.encodeWithSignature("transferOwnershipAfterRecovery(address)", newOwner));
        if (!req) revert OwnershipTransferredFailed();

        // transferOwnershipAfterRecovery(newOwner);
    }

    /// @dev Returns true if confirmation count is enough
    /// @param dataHash Data hash
    /// @return Confirmation status
    function isConfirmedByRequiredGuardians(bytes32 dataHash) public view returns (bool) {
        uint256 confirmationCount;
        uint256 guardiansSize = guardiansCount();
        unchecked {
            for (uint256 i; i < guardiansSize; i++) {
                if (isConfirmed[dataHash][guardians[i]])
                    confirmationCount++;
                if (confirmationCount == threshold)
                    return true;
            }
            return false;            
        }
    }

    /// @dev Returns hash of data encoding owner replacement
    /// @param data Data payload
    /// @return Data hash
    function getDataHash(bytes memory data) public pure returns (bytes32) {
        return keccak256(data);
    }

    /// @dev Returns the number of guardians for a wallet
    function guardiansCount() public view returns (uint256) {
        return guardians.length;
    }

}