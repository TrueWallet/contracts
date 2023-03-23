// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {Pausable} from "openzeppelin-contracts/security/Pausable.sol";
import {Create2} from "openzeppelin-contracts/utils/Create2.sol";
import {TrueWallet} from "src/TrueWallet.sol";

/// @title WalletFactory contract to deploy user smart wallets
contract WalletFactory is Ownable, Pausable {
    constructor() Ownable() Pausable() {}

    /// @notice Deploy a smart wallet, with an entryPoint and Owner specified by the user
    ///         Intended that all wallets are deployed through this factory, so if no initCode is passed
    ///         then just returns the CREATE2 computed address
    function deployWallet(
        address entryPoint,
        address walletOwner,
        bytes32 salt
    ) external whenNotPaused returns (TrueWallet) {
        address walletAddress = computeAddress(entryPoint, walletOwner, salt);

        // Determine if a wallet is already deployed at this address, if so return that
        uint256 codeSize = walletAddress.code.length;
        if (codeSize > 0) {
            return TrueWallet(payable(walletAddress));
        } else {
            // Deploy the wallet
            TrueWallet wallet = new TrueWallet{salt: bytes32(salt)}(
                entryPoint,
                walletOwner
            );
            return wallet;
        }
    }

    /// @notice Deterministically compute the address of a smart wallet using Create2
    function computeAddress(
        address entryPoint,
        address walletOwner,
        bytes32 salt
    ) public view returns (address) {
        return
            Create2.computeAddress(
                bytes32(salt),
                keccak256(
                    abi.encodePacked(
                        type(TrueWallet).creationCode,
                        abi.encode(entryPoint, walletOwner)
                    )
                )
            );
    }

    /// @notice Pause the WalletFactory to prevent new wallet creation. OnlyOwner
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpause the WalletFactory to allow new wallet creation. OnlyOwner
    function unpause() public onlyOwner {
        _unpause();
    }
}