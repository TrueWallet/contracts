// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

/**
 * @title Upgradeable Smart Contract
 * @dev This abstract contract provides a basic framework for upgradeable contracts using the EIP-1967 standard.
 *      It includes functionality to get and set the implementation address, and to upgrade the contract.
 *      EIP-1967 is a standard for handling proxy contracts and their implementation addresses in a predictable manner.
 */
abstract contract Upgradeable {
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev @dev The mask of the lower 160 bits for addresses.
     */
    uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

    /**
     * @dev The `Upgraded` event signature is given by: `keccak256(bytes("Upgraded(address)"))`.
     */
    bytes32 private constant _UPGRADED_EVENT_SIGNATURE =
        0xbc7cd75a20ee27fd9adebab32041f755214dbc6bffa90cc0225b39da2e5c2d3b;

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address implementation) {
        assembly {
            implementation := sload(_IMPLEMENTATION_SLOT)
        }
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(newImplementation.code.length > 0);
        assembly {
            sstore(_IMPLEMENTATION_SLOT, newImplementation)
        }
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementationUnsafe(address newImplementation) private {
        assembly {
            sstore(_IMPLEMENTATION_SLOT, newImplementation)
        }
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        assembly {
            // emit Upgraded(newImplementation);
            let _newImplementation := and(newImplementation, _BITMASK_ADDRESS)
            // Emit the `Upgraded` event.
            log2(0, 0, _UPGRADED_EVENT_SIGNATURE, _newImplementation)
        }
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToUnsafe(address newImplementation) internal {
        _setImplementationUnsafe(newImplementation);
        assembly {
            // emit Upgraded(newImplementation);
            let _newImplementation := and(newImplementation, _BITMASK_ADDRESS)
            // Emit the `Upgraded` event.
            log2(0, 0, _UPGRADED_EVENT_SIGNATURE, _newImplementation)
        }
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(address newImplementation, bytes memory data) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                // Call the implementation using delegatecall
                let result := delegatecall(
                    gas(),              // forward all available gas
                    newImplementation,  // target address (new implementation)
                    add(data, 0x20),    // pointer to data, skipping the length field
                    mload(data),        // size of data
                    0,                  // we don't use the return value, so no need for output buffer
                    0                   // output size is zero
                )

                // Check if the delegatecall was successful, revert otherwise
                switch result
                case 0 { revert(0, 0) }
            }
        }
    }
}
