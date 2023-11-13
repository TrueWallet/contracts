// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {IEntryPoint, UserOperation} from "account-abstraction/interfaces/IEntryPoint.sol";
// import {UserOperation} from "account-abstraction/interfaces/UserOperation.sol";
import {IWallet} from "./IWallet.sol";
// import {IEntryPoint, UserOperation} from "account-abstraction/interfaces/IEntryPoint.sol";
// import {UserOperation} from "account-abstraction/interfaces/UserOperation.sol";
import {AccountStorage} from "src/utils/AccountStorage.sol";
import {LogicUpgradeControl} from "src/utils/LogicUpgradeControl.sol";
import {TokenCallbackHandler} from "src/callback/TokenCallbackHandler.sol";
import {Initializable} from "openzeppelin-contracts/proxy/utils/Initializable.sol";
import {ECDSA, SignatureChecker} from "openzeppelin-contracts/utils/cryptography/SignatureChecker.sol";
import {ModuleManager} from "src/base/ModuleManager.sol";
import {OwnerManager} from "src/base/OwnerManager.sol";
import {TokenManager} from "src/base/TokenManager.sol";
import {Authority} from "src/authority/Authority.sol";

/// @title TrueWallet - Smart contract wallet compatible with ERC-4337
/// @dev This contract provides functionality to execute AA (ERC-4337) UserOperetion
///      It allows to receive and manage assets using the owner account of the smart contract wallet
contract TrueWallet is
    IWallet,
    Initializable,
    Authority,
    ModuleManager,
    OwnerManager,
    TokenManager,
    LogicUpgradeControl,
    TokenCallbackHandler
{
    /// @notice All state variables are stored in AccountStorage. Layout with specific storage slot to avoid storage collision.
    using AccountStorage for AccountStorage.Layout;

    /////////////////  EVENTS ///////////////

    event AccountInitialized(address indexed account, address indexed entryPoint, address owner, uint32 upgradeDelay);
    event UpdateEntryPoint(address indexed newEntryPoint, address indexed oldEntryPoint);
    event OwnershipTransferred(address indexed sender, address indexed newOwner);
    event ReceivedETH(address indexed sender, uint256 indexed amount);

    /////////////////  MODIFIERS ///////////////

    /// @dev Only from EOA owner, or through the account itself (which gets redirected through execute())
    modifier onlyOwner() {
        if (!_isOwner(msg.sender) && msg.sender != address(this)) {
            revert InvalidOwner();
        }
        _;
    }

    /// @notice Validate that only the entryPoint or Owner is able to call a method
    modifier onlyEntryPointOrOwner() {
        if (msg.sender != address(entryPoint()) && !_isOwner(msg.sender) && msg.sender != address(this)) {
            revert InvalidEntryPointOrOwner();
        }
        _;
    }

    /////////////////  CONSTRUCTOR & INITIALIZE ///////////////

    /// @dev This prevents initialization of the implementation contract itself
    constructor() {
        _disableInitializers();
        // solhint-disable-previous-line no-empty-blocks
    }

    /// @notice Initialize function to setup the true wallet contract
    /// @param  _entryPoint trused entrypoint
    /// @param  _owner wallet sign key address
    /// @param  _upgradeDelay upgrade delay which update take effect
    /// @param _modules The list of encoded modules to be added and its associated initialization data.
    function initialize(address _entryPoint, address _owner, uint32 _upgradeDelay, bytes[] calldata _modules)
        public
        initializer
    {
        if (_entryPoint == address(0) || _owner == address(0)) {
            revert ZeroAddressProvided();
        }

        _addOwner(_owner);

        AccountStorage.Layout storage layout = AccountStorage.layout();
        layout.entryPoint = IEntryPoint(_entryPoint);

        if (_upgradeDelay < 2 days) revert InvalidUpgradeDelay();
        layout.logicUpgrade.upgradeDelay = _upgradeDelay;

        for (uint256 i; i < _modules.length;) {
            _addModule(_modules[i]);
            unchecked {
                i++;
            }
        }

        emit AccountInitialized(address(this), address(_entryPoint), _owner, _upgradeDelay);
    }

    /////////////////  FUNCTIONS ///////////////

    /// @dev This function is a special fallback function that is triggered when the contract receives Ether
    receive() external payable {
        emit ReceivedETH(msg.sender, msg.value);
    }

    /// @notice Returns the entryPoint address
    function entryPoint() public view returns (address) {
        return address(AccountStorage.layout().entryPoint);
    }

    /// @notice Returns the contract nonce
    function nonce() public view returns (uint256) {
        return IEntryPoint(entryPoint()).getNonce(address(this), 0);
    }

    /// @notice Set the entrypoint contract, restricted to onlyOwner
    function setEntryPoint(address _newEntryPoint) external onlyOwner {
        if (_newEntryPoint == address(0)) revert ZeroAddressProvided();

        emit UpdateEntryPoint(_newEntryPoint, address(entryPoint()));

        AccountStorage.Layout storage layout = AccountStorage.layout();
        layout.entryPoint = IEntryPoint(_newEntryPoint);
    }

    /// @notice Validate that the userOperation is valid
    /// @param userOp - ERC-4337 User Operation
    /// @param userOpHash - Hash of the user operation, entryPoint address and chainId
    /// @param missingWalletFunds - Amount of ETH to pay the EntryPoint for processing the transaction
    function validateUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 missingWalletFunds)
        external
        override
        onlyEntryPointOrOwner
        returns (uint256 validationData)
    {
        // Validate signature
        validationData = _validateSignature(userOp, userOpHash);
        require(userOp.nonce < type(uint64).max, "account: nonsequential nonce");
        _payPrefund(missingWalletFunds);
    }

    /// @notice Method called by entryPoint or owner to execute the calldata supplied by a wallet
    /// @param target - Address to send calldata payload for execution
    /// @param value - Amount of ETH to forward to target
    /// @param payload - Calldata to send to target for execution
    function execute(address target, uint256 value, bytes calldata payload) external onlyEntryPointOrOwner {
        _call(target, value, payload);
    }

    /// @notice Execute a sequence of transactions, called directly by owner or by entryPoint. Maximum 8.
    function executeBatch(address[] calldata target, uint256[] calldata value, bytes[] calldata payload)
        external
        onlyEntryPointOrOwner
    {
        if (target.length != payload.length || payload.length != value.length) {
            revert LengthMismatch();
        }
        for (uint256 i; i < target.length;) {
            _call(target[i], value[i], payload[i]);
            unchecked {
                i++;
            }
        }
    }

    /// @notice preUpgradeTo is called before upgrading the wallet
    function preUpgradeTo(address newImplementation) external onlyEntryPointOrOwner {
        _preUpgradeTo(newImplementation);
    }

    /////////////////  DEPOSITE MANAGER ///////////////

    /// @notice Returns the wallet's deposit in EntryPoint
    function getDeposite() public view returns (uint256) {
        return IEntryPoint(entryPoint()).balanceOf(address(this));
    }

    /// @notice Add to the deposite of the wallet in EntryPoint. Deposit is used to pay user gas fees
    function addDeposite() public payable {
        IEntryPoint(entryPoint()).depositTo{value: msg.value}(address(this));
    }

    /// @notice Withdraw funds from the wallet's deposite in EntryPoint
    function withdrawDepositeTo(address payable to, uint256 amount) public onlyOwner {
        IEntryPoint(entryPoint()).withdrawTo(to, amount);
    }

    /////////////////  INTERNAL METHODS ///////////////

    /// @notice Validate the signature of the userOperation
    function _validateSignature(UserOperation calldata userOp, bytes32 userOpHash)
        internal
        virtual
        returns (uint256 validationData)
    {
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(userOpHash);
        address signer = ECDSA.recover(messageHash, userOp.signature);
        if (!_isOwner(signer)) {
            return 1;
        }
        return 0;
    }

    /// @notice Sends to the entrypoint (msg.sender) the missing funds for this transaction.
    /// Pay the EntryPoint in ETH ahead of time for the transaction that it will execute
    /// Amount to pay may be zero, if the entryPoint has sufficient funds or if a paymaster is used
    /// to pay the entryPoint through other means.
    /// (E.g. send to the entryPoint more than the minimum required, so that in future transactions
    /// it will not be required to send again)
    /// @param missingAccountFunds - The min minimum value this method should send the entrypoint.
    /// This value MAY be zero, in case there is enough deposit, or the userOp has a paymaster.
    function _payPrefund(uint256 missingAccountFunds) internal {
        if (missingAccountFunds != 0) {
            (bool success,) = payable(msg.sender).call{value: missingAccountFunds, gas: type(uint256).max}("");
            (success);
            // ignore failure (its EntryPoint's job to verify, not account.)
        }
    }

    /// @notice Perform and validate the function call
    function _call(address target, uint256 value, bytes memory data) internal {
        (bool success, bytes memory result) = target.call{value: value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    /// @dev Required by the OZ UUPS module
    function _authorizeUpgrade(address) internal onlyOwner {}

    /// @dev Returns true if the caller is the wallet owner. Compatibility with OwnerAuth
    function _isOwner() internal view override returns (bool) {
        if (_isOwner(msg.sender)) {
            return true;
        }
        return false;
    }

    /////////////////  SUPPORT INTERFACES ///////////////

    /// @notice Support ERC-1271, verifies that the signer is the owner of the signing contract
    function isValidSignature(bytes32 hash, bytes memory signature) public view returns (bytes4 magicValue) {
        return ECDSA.recover(hash, signature) == listOwner()[0] ? this.isValidSignature.selector : bytes4(0);
    }

    /// @notice Support ERC165, query if a contract implements an interface
    function supportsInterface(bytes4 _interfaceID) public view override(TokenCallbackHandler) returns (bool) {
        return supportsInterface(_interfaceID);
    }
}
