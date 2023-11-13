// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {Pausable} from "openzeppelin-contracts/security/Pausable.sol";
import {Create2} from "openzeppelin-contracts/utils/Create2.sol";
import {TrueWallet} from "./TrueWallet.sol";
import {TrueWalletProxy} from "./TrueWalletProxy.sol";
import {IEntryPoint} from "account-abstraction/interfaces/IEntryPoint.sol";
// import {IEntryPoint} from "../interfaces/IEntryPoint.sol";
import {WalletErrors} from "../common/Errors.sol";

/// @title TrueWalletFactory
/// @notice A factory contract for deploying and managing TrueWallet smart contracts.
/// @dev This contract allows for the creation of TrueWallet instances using the CREATE2 opcode for predictable addresses.
contract TrueWalletFactory is Ownable, Pausable, WalletErrors {
    /// @notice Address of the wallet implementation contract.
    address public immutable walletImplementation;

    /// @notice Address of the entry point contract.
    address public immutable entryPoint;

    /// @notice Event emitted when a new TrueWallet is created.
    event TrueWalletCreation(TrueWallet wallet);

    /// @param _walletImplementation Address of the wallet implementation contract.
    /// @param _owner Address of the owner of this factory contract.
    /// @param _entryPoint Address of the entry point contract.
    constructor(
        address _walletImplementation,
        address _owner,
        address _entryPoint
    ) Ownable() Pausable() {
        if (_walletImplementation == address(0) || _owner == address(0) || _entryPoint == address(0)) {
            revert ZeroAddressProvided();
        }

        walletImplementation = _walletImplementation;
        entryPoint = _entryPoint;
    }

    /// @notice Deploy a new TrueWallet smart contract.
    /// @param _entryPoint The address of the EntryPoint contract for the new wallet.
    /// @param _walletOwner The owner address for the new wallet.
    /// @param _upgradeDelay Delay (in seconds) before an upgrade can take effect.
    /// @param _modules Array of initial module addresses for the wallet.
    /// @param _salt A salt value used in the CREATE2 opcode for deterministic address generation.
    /// @return proxy The address of the newly created TrueWallet contract.
    function createWallet(
        address _entryPoint,
        address _walletOwner,
        uint32 _upgradeDelay,
        bytes[] calldata _modules,
        bytes32 _salt
    ) external whenNotPaused returns (TrueWallet proxy) {
        address walletAddress = getWalletAddress(
            _entryPoint,
            _walletOwner,
            _upgradeDelay,
            _modules,
            _salt
        );

        bytes memory deployInitData = abi.encodePacked(
            type(TrueWalletProxy).creationCode,
            abi.encode(
                walletImplementation,
                abi.encodeCall(
                    TrueWallet.initialize,
                    (_entryPoint, _walletOwner, _upgradeDelay, _modules)
                )
            )
        );

        // Determine if a wallet is already deployed at this address, if so return that
        uint256 codeSize = walletAddress.code.length;
        if (codeSize > 0) {
            return TrueWallet(payable(walletAddress));
        } else {
            // Deploy and initialize the wallet
            /// @solidity memory-safe-assembly
            assembly {
                proxy := create2(0x0, add(deployInitData, 0x20), mload(deployInitData), _salt)
            }
            if (address(proxy) == address(0)) {
                revert WalletFactory__Create2CallFailed();
            }

            emit TrueWalletCreation(proxy);
        }
    }

    /// @notice Computes the deterministic address for a potential wallet deployment using CREATE2.
    /// @dev This doesn't deploy the wallet, just calculates its address.
    /// @param _entryPoint The address of the EntryPoint contract for the new wallet.
    /// @param _walletOwner The owner address for the new wallet.
    /// @param _upgradeDelay Delay (in seconds) before an upgrade can take effect.
    /// @param _modules Array of initial module addresses for the wallet.
    /// @param _salt A salt value used in the CREATE2 opcode for deterministic address generation.
    /// @return Address of the wallet that would be created using the provided parameters.
    function getWalletAddress(
        address _entryPoint,
        address _walletOwner,
        uint32 _upgradeDelay,
        bytes[] calldata _modules,
        bytes32 _salt
    ) public view returns (address) {
        bytes memory deployInitData = abi.encodePacked(
            type(TrueWalletProxy).creationCode,
            abi.encode(
                walletImplementation,
                abi.encodeCall(
                    TrueWallet.initialize,
                    (_entryPoint, _walletOwner, _upgradeDelay, _modules)
                )
            )
        );

        return Create2.computeAddress(bytes32(_salt), keccak256(deployInitData));
    }

    /// @notice Deposit funds into the EntryPoint associated with the factory.
    function deposit() public payable {
        IEntryPoint(entryPoint).depositTo{value: msg.value}(address(this));
    }

    /// @notice Withdraw funds from the EntryPoint.
    /// @param _withdrawAddress The address to send withdrawn funds to.
    /// @param _withdrawAmount The amount of funds to withdraw.
    function withdrawTo(address payable _withdrawAddress, uint256 _withdrawAmount) public onlyOwner{
        IEntryPoint(entryPoint).withdrawTo(_withdrawAddress, _withdrawAmount);
    }

    /// @dev Add to the account's stake - amount and delay any pending unstake is first cancelled.
    /// @param _unstakeDelaySec the new lock duration before the deposit can be withdrawn.
    function addStake(uint32 _unstakeDelaySec) external payable onlyOwner {
        IEntryPoint(entryPoint).addStake{value: msg.value}(_unstakeDelaySec);
    }

    /// @dev Unlock staked funds from the EntryPoint contract.
    function unlockStake() external onlyOwner {
        IEntryPoint(entryPoint).unlockStake();
    }

    /// @dev Withdraw unlocked staked funds from the EntryPoint contract.
    /// @param _withdrawAddress The address to send withdrawn funds to.
    function withdrawStake(address payable _withdrawAddress) external onlyOwner {
        IEntryPoint(entryPoint).withdrawStake(_withdrawAddress);
    }

    /// @notice Pause the factory to prevent new wallet creation.
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Resume operations and allow new wallet creation.
    function unpause() public onlyOwner {
        _unpause();
    }
}
