// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.19;

import {IModule} from "../interfaces/IModule.sol";
import {IModuleManager} from "../interfaces/IModuleManager.sol";
import {IWallet} from "../wallet/IWallet.sol";
import {ModuleManagerErrors} from "../common/Errors.sol";

/// @title Base Module - provides basic functionalities for initializing and deinitializing a wallet modules.
abstract contract BaseModule is IModule, ModuleManagerErrors {
    /// @dev Emitted when a module is initialized for a wallet.
    event ModuleInit(address indexed wallet);
    /// @dev Emitted when a module is de-initialized for a wallet.
    event ModuleDeInit(address indexed wallet);

    /// @notice Initializes the module for the sender's wallet with provided data.
    /// @dev Only authorized and not previously initialized modules can perform this action.
    /// @param data Initialization data.
    function walletInit(bytes calldata data) external {
        address _sender = sender();
        if (!inited(_sender)) {
            // add module after wallet deployment
            if (_sender.code.length > 0) {
                if (!IWallet(_sender).isAuthorizedModule(address(this))) {
                    revert ModuleNotAuthorized();
                }
            } 
            _init(data);
            emit ModuleInit(_sender);
        }
    }

    /// @notice De-initializes the module for the sender's wallet.
    /// @dev Only not authorized and previously initialized modules can perform this action.
    function walletDeInit() external {
        address _sender = sender();
        if (inited(_sender)) {
            if (IWallet(_sender).isAuthorizedModule(address(this))) {
                revert ModuleAuthorized();
            }
            _deInit();
            emit ModuleDeInit(_sender);
        }
    }

    /// @notice Checks if the module is initialized for a given wallet.
    /// @param wallet Address of the wallet to check.
    /// @return true if the module is initialized for the wallet, false otherwise.
    function inited(address wallet) internal view virtual returns (bool);

    /// @notice Initializes the module with provided data.
    /// @dev Implementation should be provided by derived contracts.
    /// @param data Initialization data.
    function _init(bytes calldata data) internal virtual;

    /// @notice De-initializes the module.
    /// @dev Implementation should be provided by derived contracts.
    function _deInit() internal virtual;

    /// @notice Retrieves the sender of the current transaction.
    /// @return address of the sender.
    function sender() internal view returns (address) {
        return msg.sender;
    }

    /// @notice Checks if the contract implements a given interface.
    /// @param interfaceId The interface identifier, as specified by ERC-165.
    /// @return true if the contract implements `interfaceId` and `interfaceId` is not 0xffffffff, false otherwise.
    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IModule).interfaceId;
    }
}
