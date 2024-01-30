// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {Pausable} from "openzeppelin-contracts/security/Pausable.sol";
import {Create2} from "openzeppelin-contracts/utils/Create2.sol";
import {IEntryPoint} from "account-abstraction/interfaces/IEntryPoint.sol";
import {TrueWallet} from "./TrueWallet.sol";
import {TrueWalletProxy} from "./TrueWalletProxy.sol";
import {WalletErrors} from "../common/Errors.sol";

/// @title TrueWalletFactory
/// @notice A factory contract for deploying and managing TrueWallet smart contracts.
/// @dev This contract allows for the creation of TrueWallet instances using the CREATE2 opcode for predictable addresses.
contract TrueWalletFactory is Ownable, Pausable, WalletErrors {
    /// @notice Address of the wallet implementation contract.
    /// @dev This private immutable variable stores the address of the wallet implementation contract.
    ///      The address is converted from address to uint256 to fit the specific storage optimization needs.
    ///      This address is used when creating new wallet instances or when referring to the wallet logic.
    uint256 private immutable _WALLETIMPL;

    /// @notice Address of the entry point contract.
    address public immutable entryPoint;

    /// @notice Event emitted when a new TrueWallet is created.
    event TrueWalletCreation(TrueWallet wallet);

    /// @dev Initializes the factory with the wallet implementation and entry point addresses.
    /// @param _walletImpl Address of the wallet implementation contract.
    /// @param _owner Address of the owner of this factory contract.
    /// @param _entryPoint Address of the entry point contract.
    constructor(address _walletImpl, address _owner, address _entryPoint) Ownable() Pausable() {
        if (_walletImpl == address(0) || _owner == address(0) || _entryPoint == address(0)) {
            revert ZeroAddressProvided();
        }
        _WALLETIMPL = uint256(uint160(_walletImpl));
        entryPoint = _entryPoint;
        _transferOwnership(_owner);
    }

    /// @notice Deploy a new TrueWallet smart contract.
    /// @param _entryPoint The address of the EntryPoint contract for the new wallet.
    /// @param _walletOwner The owner address for the new wallet.
    /// @param _modules Array of initial module addresses for the wallet.
    /// @param _salt A salt value used in the CREATE2 opcode for deterministic address generation.
    /// @return proxy The address of the newly created TrueWallet contract.
    function createWallet(address _entryPoint, address _walletOwner, bytes[] calldata _modules, bytes32 _salt)
        external
        whenNotPaused
        returns (TrueWallet proxy)
    {
        bytes memory deploymentData =
            abi.encodePacked(type(TrueWalletProxy).creationCode, _WALLETIMPL);
        bytes32 salt = _calcSalt(_entryPoint, _walletOwner, _modules, _salt);

        // solhint-disable-next-line no-inline-assembly
        assembly {
            proxy := create2(0x0, add(deploymentData, 0x20), mload(deploymentData), salt)
        }

        if (address(proxy) == address(0)) {
            revert();
        }

        bytes memory initializer = getInitializer(_entryPoint, _walletOwner, _modules);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let succ := call(gas(), proxy, 0, add(initializer, 0x20), mload(initializer), 0, 0)
            if eq(succ, 0) { revert(0, 0) }
        }

        emit TrueWalletCreation(proxy);
    }

    /// @notice Computes the deterministic address for a potential wallet deployment using CREATE2.
    /// @dev This doesn't deploy the wallet, just calculates its address.
    /// @param _entryPoint The address of the EntryPoint contract for the new wallet.
    /// @param _walletOwner The owner address for the new wallet.
    /// @param _modules Array of initial module addresses for the wallet.
    /// @param _salt A salt value used in the CREATE2 opcode for deterministic address generation.
    /// @return proxy address of the wallet that would be created using the provided parameters.
    function getWalletAddress(address _entryPoint, address _walletOwner, bytes[] calldata _modules, bytes32 _salt)
        public
        view
        returns (address proxy)
    {
        bytes memory deploymentData =
            abi.encodePacked(type(TrueWalletProxy).creationCode, _WALLETIMPL);
        bytes32 salt = _calcSalt(_entryPoint, _walletOwner, _modules, _salt);
        proxy = Create2.computeAddress(salt, keccak256(deploymentData));
    }

    /// @notice Returns the wallet implementation address.
    /// @return Address of the wallet implementation.
    function walletImplementation() external view returns (address) {
        return address(uint160(_WALLETIMPL));
    }

    /// @notice Calculates the salt value used in the deterministic address generation.
    /// @dev This is an internal function used to compute the salt by hashing initialization parameters together with the provided _salt.
    function _calcSalt(address _entryPoint, address _walletOwner, bytes[] calldata _modules, bytes32 _salt)
        internal
        pure
        returns (bytes32 salt)
    {
        return keccak256(abi.encodePacked(keccak256(getInitializer(_entryPoint, _walletOwner, _modules)), _salt));
    }

    /// @notice Constructs the initializer payload for wallet creation.
    /// @dev This function prepares the data required to initialize a new wallet, encoding it for the constructor.
    function getInitializer(address _entryPoint, address _walletOwner, bytes[] calldata _modules)
        internal
        pure
        returns (bytes memory initializer)
    {
        return abi.encodeWithSignature("initialize(address,address,bytes[])", _entryPoint, _walletOwner, _modules);
    }

    /// @notice Returns the proxy's creation code.
    /// @dev This public function is used to access the creation code of the TrueWalletProxy contract.
    ///      It's primarily utilized by truewalletlib to calculate the TrueWallet address.
    /// @return A byte array representing the proxy's creation code.
    function proxyCode() external pure returns (bytes memory) {
        return _proxyCode();
    }

    /// @notice Retrieves the creation code of the TrueWalletProxy contract.
    /// @dev This private function provides the low-level creation code used by the `proxyCode` function.
    /// @return A byte array containing the creation code of the TrueWalletProxy contract.
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
