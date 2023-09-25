// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.19;

interface IModuleManager {
    /// @dev Emitted when a new module is added.
    event ModuleAdded(address indexed module);
    /// @dev Emitted when a module is removed.
    event ModuleRemoved(address indexed module);
    /// @dev Emitted when a module is removed with an error.
    event ModuleRemovedWithError(address indexed module);

    /// @notice Adds a new module to the wallet.
    /// @dev Can only be called by the module.
    /// @dev Modules should be stored as a linked list.
    /// @param moduleAndData Encoded module to be added and its associated initialization data.
    function addModule(bytes calldata moduleAndData) external;

    /// @notice Removes a module from the wallet.
    /// @dev Can only be called by the module.
    /// @param module Address of the module to be removed.
    function removeModule(address module) external;

    /// @notice Checks if a module is authorized.
    /// @param module Address of the module to check.
    /// @return true if the module is authorized, false otherwise.
    function isAuthorizedModule(address module) external view returns (bool);

    /// @notice Returns the list of added modules and their supported function selectors.
    /// @return modules An array of the addresses of the added modules.
    /// @return selectors A two-dimensional array containing the lists of supported function selectors for the corresponding modules.
    function listModules() external view returns (address[] memory modules, bytes4[][] memory selectors);

    /// @dev Allows a Module to execute a transaction.
    /// @notice Can only be called by a added module.
    /// @param dest Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    function executeFromModule(address dest, uint256 value, bytes calldata data) external;
}