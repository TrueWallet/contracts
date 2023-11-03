// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.19;

import {ModuleManagerErrors} from "src/common/Errors.sol";

abstract contract OwnerAuth {
    function _isOwner() internal view virtual returns (bool);
}