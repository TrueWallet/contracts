// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.19;

import "openzeppelin-contracts/utils/introspection/IERC165.sol";

/// @title IModule - describes the basic operations for modules within the modular smart account.
interface IModule is IERC165 {
    /// @notice Initializes the module for the sender's wallet with provided data.
    /// @dev Implementing contracts should define how a module gets initialized for a wallet.
    /// @param data Initialization data.
    function walletInit(bytes calldata data) external;

    /// @notice De-initializes the module for the sender's wallet.
    /// @dev Implementing contracts should define how a module gets de-initialized for a wallet.
    function walletDeInit() external;

    /// @notice Lists the required functions for the module.
    /// @dev Implementing contracts should return an array of function selectors representing the functions required by the module.
    /// @return An array of function selectors.
    function requiredFunctions() external pure returns (bytes4[] memory);
}