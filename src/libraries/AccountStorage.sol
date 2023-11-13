// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {IEntryPoint} from "account-abstraction/interfaces/IEntryPoint.sol";
import "../interfaces/ILogicUpgradeControl.sol";
import "../utils/Initializable.sol";

library AccountStorage {
    bytes32 private constant ACCOUNT_SLOT =
        keccak256("truewallet.contracts.AccountStorage");

    struct Layout {
        /// ┌───────────────────┐
        /// │     base data     │                                   /// TrueWallet.sol
        IEntryPoint entryPoint; /// entryPoint
        mapping(address => address) owners;
        uint256[50] __gap_0;
        /// └───────────────────┘

        /// ┌───────────────────┐
        /// │   upgrade data    │
        ILogicUpgradeControl.UpgradeLayout logicUpgrade;            /// LogicUpgradeControl.sol
        Initializable.InitializableLayout initializableLayout;
        uint256[50] __gap_1;
        /// └───────────────────┘

        // ┌───────────────────┐
        // │       Module      │                                    /// ModuleManager.sol
        mapping(address => address) modules;
        mapping(address => mapping(bytes4 => bytes4)) moduleSelectors;
        uint256[50] __gap_2;
        // └───────────────────┘
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = ACCOUNT_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
