// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.19;

import {IEntryPoint} from "account-abstraction/interfaces/IEntryPoint.sol";
import {WalletErrors} from "src/common/Errors.sol";

abstract contract EntryPointAuth {
    function _entryPoint() internal view virtual returns (IEntryPoint);

    modifier onlyEntryPoint() {
        if (msg.sender != address(_entryPoint())) {
            revert WalletErrors.InvalidEntryPoint();
        }
        _;
    }
}
