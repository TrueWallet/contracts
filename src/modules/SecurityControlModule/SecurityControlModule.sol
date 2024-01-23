// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.19;

import {BaseModule} from "../BaseModule.sol";
import {ITrueContractManager} from "../../registry/ITrueContractManager.sol";
import {IModuleManager} from "../../interfaces/IModuleManager.sol";
import {IWallet} from "src/interfaces/IWallet.sol";

/// @title SecurityControlModule
/// @dev A module that provides enhanced security controls for adding and removing modules and executing specific functions on a initialized wallet.
contract SecurityControlModule is BaseModule {
    /// @dev Throws when a module is not recognized as a trusted module.
    error SecurityControlModule__InvalidModule();
    /// @dev Throws when the caller is not the owner of the target wallet.
    error SecurityControlModule__InvalidOwner();
    /// @dev Throws when the module is not initialized for a particular wallet.
    error SecurityControlModule__NotInitialized();
    /// @dev Throws when there's an attempt to remove this module itself.
    error SecurityControlModule__UnableSelfRemove();
    /// @dev Throws when a function selector is unsupported.
    error SecurityControlModule__UnsupportedSelector(bytes4 selector);
    /// @dev Throws when there's an issue executing a function.
    error SecurityControlModule__ExecuteError(address target, bytes data, address sender, bytes returnData);
    /// @dev Throws when attempting to redo the basic initialization for a wallet that has already been initialized.
    error SecurityControlModule__BasicInitAlreadyDone();
    /// @dev Throws when attempting operations requiring basic initialization that hasn't been completed for a wallet.
    error SecurityControlModule__BasicInitNotDone();
    /// @dev Throws when attempting to redo the full initialization for a wallet that has already completed full initialization.
    error SecurityControlModule__FullInitAlreadyDone();
    /// @dev Throws when the initialization state is invalid.
    error SecurityControlModule__InvalidInitState();

    /// @dev The contract manager that checks if a module is trusted.
    ITrueContractManager public immutable trueContractManager;

    /// @dev Mapping to track whether a basic initialization has been done for each wallet address.
    mapping(address => bool) public basicInitialized;

    /// @dev Mapping to track whether a full initialization has been done for each wallet address.
    mapping(address => bool) public fullInitialized;

    /// @dev Mapping to track initialization state for wallets.
    mapping(address wallet => uint256 seed) public walletInitSeed;

    /// @dev Internal seed for generating unique values.
    uint256 private __seed = 0;

    /// @notice An event emitted when a function execution is successful.
    event Execute(address target, bytes data, address sender);

    /// @param trueContractManagerAddress The address of the TrueContractManager registry.
    constructor(ITrueContractManager trueContractManagerAddress) {
        trueContractManager = trueContractManagerAddress;
    }

    /// @notice Completes the full initialization of the module.
    /// @dev This function should be called after the basic initialization has been done via `_init`.
    ///      It finalizes the module setup by assigning a unique seed to the `walletInitSeed` mapping for the caller.
    ///      This function can only be called once for each wallet to prevent re-initialization.
    function fullInit() external {
        address _sender = sender();
        if (!basicInitialized[_sender]) revert SecurityControlModule__BasicInitNotDone();
        if (fullInitialized[_sender]) revert SecurityControlModule__FullInitAlreadyDone();
        fullInitialized[_sender] = true;
        walletInitSeed[_sender] = _newSeed();
    }

    /// @notice Completes the full initialization and adds a module to the target wallet address.
    /// @dev This function finalizes the initialization by setting `fullInitialized` to true and assigns a new seed.
    ///      Only allows adding a module to the target contract after the full initialization is complete.
    /// @param target The address of the target contract where the module is to be added.
    /// @param data The function data to be executed, including the module to be added.
    function fullInitAndAddModule(address target, bytes calldata data) external {
        address _sender = sender();
        if (!basicInitialized[_sender] || fullInitialized[_sender]) {
            revert SecurityControlModule__InvalidInitState();
        }
        fullInitialized[_sender] = true;
        walletInitSeed[_sender] = _newSeed();
        _authorized(target);
        if (bytes4(data[0:4]) != IModuleManager.addModule.selector) {
            revert SecurityControlModule__UnsupportedSelector(bytes4(data[0:4]));
        }
        if (!trueContractManager.isTrueModule(address(bytes20(data[68:88])))) {
            revert SecurityControlModule__InvalidModule();
        }
        _execute(target, data);
    }

    /// @notice Executes a specific function on the target address.
    /// @param target The address of the target contract.
    /// @param data The function data to be executed.
    function execute(address target, bytes calldata data) external {
        _authorized(target);
        _preExecute(target, data);
        _execute(target, data);
    }

    /// @dev Internal function to execute a call to a target address.
    /// @param target The address of the target contract.
    /// @param data The function data to be executed.
    function _execute(address target, bytes calldata data) internal {
        (bool succ, bytes memory res) = target.call{value: 0}(data);
        if (succ) {
            emit Execute(target, data, sender());
        } else {
            revert SecurityControlModule__ExecuteError(target, data, sender(), res);
        }
    }

    /// @dev Verifies the provided data for valid function execution.
    /// @param target The target contract's address.
    /// @param data The function data.
    function _preExecute(address target, bytes calldata data) internal view {
        (target);
        bytes4 _func = bytes4(data[0:4]);
        if (_func == IModuleManager.addModule.selector) {
            address module = address(bytes20(data[68:88])); // 4 sig + 32 bytes + 32 bytes
            if (!trueContractManager.isTrueModule(module)) {
                revert SecurityControlModule__InvalidModule();
            }
        } else if (_func == IModuleManager.removeModule.selector) {
            (address module) = abi.decode(data[4:], (address));
            if (module == address(this)) {
                revert SecurityControlModule__UnableSelfRemove();
            }
        } else {
            revert SecurityControlModule__UnsupportedSelector(_func);
        }
    }

    /// @dev Verifies if the caller is authorized to interact with the target.
    /// @param target The target wallet address.
    function _authorized(address target) internal view {
        address _sender = sender();
        if (_sender != target && !IWallet(target).isOwner(_sender)) {
            revert SecurityControlModule__InvalidOwner();
        }
        if (walletInitSeed[target] == 0) {
            revert SecurityControlModule__NotInitialized();
        }
    }

    /// @notice Checks if a wallet is initialized.
    /// @param wallet The address of the wallet.
    /// @return bool True if the wallet is initialized, false otherwise.
    function inited(address wallet) internal view override returns (bool) {
        return walletInitSeed[wallet] != 0;
    }

    /// @notice Internal function for basic initialization of the module.
    /// @dev This function sets the initial state for the module associated with the caller.
    ///      It should be invoked only once as part of the module's setup process.
    ///      The function checks if the basic initialization for the caller (`_sender`) has already been completed to prevent re-initialization.
    ///      The `data` parameter is not currently used but can be utilized for future extensions or additional initialization parameters.
    /// @param data Additional initialization data; currently unused.
    /// @custom:note This function is part of the two-step initialization process and is typically called automatically during module deployment.
    function _init(bytes calldata data) internal override {
        (data);
        address _sender = sender();
        if (basicInitialized[_sender]) revert SecurityControlModule__BasicInitAlreadyDone();
        basicInitialized[_sender] = true;
    }

    /// @dev De-initializes the module for a wallet.
    function _deInit() internal override {
        address _sender = sender();
        walletInitSeed[_sender] = 0;
    }

    /// @dev Generates a new unique seed value.
    function _newSeed() private returns (uint256) {
        __seed++;
        return __seed;
    }

    /// @notice Provides the list of required functions that this module supports.
    /// @return bytes4[] Array of function selectors.
    function requiredFunctions() external pure override returns (bytes4[] memory) {
        bytes4[] memory _requiredFunctions = new bytes4[](3);
        _requiredFunctions[0] = IModuleManager.addModule.selector;
        _requiredFunctions[1] = IModuleManager.removeModule.selector;
        _requiredFunctions[2] = IModuleManager.executeFromModule.selector;
        return _requiredFunctions;
    }
}
