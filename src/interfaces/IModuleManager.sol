// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.19;

interface IModuleManager {
    event ModuleAdded(address indexed module);
    event ModuleRemoved(address indexed module);
    event ModuleRemovedWithError(address indexed module);

    /// @dev Adds a module to the wallet.
    /// @notice Can only be called by the module.
    /// @notice Modules should be stored as a linked list.
    /// @notice Must emit `ModuleAdded(address indexed module)` if successful.
    /// @param module Module to be added.
    function addModule(address module) external;

    /// @dev Removes a module from the wallet.
    /// @notice Can only be called by the module.
    /// @notice Must emit `ModuleRemoved(address indexed module)` if successful.
    /// @param module Module to be removed.
    function removeModule(address module) external;

    /// @dev Returns if module is added.
    function isAuthorizedModule(address module) external view returns (bool);

    /// @dev Returns the list of modules.
    function listModules() external view returns (address[] memory modules);

    /// @dev Allows a Module to execute a transaction.
    /// @notice Can only be called by a added module.
    /// @param dest Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    function executeFromModule(address dest, uint256 value, bytes calldata data) external;
}