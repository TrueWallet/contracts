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
}