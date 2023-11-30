// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {Upgradeable} from "src/utils/Upgradeable.sol";

/// @title TrueWalletProxy
/// @notice A proxy contract that forwards calls to an implementation contract.
/// @dev This proxy uses the EIP-1967 standard for storage slots.
contract TrueWalletProxy is Upgradeable {
    /**
     * @notice Initializes the proxy with the address of the initial implementation contract.
     * @param logic Address of the initial implementation.
     */
    constructor(address logic) {
        assembly ("memory-safe") {
            sstore(_IMPLEMENTATION_SLOT, logic)
        }
    }

    /**
     * @notice Fallback function which forwards all calls to the implementation contract.
     * @dev Uses delegatecall to ensure the context remains within the proxy.
     */
    fallback() external payable {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            /* not memory-safe */
            let _singleton := and(sload(_IMPLEMENTATION_SLOT), 0xffffffffffffffffffffffffffffffffffffffff)
            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(gas(), _singleton, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if eq(success, 0) { revert(0, returndatasize()) }
            return(0, returndatasize())
        }
    }
}
