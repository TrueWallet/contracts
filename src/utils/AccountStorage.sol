// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "openzeppelin-contracts/utils/structs/EnumerableSet.sol";
import "../interfaces/ILogicUpgradeControl.sol";
import "../interfaces/IEntryPoint.sol";
import "./Initializable.sol";

library AccountStorage {
    bytes32 private constant ACCOUNT_SLOT = keccak256("truewallet.contracts.AccountStorage");

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    struct Layout {


        /// ┌───────────────────┐
        /// │     base data     │                                   /// TrueWallet.sol
        IEntryPoint entryPoint;                                     /// entryPoint
        address owner;                                              /// owner slot
        uint96 nonce;                                               /// explicit sizes of nonce, to fit a single storage cell with "owner"
        uint256[50] __gap_0;
        /// └───────────────────┘



        /// ┌───────────────────┐
        /// │   upgrade data    │
        ILogicUpgradeControl.UpgradeLayout logicUpgrade;            /// LogicUpgradeControl.sol
        Initializable.InitializableLayout initializableLayout;
        uint256[50] __gap_1;
        /// └───────────────────┘



        /// ┌───────────────────┐
        /// │     role data     │
        mapping(bytes32 => RoleData) roles;                         /// AccessControl.sol
        mapping(bytes32 => EnumerableSet.AddressSet) roleMembers;   /// AccessControlEnumerable.sol
        uint256[50] __gap_2;
        /// └───────────────────┘



        /// ┌───────────────────┐
        /// │     guardian      │                                   /// SocialRecovery.sol
        uint64 executeAfter;                                        /// @dev Execute recovery after
        uint16 threshold;                                           /// @dev Required number of guardians to confirm recovery  
        address[] guardians;                                        /// @dev The list of guardians addresses
        mapping (address => bool) isGuardian;                       /// @dev isGuardian mapping maps guardian's address to guardian status
        mapping (bytes32 => bool) isExecuted;                       /// @dev isExecuted mapping maps data hash to execution status
        mapping (bytes32 => mapping (address => bool)) isConfirmed; /// @dev isConfirmed mapping maps data hash to guardian's address to confirmation status
        uint256[50] __gap_3;
        /// └───────────────────┘


    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = ACCOUNT_SLOT;
        assembly {
            l.slot := slot
        }
    }
}