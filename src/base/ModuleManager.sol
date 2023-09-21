// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.19;

import {AccountStorage} from "../utils/AccountStorage.sol";
import {IModuleManager} from "../interfaces/IModuleManager.sol";
import {IModule} from "../interfaces/IModule.sol";
import {AddressLinkedList} from "../libraries/AddressLinkedList.sol";
import {SelectorLinkedList} from "../libraries/SelectorLinkedList.sol";
import {ModuleManagerErrors} from "../common/Errors.sol";

/// @title Module Manager - A contract that manages modules that can execute transactions
///        on behalf of the Smart Account via this contract.
abstract contract ModuleManager is IModuleManager, ModuleManagerErrors {
    using AddressLinkedList for mapping(address => address);
    using SelectorLinkedList for mapping(bytes4 => bytes4);

    modifier onlyModule() {
        if (_isAuthorizedModule()) {
            revert CallerMustBeModule();
        }
        _;
    }

    function isAuthoraizedModule(address module) external view returns (bool) {
        return _modulesMapping().isExist(module);
    }

    function addModule(bytes calldata moduleAndData) external override onlyModule {
        _addModule(moduleAndData);
    }

    function removeModule(address module) external override onlyModule {
        mapping(address => address) storage modules = _modulesMapping();
        modules.remove(module);

        mapping(address => mapping(bytes4 => bytes4)) storage moduleSelectors = _moduleSelectorsMapping();
        moduleSelectors[module].clear();

        try IModule(module).walletDeInit() {
            emit ModuleRemoved(module);
        } catch {
            emit ModuleRemovedWithError(module);
        }
    }

    function listModules() external view override returns (address[] memory modules, bytes4[][] memory selectors) {
        mapping(address => address) storage _modules = _modulesMapping();
        uint256 moduleSize = _modulesMapping().size();
        modules = new address[](moduleSize);
        mapping(address => mapping(bytes4 => bytes4)) storage moduleSelectors = _moduleSelectorsMapping();
        selectors = new bytes4[][](moduleSize);

        uint256 i = 0;
        address addr = _modules[AddressLinkedList.SENTINEL_ADDRESS];
        while (uint160(addr) > AddressLinkedList.SENTINEL_UINT) {
            {
                modules[i] = addr;
                mapping(bytes4 => bytes4) storage moduleSelector = moduleSelectors[addr];

                {
                    uint256 selectorSize = moduleSelector.size();
                    bytes4[] memory _selectors = new bytes4[](selectorSize);
                    uint256 j = 0;
                    bytes4 selector = moduleSelector[SelectorLinkedList.SENTINEL_SELECTOR];
                    while (uint32(selector) > SelectorLinkedList.SENTINEL_UINT) {
                        _selectors[j] = selector;

                        selector = moduleSelector[selector];
                        unchecked {
                            j++;
                        }
                    }
                    selectors[i] = _selectors;
                }
            }

            addr = _modules[addr];
            unchecked {
                i++;
            }
        }
    }

    function executeFromModule(address to, uint256 value, bytes memory data) external override onlyModule {
        if (to == address(this)) revert ModuleExecuteFromModuleRecursive();
        assembly {
            /* not memory-safe */
            let result := call(gas(), to, value, add(data, 0x20), mload(data), 0, 0)
            if iszero(result) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    function _modulesMapping() private view returns (mapping(address => address) storage modules) {
        modules = AccountStorage.layout().modules;
    }

    function _moduleSelectorsMapping()
        private
        view
        returns (mapping(address => mapping(bytes4 => bytes4)) storage moduleSelectors)
    {
        moduleSelectors = AccountStorage.layout().moduleSelectors;
    }

    function _addModule(bytes calldata moduleAndData) internal {
        if (moduleAndData.length < 20) {
            revert ModuleAddressEmpty();
        }
        address moduleAddress = address(bytes20(moduleAndData[:20]));
        bytes calldata initData = moduleAndData[20:];
        IModule aModule = IModule(moduleAddress);
        if (!aModule.supportsInterface(type(IModule).interfaceId)) {
            revert ModuleNotSupportInterface();
        }
        bytes4[] memory requiredFunctions = aModule.requiredFunctions();
        if (requiredFunctions.length == 0) {
            revert ModuleSelectorsEmpty();
        }

        mapping(address => address) storage modules = _modulesMapping();
        modules.add(moduleAddress);
        mapping(address => mapping(bytes4 => bytes4)) storage moduleSelectors = _moduleSelectorsMapping();
        moduleSelectors[moduleAddress].add(requiredFunctions);
        aModule.walletInit(initData);
        emit ModuleAdded(moduleAddress);
    }

    function _isAuthorizedModule() internal view returns (bool) {
        address module = msg.sender;
        if (!_modulesMapping().isExist(module)) {
            return false;
        } else {
            return true;
        }
    }
}
