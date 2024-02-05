// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.19;

import {ITrueContractManager} from "src/registry/ITrueContractManager.sol";
import {Ownable} from "solady/auth/Ownable.sol";

/// @title TrueContractManager
/// @notice This contract manages and verifies TrueContract modules
/// @dev It allows the owner to add or remove module contracts and check if a module is registered
contract TrueContractManager is ITrueContractManager, Ownable {
    /// @dev Emitted when an address provided is not a contract
    error TrueContractManager__NotContractProvided();
    /// @dev Emitted when attempting to register an already registered contract
    error TrueContractManager__ContractAlreadyRegistered();
    /// @dev Emitted when attempting to remove a contract that is not registered
    error TrueContractManager__ContractNotRegistered();

    /// @dev Mapping to store registered TrueContract modules
    mapping(address module => bool) private _isTrueModule;

    /// @param _owner The address of the owner of this contract
    constructor(address _owner) {
        _setOwner(_owner);
    }

    /// @notice Adds a list of modules to the registry
    /// @dev Registers multiple module addresses as TrueModules. Permissioned to only the owner
    /// @param modules Array of addresses of the modules to be added
    function add(address[] calldata modules) external onlyOwner {
        for (uint256 i; i < modules.length;) {
            if (modules[i].code.length == 0) {
                revert TrueContractManager__NotContractProvided();
            }
            if (_isTrueModule[modules[i]]) {
                revert TrueContractManager__ContractAlreadyRegistered();
            }
            _isTrueModule[modules[i]] = true;
            emit TrueContractManagerAdded(modules[i]);
            unchecked {
                i++;
            }
        }
    }

    /// @dev Removes a list of modules from the registry. Permissioned to only the owner
    /// @param modules Array of addresses of the modules to be removed
    function remove(address[] calldata modules) external onlyOwner {
        for (uint256 i; i < modules.length;) {
            if (!_isTrueModule[modules[i]]) {
                revert TrueContractManager__ContractNotRegistered();
            }
            _isTrueModule[modules[i]] = false;
            emit TrueContractManagerRemoved(modules[i]);
            unchecked {
                i++;
            }
        }
    }

    /// @notice Checks if the address is a registered TrueModule
    /// @param module Address of the module to be checked
    /// @return bool Returns true if the provided address is a registered module, otherwise false
    function isTrueModule(address module) external view returns (bool) {
        return _isTrueModule[module];
    }
}
