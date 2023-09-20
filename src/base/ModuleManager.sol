// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.19;

import {AccountStorage} from "../utils/AccountStorage.sol";
import {IModuleManager} from "../interfaces/IModuleManager.sol";
import {AddressLinkedList} from "../libraries/AddressLinkedList.sol";
import "../common/Errors.sol";

/// @title Module Manager - A contract that manages modules that can execute transactions
///        on behalf of the Smart Account via this contract.
abstract contract ModuleManager is IModuleManager {
    using AddressLinkedList for mapping(address => address);

    modifier onlyModule() {
        if (_isAuthorizedModule()) {
            revert CALLER_MUST_BE_MODULE();
        }
        _;
    }

    function isAuthoraizedModule(address module) external view returns (bool) {
        return _moduleMapping().isExist(module);
    }

    function addModule(address module) external override onlyModule {
        _addModule(module);
    }

    function removeModule(address module) external override onlyModule {
        mapping(address => address) storage modules = _moduleMapping();
        modules.remove(module);
        emit ModuleRemoved(module);
    }

    function listModules() external view override returns (address[] memory modules) {
        mapping(address => address) storage _modules = _moduleMapping();
        uint256 moduleSize = _moduleMapping().size();
        modules = new address[](moduleSize);
        modules = AddressLinkedList.list(_modules, AddressLinkedList.SENTINEL_ADDRESS, moduleSize);
    }

    function executeFromModule(
        address to,
        uint256 value,
        bytes memory data
    ) external override onlyModule {
        if (to == address(this)) revert MODULE_EXECUTE_FROM_MODULE_RECURSIVE();
        assembly {
            /* not memory-safe */
            let result := call(gas(), to, value, add(data, 0x20), mload(data), 0, 0)
            if iszero(result) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    function _moduleMapping() private view returns (mapping(address => address) storage modules) {
        modules = AccountStorage.layout().modules;
    }

    function _addModule(address module) internal {
        if (module == address(0)) revert MODULE_ADDRESS_EMPTY();
        mapping(address => address) storage modules = _moduleMapping();
        modules.add(module);
        emit ModuleAdded(module);
    }

    function _isAuthorizedModule() internal view returns (bool) {
        address module = msg.sender;
        if (!_moduleMapping().isExist(module)) {
            return false;
        } else return true;
    }
}