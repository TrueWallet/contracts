# DeployCodeGenerator
[Git Source](https://github.com/TrueWallet/contracts/blob/5a052bc82f5ecbfdc3b7fb992a66fa5b770bcc4b/src/deployer/DeployCodeGenerator.sol)

Provides functions to generate creation bytecode for various contracts.


## Functions
### getTrueWalletFactoryCode

Retrieves the creation bytecode of the TrueWalletFactory contract.

*Combines TrueWalletFactory creation bytecode with encoded constructor parameters.*


```solidity
function getTrueWalletFactoryCode(address _walletImpl, address _owner, address _entryPoint)
    external
    pure
    returns (bytes memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_walletImpl`|`address`|Address of the wallet implementation contract.|
|`_owner`|`address`|Address of the owner for the TrueWalletFactory contract.|
|`_entryPoint`|`address`|Address of the entry point contract.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes`|bytecode The bytecode used to deploy the TrueWalletFactory contract.|


### getTrueContractManagerCode

Retrieves the creation bytecode of the TrueContractManager contract.

*Combines TrueContractManager creation bytecode with encoded constructor parameter.*


```solidity
function getTrueContractManagerCode(address _owner) external pure returns (bytes memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_owner`|`address`|Address of the owner for the TrueContractManager contract.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes`|bytecode The bytecode used to deploy the TrueContractManager contract.|


### getSecurityControlModuleCode

Retrieves the creation bytecode of the SecurityControlModule contract.

*Combines SecurityControlModule creation bytecode with encoded constructor parameter.*


```solidity
function getSecurityControlModuleCode(address _trueContractManager) external pure returns (bytes memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_trueContractManager`|`address`|Address of the TrueContractManager contract.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes`|bytecode The bytecode used to deploy the SecurityControlModule contract.|


### getSocialRecoveryModuleCode

Retrieves the creation bytecode of the SocialRecoveryModule contract.

*Returns the creation bytecode of the SocialRecoveryModule contract.*


```solidity
function getSocialRecoveryModuleCode() external pure returns (bytes memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes`|bytecode The bytecode used to deploy the SocialRecoveryModule contract.|


### getTrueWalletImplCode

Retrieves the creation bytecode of the TrueWallet contract.

*Returns the creation bytecode of the TrueWallet contract.*


```solidity
function getTrueWalletImplCode() external pure returns (bytes memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes`|bytecode The bytecode used to deploy the TrueWallet contract.|


