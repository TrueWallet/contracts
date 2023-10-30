# TrueWallet

[Git Source](https://github.com/TrueWallet/contracts/blob/b38849a85d65fd71e42df8fc5190581d11c83fec/src/wallet/TrueWallet.sol)

**Inherits:**
[IAccount](/src/interfaces/IAccount.sol/interface.IAccount.md), [Initializable](/src/utils/Initializable.sol/abstract.Initializable.md), [SocialRecovery](/src/guardian/SocialRecovery.sol/contract.SocialRecovery.md), [LogicUpgradeControl](/src/utils/LogicUpgradeControl.sol/contract.LogicUpgradeControl.md), [TokenCallbackHandler](/src/callback/TokenCallbackHandler.sol/contract.TokenCallbackHandler.md), [WalletErrors](/src/common/Errors.sol/contract.WalletErrors.md)

_This contract provides functionality to execute AA (ERC-4337) UserOperetion
It allows to receive and manage assets using the owner account of the smart contract wallet_

## Functions

### onlyOwner

_Only from EOA owner, or through the account itself (which gets redirected through execute())_

```solidity
modifier onlyOwner();
```

### onlyEntryPointOrOwner

Validate that only the entryPoint or Owner is able to call a method

```solidity
modifier onlyEntryPointOrOwner();
```

### constructor

_This prevents initialization of the implementation contract itself_

```solidity
constructor();
```

### initialize

Initialize function to setup the true wallet contract

```solidity
function initialize(address _entryPoint, address _owner, uint32 _upgradeDelay) public initializer;
```

**Parameters**

| Name            | Type      | Description                            |
| --------------- | --------- | -------------------------------------- |
| `_entryPoint`   | `address` | trused entrypoint                      |
| `_owner`        | `address` | wallet sign key address                |
| `_upgradeDelay` | `uint32`  | upgrade delay which update take effect |

### receive

_This function is a special fallback function that is triggered when the contract receives Ether_

```solidity
receive() external payable;
```

### entryPoint

Returns the entryPoint address

```solidity
function entryPoint() public view returns (IEntryPoint);
```

### nonce

Returns the contract nonce

```solidity
function nonce() public view returns (uint256);
```

### owner

Returns the contract owner

```solidity
function owner() public view returns (address);
```

### setEntryPoint

Set the entrypoint contract, restricted to onlyOwner

```solidity
function setEntryPoint(address _newEntryPoint) external onlyOwner;
```

### validateUserOp

Validate that the userOperation is valid

```solidity
function validateUserOp(
    UserOperation calldata userOp,
    bytes32 userOpHash,
    address aggregator,
    uint256 missingWalletFunds
) external override onlyEntryPointOrOwner returns (uint256 deadline);
```

**Parameters**

| Name                 | Type            | Description                                                          |
| -------------------- | --------------- | -------------------------------------------------------------------- |
| `userOp`             | `UserOperation` | - ERC-4337 User Operation                                            |
| `userOpHash`         | `bytes32`       | - Hash of the user operation, entryPoint address and chainId         |
| `aggregator`         | `address`       | - Signature aggregator                                               |
| `missingWalletFunds` | `uint256`       | - Amount of ETH to pay the EntryPoint for processing the transaction |

### execute

Method called by entryPoint or owner to execute the calldata supplied by a wallet

```solidity
function execute(address target, uint256 value, bytes calldata payload) external onlyEntryPointOrOwner;
```

**Parameters**

| Name      | Type      | Description                                      |
| --------- | --------- | ------------------------------------------------ |
| `target`  | `address` | - Address to send calldata payload for execution |
| `value`   | `uint256` | - Amount of ETH to forward to target             |
| `payload` | `bytes`   | - Calldata to send to target for execution       |

### executeBatch

Execute a sequence of transactions, called directly by owner or by entryPoint

```solidity
function executeBatch(address[] calldata target, uint256[] calldata value, bytes[] calldata payload)
    external
    onlyEntryPointOrOwner;
```

### transferOwnership

Transfer ownership by owner

```solidity
function transferOwnership(address newOwner) public virtual onlyOwner;
```

### preUpgradeTo

preUpgradeTo is called before upgrading the wallet

```solidity
function preUpgradeTo(address newImplementation) external onlyEntryPointOrOwner;
```

### addGuardianWithThreshold

Lets the owner set guardians and threshold for the wallet

```solidity
function addGuardianWithThreshold(address[] calldata guardians, uint16 threshold) external onlyOwner;
```

**Parameters**

| Name        | Type        | Description                                         |
| ----------- | ----------- | --------------------------------------------------- |
| `guardians` | `address[]` | List of guardians' addresses                        |
| `threshold` | `uint16`    | Required number of guardians to confirm replacement |

### revokeGuardianWithThreshold

Lets the owner revoke a guardian from the wallet and change threshold respectively

```solidity
function revokeGuardianWithThreshold(address guardian, uint16 threshold) external onlyOwner;
```

**Parameters**

| Name        | Type      | Description                                                 |
| ----------- | --------- | ----------------------------------------------------------- |
| `guardian`  | `address` | The guardian address to revoke                              |
| `threshold` | `uint16`  | The new required number of guardians to confirm replacement |

### transferETH

Transfer ETH out of the wallet. Permissioned to only the owner

```solidity
function transferETH(address payable to, uint256 amount) external onlyOwner;
```

### transferERC20

Transfer ERC20 tokens out of the wallet. Permissioned to only the owner

```solidity
function transferERC20(address token, address to, uint256 amount) external onlyOwner;
```

### transferERC721

Transfer ERC721 tokens out of the wallet. Permissioned to only the owner

```solidity
function transferERC721(address collection, uint256 tokenId, address to) external onlyOwner;
```

### transferERC1155

Transfer ERC1155 tokens out of the wallet. Permissioned to only the owner

```solidity
function transferERC1155(address collection, uint256 tokenId, address to, uint256 amount) external onlyOwner;
```

### getDeposite

Returns the wallet's deposit in EntryPoint

```solidity
function getDeposite() public view returns (uint256);
```

### addDeposite

Add to the deposite of the wallet in EntryPoint. Deposit is used to pay user gas fees

```solidity
function addDeposite() public payable;
```

### withdrawDepositeTo

Withdraw funds from the wallet's deposite in EntryPoint

```solidity
function withdrawDepositeTo(address payable to, uint256 amount) public onlyOwner;
```

### \_validateSignature

Validate the signature of the userOperation

```solidity
function _validateSignature(UserOperation calldata userOp, bytes32 userOpHash) internal view;
```

### \_payPrefund

Pay the EntryPoint in ETH ahead of time for the transaction that it will execute
Amount to pay may be zero, if the entryPoint has sufficient funds or if a paymaster is used
to pay the entryPoint through other means

```solidity
function _payPrefund(uint256 amount) internal;
```

**Parameters**

| Name     | Type      | Description                           |
| -------- | --------- | ------------------------------------- |
| `amount` | `uint256` | - Amount of ETH to pay the entryPoint |

### \_call

Perform and validate the function call

```solidity
function _call(address target, uint256 value, bytes memory data) internal;
```

### \_authorizeUpgrade

_Required by the OZ UUPS module_

```solidity
function _authorizeUpgrade(address) internal onlyOwner;
```

### isValidSignature

Support ERC-1271, verifies that the signer is the owner of the signing contract

```solidity
function isValidSignature(bytes32 hash, bytes memory signature) public view returns (bytes4 magicValue);
```

### supportsInterface

Support ERC165, query if a contract implements an interface

```solidity
function supportsInterface(bytes4 _interfaceID) public view override(TokenCallbackHandler) returns (bool);
```

## Events

### AccountInitialized

All state variables are stored in AccountStorage.Layout with specific storage slot to avoid storage collision

```solidity
event AccountInitialized(address indexed account, address indexed entryPoint, address owner, uint32 upgradeDelay);
```

### UpdateEntryPoint

```solidity
event UpdateEntryPoint(address indexed newEntryPoint, address indexed oldEntryPoint);
```

### PayPrefund

```solidity
event PayPrefund(address indexed payee, uint256 amount);
```

### OwnershipTransferred

```solidity
event OwnershipTransferred(address indexed sender, address indexed newOwner);
```

### ReceivedETH

```solidity
event ReceivedETH(address indexed sender, uint256 indexed amount);
```

### TransferedETH

```solidity
event TransferedETH(address indexed to, uint256 amount);
```

### TransferedERC20

```solidity
event TransferedERC20(address token, address indexed to, uint256 amount);
```

### TransferedERC721

```solidity
event TransferedERC721(address indexed collection, uint256 indexed tokenId, address indexed to);
```

### TransferedERC1155

```solidity
event TransferedERC1155(address indexed collection, uint256 indexed tokenId, uint256 amount, address indexed to);
```
