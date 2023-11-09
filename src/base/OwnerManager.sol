// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.19;

import {AccountStorage} from "../utils/AccountStorage.sol";
import {Authority} from "../authority/Authority.sol";
import {IModuleManager} from "../interfaces/IModuleManager.sol";
import {IOwnerManager} from "../interfaces/IOwnerManager.sol";
import {AddressLinkedList} from "../libraries/AddressLinkedList.sol";
import {OwnerManagerErrors} from "../common/Errors.sol";

/// @title OwnerManager
/// @dev Provides functionality for adding, removing, checking, and listing owners.
abstract contract OwnerManager is IOwnerManager, Authority {
    using AddressLinkedList for mapping(address => address);

    function isOwner(address addr) external view returns (bool) {
        return _isOwner(addr);
    }

    function addOwner(address owner) external override onlySelfOrModule {
        _addOwner(owner);
    }

    function addOwners(address[] calldata owners) external override onlySelfOrModule {
        _addOwners(owners);
    }

    function resetOwner(address newOwner) external override onlySelfOrModule {
        _clearOwner();
        _addOwner(newOwner);
    }

    function resetOwners(address[] calldata newOwners) external override onlySelfOrModule {
        _clearOwner();
        _addOwners(newOwners);
    }

    function removeOwner(address owner) external override onlySelfOrModule {
        _ownerMapping().remove(owner);
        if (_ownerMapping().isEmpty()) {
            revert OwnerManagerErrors.NoOwner();
        }
        emit OwnerRemoved(owner);
    }

    function _isOwner(address addr) internal view returns (bool) {
        return _ownerMapping().isExist(addr);
    }

    function _addOwner(address owner) internal {
        _ownerMapping().add(owner);
        emit OwnerAdded(owner);
    }

    function _ownerMapping() private view returns (mapping(address => address) storage owners) {
        owners = AccountStorage.layout().owners;
    }

    function _clearOwner() private {
        _ownerMapping().clear();
        emit OwnerCleared();
    }

    function _addOwners(address[] calldata owners) private {
        for (uint256 i; i < owners.length;) {
            _addOwner(owners[i]);
            unchecked {
                i++;
            }
        }
    }

    function listOwner() public view override returns (address[] memory owners) {
        uint256 size = _ownerMapping().size();
        owners = _ownerMapping().list(AddressLinkedList.SENTINEL_ADDRESS, size);
    }
}