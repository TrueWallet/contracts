# ITrueContractManager
[Git Source](https://github.com/TrueWallet/contracts/blob/db2e75cb332931da5fdaa38bec9e4d367be1d851/src/registry/ITrueContractManager.sol)

*Interface to manage and check permissions for TrueContract modules*


## Functions
### isTrueModule

Checks if the address is a true module that is registered in the system


```solidity
function isTrueModule(address module) external view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`module`|`address`|Address of the module to be checked|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|bool Returns true if the provided address is an active registered module, otherwise false|


## Events
### TrueContractManagerAdded
*Emitted when a new module is added*


```solidity
event TrueContractManagerAdded(address indexed module);
```

### TrueContractManagerRemoved
*Emitted when an existing module is removed*


```solidity
event TrueContractManagerRemoved(address indexed module);
```
