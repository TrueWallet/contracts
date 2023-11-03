// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.19;

import {ModuleManagerErrors} from "src/common/Errors.sol";

abstract contract ModuleAuth {
    function _isAuthorizedModule() internal view virtual returns (bool);

    modifier onlyModule() {
        if (!_isAuthorizedModule()) {
            revert ModuleManagerErrors.CallerMustBeModule();
        }
        _;
    }
}