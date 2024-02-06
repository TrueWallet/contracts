# Deployer
[Git Source](https://github.com/TrueWallet/contracts/blob/5a052bc82f5ecbfdc3b7fb992a66fa5b770bcc4b/src/deployer/Deployer.sol)

**Inherits:**
Ownable

A contract for deploying other contracts using CREATE3 to achieve deterministic addresses.

*This contract utilizes the CREATE3 library to enable deterministic deployment of contracts, allowing for the same contract address across different EVM-compatible blockchains.*


## Functions
### constructor

*Initializes the Deployer contract, setting the initial owner to the provided address.*


```solidity
constructor(address _owner);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_owner`|`address`|The address that will be granted ownership of this contract, capable of performing deployments.|


### deploy

Deploys a contract using a specific salt and creation code.

*This function can only be called by the owner of the contract.*


```solidity
function deploy(bytes32 _salt, bytes calldata _creationCode) external onlyOwner returns (address contractAddress);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_salt`|`bytes32`|A unique salt value used to determine the contract's address.|
|`_creationCode`|`bytes`|The bytecode (including constructor parameters) of the contract to be deployed.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`contractAddress`|`address`|The address of the deployed contract.|


### getContractAddress

Computes and returns the address of a contract deployed with a given salt.

*This function does not change the state and can be called by anyone.*


```solidity
function getContractAddress(bytes32 _salt) external view returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_salt`|`bytes32`|The salt value used in the contract's deployment.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The address of the contract deployed with the given salt.|


## Events
### ContractDeployed
Emitted when a contract is successfully deployed.


```solidity
event ContractDeployed(address indexed contractAddress);
```

