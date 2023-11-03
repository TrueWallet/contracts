// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.19;

/// @title IOwnerManager
/// @notice Interface for managing ownership in a contract
interface IOwnerManager {
    /// @dev Emitted when a new owner is added
    /// @param owner Address of the new owner added
    event OwnerAdded(address indexed owner);

    /// @dev Emitted when an existing owner is removed
    /// @param owner Address of the owner removed
    event OwnerRemoved(address indexed owner);

    /// @dev Emitted when all owners are cleared and reset
    event OwnerCleared();

    /// @notice Checks if the given address is an owner
    /// @param addr Address to be checked
    /// @return bool Returns true if the address is an owner, otherwise false
    function isOwner(address addr) external view returns (bool);

    /// @notice Adds a single owner to the contract
    /// @param owner Address of the new owner to be added
    function addOwner(address owner) external;

    /// @notice Adds multiple owners to the contract
    /// @param owners Array of addresses of the new owners to be added
    function addOwners(address[] calldata owners) external;

    /// @notice Resets the ownership of the contract to a single owner
    /// @param newOwner Address of the new owner
    function resetOwner(address newOwner) external;

    /// @notice Resets the ownership of the contract to multiple owners
    /// @param newOwners Array of addresses to set as the new owners
    function resetOwners(address[] calldata newOwners) external;

    /// @notice Removes a specific owner from the contract
    /// @param owner Address of the owner to be removed
    function removeOwner(address owner) external;

    /// @notice Returns a list of all owners
    /// @return owners Array of owner addresses
    function listOwner() external returns (address[] memory owners);
}