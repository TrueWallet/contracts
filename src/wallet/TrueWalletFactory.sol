// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {Pausable} from "openzeppelin-contracts/security/Pausable.sol";
import {Create2} from "openzeppelin-contracts/utils/Create2.sol";
import {TrueWalletUpgradeable} from "src/wallet/TrueWalletUpgradeable.sol";
import {TrueWalletProxy} from "src/wallet/TrueWalletProxy.sol";

/// @title TrueWalletFactory contract to deploy user smart wallets
contract TrueWalletFactory is Ownable, Pausable {
    address public immutable walletImplementation;

    error ZeroAddressProvided();

    constructor(address _walletImplementation, address _owner) Ownable() Pausable() {
        if (_walletImplementation == address(0) || _owner == address(0)) {
            revert ZeroAddressProvided();
        }

        walletImplementation = _walletImplementation;
    }

    /// @notice Deploy a smart wallet, with an entryPoint and Owner specified by the user
    ///         Intended that all wallets are deployed through this factory, so if no initCode is passed
    ///         then just returns the CREATE2 computed address
    function createWallet(
        address entryPoint,
        address walletOwner,
        bytes32 salt
    ) external whenNotPaused returns (TrueWalletUpgradeable) {
        address walletAddress = getWalletAddress(entryPoint, walletOwner, salt);

        // Determine if a wallet is already deployed at this address, if so return that
        uint256 codeSize = walletAddress.code.length;
        if (codeSize > 0) {
            return TrueWalletUpgradeable(payable(walletAddress));
        } else {
            // Deploy the wallet
            TrueWalletUpgradeable wallet = TrueWalletUpgradeable(payable(new TrueWalletProxy{salt: bytes32(salt)}(
                walletImplementation,
                abi.encodeCall(
                    TrueWalletUpgradeable.initialize,
                    (entryPoint, walletOwner)
                )))
            );

            return wallet;
        }
    }

    /// @notice Deterministically compute the address of a smart wallet using Create2
    function getWalletAddress(
        address entryPoint,
        address walletOwner,
        bytes32 salt
    ) public view returns (address) {
        bytes memory deploymentData = abi.encodePacked(
            type(TrueWalletProxy).creationCode,
            abi.encode(
                walletImplementation,
                abi.encodeCall(
                    TrueWalletUpgradeable.initialize,
                    (entryPoint, walletOwner)
                )
            )
        );

        return Create2.computeAddress(bytes32(salt), keccak256(deploymentData));
    }

    /// @notice Pause the TrueWalletFactory to prevent new wallet creation. OnlyOwner
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpause the TrueWalletFactory to allow new wallet creation. OnlyOwner
    function unpause() public onlyOwner {
        _unpause();
    }
}