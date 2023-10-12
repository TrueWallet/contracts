// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.19;

/// @title ITrueContractManager
/// @dev Interface to manage and check permissions for TrueContract modules
interface ITrueContractManager {
    /// @dev Emitted when a new module is added
    /// @param module Address of the new module added
    event TrueContractManagerAdded(address indexed module);

    /// @dev Emitted when an existing module is removed
    /// @param module Address of the module removed
    event TrueContractManagerRemoved(address indexed module);

    /// @notice Checks if the address is a true module that is registered in the system
    /// @param module Address of the module to be checked
    /// @return bool Returns true if the provided address is an active registered module, otherwise false
    function isTrueModule(address module) external view returns (bool);
}   