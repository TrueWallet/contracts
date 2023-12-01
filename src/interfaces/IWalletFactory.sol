// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {TrueWallet} from "src/wallet/TrueWallet.sol";

/// @title IWalletFactory
/// @notice Interface for the WalletFactory contract responsible for deploying and managing smart wallets.
interface IWalletFactory {
    /**
    * @notice Deploy a smart wallet with specified entryPoint and walletOwner.
    * @dev If no initCode is passed, the function returns the CREATE2 computed address.
    * @param entryPoint The address of the EntryPoint contract.
    * @param walletOwner The address of the wallet owner.
    * @param modules An array of modules with init data to be associated with the wallet.
    * @param salt A unique salt for CREATE2 deployment.
    * @return The address of the newly created TrueWallet contract.
    */
    function createWallet(
        address entryPoint,
        address walletOwner,
        bytes[] calldata modules,
        bytes32 salt
    ) external returns (TrueWallet);

    /**
    * @notice Computes the address of a smart wallet using CREATE2, deterministically.
    * @param entryPoint The address of the EntryPoint contract.
    * @param walletOwner The address of the wallet owner.
    * @param modules An array of modules with init data to be associated with the wallet.
    * @param salt A unique salt for CREATE2 deployment.
    * @return The computed wallet address.
    */
    function getWalletAddress(
        address entryPoint,
        address walletOwner,
        bytes[] calldata modules,
        bytes32 salt
    ) external view returns (address);
}
