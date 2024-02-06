# IWallet
[Git Source](https://github.com/TrueWallet/contracts/blob/5a052bc82f5ecbfdc3b7fb992a66fa5b770bcc4b/src/interfaces/IWallet.sol)

**Inherits:**
[IAccount](/src/interfaces/IAccount.sol/interface.IAccount.md), [IModuleManager](/src/interfaces/IModuleManager.sol/interface.IModuleManager.md), [IOwnerManager](/src/interfaces/IOwnerManager.sol/interface.IOwnerManager.md)

Interface for a smart wallet contract, providing functionalities like executing transactions, managing nonce, and validating signatures.


## Functions
### entryPoint

Retrieves the address of the EntryPoint connected to the wallet.


```solidity
function entryPoint() external view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The address of the EntryPoint contract.|


### nonce

Gets the current nonce of the wallet.


```solidity
function nonce() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The current nonce value.|


### execute

Executes a single user operation.


```solidity
function execute(address target, uint256 value, bytes calldata payload) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`target`|`address`|The address of the contract to be called.|
|`value`|`uint256`|The amount of Ether to send with the call.|
|`payload`|`bytes`|The calldata for the operation.|


### executeBatch

Executes a batch of user operations.


```solidity
function executeBatch(address[] calldata target, uint256[] calldata value, bytes[] calldata payload) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`target`|`address[]`|An array of addresses of the contracts to be called.|
|`value`|`uint256[]`|An array of amounts of Ether to send with each call.|
|`payload`|`bytes[]`|An array of call data for each operation.|


### isValidSignature

Verifies if a given signature is valid for a given message hash.


```solidity
function isValidSignature(bytes32 messageHash, bytes memory signature) external view returns (bytes4);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`messageHash`|`bytes32`|The hash of the message that was signed.|
|`signature`|`bytes`|The signature to validate.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes4`|Returns `bytes4(0x1626ba7e)` if the signature is valid, otherwise reverts.|


