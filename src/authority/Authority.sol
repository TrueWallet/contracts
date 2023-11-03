// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.19;

// import {EntryPointAuth} from "./EntryPointAuth.sol";
import {ModuleAuth} from "./ModuleAuth.sol";
import {OwnerAuth} from "./OwnerAuth.sol";
import {OwnerManagerErrors} from "src/common/Errors.sol";

abstract contract Authority is /*EntryPointAuth,*/ ModuleAuth, OwnerAuth {
    modifier onlySelfOrModule() {
        if (msg.sender != address(this) && !_isAuthorizedModule()) {
            revert OwnerManagerErrors.CallerMustBeSelfOfModule();
        }
        _;
    }
}