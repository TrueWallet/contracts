// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "openzeppelin-contracts/utils/Address.sol";
import {ILogicUpgradeControl} from "../interfaces/ILogicUpgradeControl.sol";
import {AccountStorage} from "./AccountStorage.sol";
import {Upgradeable} from "./Upgradeable.sol";

contract LogicUpgradeControl is ILogicUpgradeControl, Upgradeable {
    using AccountStorage for AccountStorage.Layout;

    error UpgradeDelayNotElapsed();

    /// @dev Returns Logic updgrade layout info
    function logicUpgradeInfo() public view returns (ILogicUpgradeControl.UpgradeLayout memory) {
        ILogicUpgradeControl.UpgradeLayout memory layout = AccountStorage.layout().logicUpgrade;
        return layout;
    }

    /// @dev preUpgradeTo is called before upgrading the wallet
    function _preUpgradeTo(address newImplementation) internal {
        ILogicUpgradeControl.UpgradeLayout storage layout = AccountStorage.layout().logicUpgrade;

        if (newImplementation != address(0)) {
            require(Address.isContract(newImplementation));

            layout.pendingImplementation = newImplementation;

            layout.activateTime = uint64(block.timestamp + layout.upgradeDelay);
        } else {
            layout.activateTime = 0;
        }

        emit PreUpgrade(newImplementation, layout.activateTime);
    }

    /// @dev Perform implementation upgrade
    function upgrade() external {
        ILogicUpgradeControl.UpgradeLayout storage layout = AccountStorage.layout().logicUpgrade;

        if (layout.activateTime != 0 && block.timestamp >= layout.activateTime) {
            _upgradeTo(layout.pendingImplementation);
        } else {
            revert UpgradeDelayNotElapsed();
        }

        layout.activateTime = 0;
        layout.pendingImplementation = address(0);
    }

    /// @dev Returns the current implementation address
    function getImplementation() public view {
        _getImplementation();
    }
}