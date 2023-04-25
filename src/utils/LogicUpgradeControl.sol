// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "openzeppelin-contracts/utils/Address.sol";
import {Upgradeable} from "src/utils/Upgradeable.sol";

contract LogicUpgradeControl is Upgradeable {
    address public pendingImplementation;
    uint64 public activateTime;

    error UpgradeDelayNotElapsed();

    event PreUpgrade(address newImplementation, uint64 activateTime);

    /// @dev preUpgradeTo is called before upgrading the wallet
    function _preUpgradeTo(address newImplementation, uint32 upgradeDelay) internal {
        if (newImplementation != address(0)) {
            require(Address.isContract(newImplementation));

            pendingImplementation = newImplementation;

            activateTime = uint64(block.timestamp + upgradeDelay);
        } else {
            activateTime = 0;
        }

        emit PreUpgrade(newImplementation, activateTime);
    }

    /// @dev Perform implementation upgrade
    function upgrade() external {
        if (activateTime != 0 && activateTime >= block.timestamp) {
            _upgradeTo(pendingImplementation);
        } else {
            revert UpgradeDelayNotElapsed();
        }

        activateTime = 0;
        pendingImplementation = address(0);
    }

    /// @dev Returns the current implementation address
    function getImplementation() public view returns (address) {
        _getImplementation();
    }
}