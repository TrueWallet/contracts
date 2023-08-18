// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {TrueWallet} from "src/wallet/TrueWallet.sol";

interface IWalletFactory {
    /// @notice Deploy a smart wallet, with an entryPoint and Owner specified by the user
    ///         Intended that all wallets are deployed through this factory, so if no initCode is passed
    ///         then just returns the CREATE2 computed address
    function createWallet(
        address entryPoint,
        address walletOwner,
        uint32 upgradeDelay,
        bytes32 salt
    ) external returns (TrueWallet);

    /// @notice Deterministically compute the address of a smart wallet using Create2
    function getWalletAddress(
        address entryPoint,
        address walletOwner,
        uint32 upgradeDelay,
        bytes32 salt
    ) external view returns (address);
}
