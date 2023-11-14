# IModule
[Git Source](https://github.com/TrueWallet/contracts/blob/3a8d1f53b9460a762889129a9214639685ad5b95/src/interfaces/IModule.sol)

**Inherits:**
IERC165


## Functions
### walletInit

Initializes the module for the sender's wallet with provided data.

*Implementing contracts should define how a module gets initialized for a wallet.*


```solidity
function walletInit(bytes calldata data) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`data`|`bytes`|Initialization data.|


### walletDeInit

De-initializes the module for the sender's wallet.

*Implementing contracts should define how a module gets de-initialized for a wallet.*


```solidity
function walletDeInit() external;
```

### requiredFunctions

Lists the required functions for the module.

*Implementing contracts should return an array of function selectors representing the functions required by the module.*


```solidity
function requiredFunctions() external pure returns (bytes4[] memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes4[]`|An array of function selectors.|


