# IAggregator
[Git Source](https://github.com/TrueWallet/contracts/blob/843930f01013ad22976a2d653f9d67aaa82d54f4/src/interfaces/IAggregator.sol)

Aggregated Signatures validator.


## Functions
### validateSignatures

Validate aggregated signature.
Revert if the aggregated signature does not match the given list of operations.


```solidity
function validateSignatures(UserOperation[] calldata userOps, bytes calldata signature) external view;
```

### validateUserOpSignature

Validate signature of a single userOp
This method is should be called by bundler after EntryPoint.simulateValidation() returns (reverts) with ValidationResultWithAggregation.
First it validates the signature over the userOp. Then it returns data to be used when creating the handleOps.


```solidity
function validateUserOpSignature(UserOperation calldata userOp) external view returns (bytes memory sigForUserOp);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`userOp`|`UserOperation`|the userOperation received from the user.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`sigForUserOp`|`bytes`|the value to put into the signature field of the userOp when calling handleOps. (usually empty, unless account and aggregator support some kind of "multisig"|


### aggregateSignatures

Aggregate multiple signatures into a single value.
This method is called off-chain to calculate the signature to pass with handleOps().
Bundler MAY use optimized custom code perform this aggregation.


```solidity
function aggregateSignatures(UserOperation[] calldata userOps)
    external
    view
    returns (bytes memory aggregatedSignature);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`userOps`|`UserOperation[]`|array of UserOperations to collect the signatures from.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`aggregatedSignature`|`bytes`|the aggregated signature.|


