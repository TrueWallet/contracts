// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {Ownable} from "solady/auth/Ownable.sol";
import {CREATE3} from "solady/utils/CREATE3.sol";
import {Pausable} from "openzeppelin-contracts/security/Pausable.sol";
import {IEntryPoint} from "account-abstraction/interfaces/IEntryPoint.sol";
import {TrueWallet} from "./TrueWallet.sol";
import {TrueWalletProxy} from "./TrueWalletProxy.sol";
import {WalletErrors} from "../common/Errors.sol";

/// @title TrueWalletFactory
/// @notice A factory contract for deploying and managing TrueWallet smart contracts using CREATE2 and CREATE3 for deterministic addresses.
/// @dev This contract allows for the creation of TrueWallet instances with predictable addresses.
contract TrueWalletFactory is Ownable, Pausable, WalletErrors {
    /// @notice Address of the wallet implementation contract.
    address public immutable walletImplementation;

    /// @notice Address of the entry point contract.
    address public immutable entryPoint;

    /// @notice Event emitted when a new TrueWallet is created.
    event TrueWalletCreation(TrueWallet wallet);

    /// @dev Initializes the factory with the wallet implementation and entry point addresses.
    /// @param _walletImpl Address of the wallet implementation contract.
    /// @param _owner Address of the owner of this factory contract.
    /// @param _entryPoint Address of the entry point contract.
    constructor(address _walletImpl, address _owner, address _entryPoint) Pausable() {
        if (_walletImpl == address(0) || _owner == address(0) || _entryPoint == address(0)) {
            revert ZeroAddressProvided();
        }
        walletImplementation = _walletImpl;
        entryPoint = _entryPoint;
        _setOwner(_owner);
    }

    /// @notice Deploy a new TrueWallet smart contract using CREATE3.
    /// @param _initializer Initialization data for the new wallet.
    /// @param _salt A unique salt value used in the CREATE3 operation for deterministic address generation.
    /// @return proxy The address of the newly created TrueWallet contract.
    function createWallet(bytes memory _initializer, bytes32 _salt) external whenNotPaused returns (TrueWallet proxy) {
        bytes memory deploymentData =
            abi.encodePacked(type(TrueWalletProxy).creationCode, uint256(uint160(walletImplementation)));
        
        proxy = TrueWallet(payable(address(CREATE3.deploy(_salt, deploymentData, 0))));
        
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let succ := call(gas(), proxy, 0, add(_initializer, 0x20), mload(_initializer), 0, 0)
            if eq(succ, 0) { revert(0, 0) }
        }

        emit TrueWalletCreation(proxy);
    }

    /// @notice Computes the deterministic address for a potential wallet deployment using CREATE3.
    /// @dev This doesn't deploy the wallet, just calculates its address using the provided salt.
    /// @param _salt A unique salt value used in the CREATE3 operation for deterministic address generation.
    /// @return proxy The address of the wallet that would be created using the provided salt.
    function getWalletAddress(bytes32 _salt) public view returns (address proxy) {
        proxy = CREATE3.getDeployed(_salt);
    }

    /// @notice Constructs the initializer payload for wallet creation.
    /// @dev This function prepares the data required to initialize a new wallet, encoding it for the constructor.
    /// @param _entryPoint The address of the EntryPoint contract for the new wallet.
    /// @param _walletOwner The owner address for the new wallet.
    /// @param _modules Array of initial module addresses with respective init data for the wallet.
    /// @return initializer The encoded initializer payload.
    function getInitializer(address _entryPoint, address _walletOwner, bytes[] calldata _modules)
        public
        pure
        returns (bytes memory initializer)
    {
        return abi.encodeWithSignature("initialize(address,address,bytes[])", _entryPoint, _walletOwner, _modules);
    }

    /// @notice Returns the proxy's creation code.
    /// @dev This public function is used to access the creation code of the TrueWalletProxy contract.
    /// @return A byte array representing the proxy's creation code.
    function proxyCode() external pure returns (bytes memory) {
        return _proxyCode();
    }

    /// @dev Provides the low-level creation code used by the `proxyCode` function.
    /// @return The creation code of the TrueWalletProxy contract.
    function _proxyCode() private pure returns (bytes memory) {
        return type(TrueWalletProxy).creationCode;
    }

    /// @notice Deposit funds into the EntryPoint associated with the factory.
    function deposit() public payable {
        IEntryPoint(entryPoint).depositTo{value: msg.value}(address(this));
    }

    /// @notice Withdraw funds from the EntryPoint.
    /// @param _withdrawAddress The address to send withdrawn funds to.
    /// @param _withdrawAmount The amount of funds to withdraw.
    function withdrawTo(address payable _withdrawAddress, uint256 _withdrawAmount) public onlyOwner {
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
