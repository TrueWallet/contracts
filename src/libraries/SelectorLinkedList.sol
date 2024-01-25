// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

/**
 * @title Selector Linked List.
 * @notice This library provides utility functions to manage a linked list of selectors.
 */
library SelectorLinkedList {
    error InvalidSelector();
    error SelectorAlreadyExists();
    error SelectorNotExists();

    bytes4 internal constant SENTINEL_SELECTOR = 0x00000001;
    uint32 internal constant SENTINEL_UINT = 1;

    function isSafeSelector(bytes4 selector) internal pure returns (bool) {
        return uint32(selector) > SENTINEL_UINT;
    }

    /**
     * @dev Modifier that checks if an selector is valid.
     */
    modifier onlySelector(bytes4 selector) {
        if (!isSafeSelector(selector)) {
            revert InvalidSelector();
        }
        _;
    }

    /**
     * @notice Adds a selector to the linked list.
     * @param self The linked list mapping.
     * @param selector The selector to be added.
     */
    function add(mapping(bytes4 => bytes4) storage self, bytes4 selector) internal onlySelector(selector) {
        if (self[selector] != 0) {
            revert SelectorAlreadyExists();
        }
        bytes4 _prev = self[SENTINEL_SELECTOR];
        if (_prev == 0) {
            self[SENTINEL_SELECTOR] = selector;
            self[selector] = SENTINEL_SELECTOR;
        } else {
            self[SENTINEL_SELECTOR] = selector;
            self[selector] = _prev;
        }
    }

    function add(mapping(bytes4 => bytes4) storage self, bytes4[] memory selectors) internal {
        for (uint256 i = 0; i < selectors.length;) {
            add(self, selectors[i]);
            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Removes an address from the linked list.
     * @param self The linked list mapping.
     * @param selector The address to be removed.
     */
    function remove(mapping(bytes4 => bytes4) storage self, bytes4 selector) internal {
        if (!isExist(self, selector)) {
            revert SelectorNotExists();
        }

        bytes4 cursor = SENTINEL_SELECTOR;
        while (true) {
            bytes4 _selector = self[cursor];
            if (_selector == selector) {
                bytes4 next = self[_selector];
                if (next == SENTINEL_SELECTOR && cursor == SENTINEL_SELECTOR) {
                    self[SENTINEL_SELECTOR] = 0;
                } else {
                    self[cursor] = next;
                }
                self[_selector] = 0;
                return;
            }
            cursor = _selector;
        }
    }

    /**
     * @notice Clears all selectors from the linked list.
     * @param self The linked list mapping.
     */
    function clear(mapping(bytes4 => bytes4) storage self) internal {
        bytes4 selector = self[SENTINEL_SELECTOR];
        self[SENTINEL_SELECTOR] = 0;
        while (uint32(selector) > SENTINEL_UINT) {
            bytes4 _selector = self[selector];
            self[selector] = 0;
            selector = _selector;
        }
    }

    /**
     * @notice Checks if an selector exists in the linked list.
     * @param self The linked list mapping.
     * @param selector The selector to check.
     * @return Returns true if the selector exists, false otherwise.
     */
    function isExist(mapping(bytes4 => bytes4) storage self, bytes4 selector)
        internal
        view
        onlySelector(selector)
        returns (bool)
    {
        return self[selector] != 0;
    }

    /**
     * @notice Returns the size of the linked list.
     * @param self The linked list mapping.
     * @return Returns the size of the linked list.
     */
    function size(mapping(bytes4 => bytes4) storage self) internal view returns (uint256) {
        uint256 result = 0;
        bytes4 selector = self[SENTINEL_SELECTOR];
        while (uint32(selector) > SENTINEL_UINT) {
            selector = self[selector];
            unchecked {
                result++;
            }
        }
        return result;
    }

    /**
     * @notice Checks if the linked list is empty.
     * @param self The linked list mapping.
     * @return Returns true if the linked list is empty, false otherwise.
     */
    function isEmpty(mapping(bytes4 => bytes4) storage self) internal view returns (bool) {
        return self[SENTINEL_SELECTOR] == 0;
    }

   /**
     * @notice Returns a list of selectors from the linked list.
     * @param self The linked list mapping.
     * @param from The starting selector.
     * @param limit The number of selectors to return.
     * @return Returns an array of selectors.
     */
    function list(mapping(bytes4 => bytes4) storage self, bytes4 from, uint256 limit)
        internal
        view
        returns (bytes4[] memory)
    {
        bytes4[] memory result = new bytes4[](limit);
        uint256 i = 0;
        bytes4 selector = self[from];
        while (uint32(selector) > SENTINEL_UINT && i < limit) {
            result[i] = selector;
            selector = self[selector];
            unchecked {
                i++;
            }
        }

        return result;
    }
}
