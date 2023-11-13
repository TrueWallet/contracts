# IModule
[Git Source](https://github.com/TrueWallet/contracts/blob/43e94f0622a36448f24323cfe74a0e2604784f80/src/interfaces/IModule.sol)

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


