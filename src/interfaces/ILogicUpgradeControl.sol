// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

/**
 * @dev Interface of the LogicUpgradeControl
 */
interface ILogicUpgradeControl {
    struct UpgradeLayout {
        uint64 activateTime; // activateTime
        address pendingImplementation; // pendingImplementation
        uint256[50] __gap;
    }

    /**
     * @dev Emitted before upgrade logic
     */
    event PreUpgrade(address newLogic, uint64 activateTime);

    /**
     * @dev Emitted when `implementation` is upgraded.
     */
    event Upgraded(address newImplementation);
}
