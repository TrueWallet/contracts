// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {TrueWallet} from "src/wallet/TrueWallet.sol";

/// @title IWalletFactory
/// @notice Interface for the WalletFactory contract responsible for deploying and managing smart wallets.
interface IWalletFactory {
    /**
     * @notice Deploy a new TrueWallet smart contract using CREATE3.
     * @param initializer Initialization data for the new wallet.
     * @param salt A unique salt value used in the CREATE3 operation for deterministic address generation.
     * @return The address of the newly created TrueWallet contract.
     */
    function createWallet(bytes memory initializer, bytes32 salt) external returns (TrueWallet);

    /**
     * @notice Computes the deterministic address for a potential wallet deployment using CREATE3.
     * @param salt A unique salt value used in the CREATE3 operation for deterministic address generation.
     * @return The computed wallet address.
     */
    function getWalletAddress(bytes32 salt) external view returns (address);

    /**
     * @notice Constructs the initializer payload for wallet creation.
     * @param entryPoint The address of the EntryPoint contract for the new wallet.
     * @param walletOwner The owner address for the new wallet.
     * @param modules Array of initial module addresses with respective init data for the wallet.
     * @return The encoded initializer payload.
     */
    function getInitializer(address entryPoint, address walletOwner, bytes[] calldata modules)
        external
        pure
        returns (bytes memory);
}
