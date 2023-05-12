# SenderCreator
[Git Source](https://github.com/TrueWallet/contracts/blob/843930f01013ad22976a2d653f9d67aaa82d54f4/src/entrypoint/SenderCreator.sol)

Helper contract for EntryPoint, to call userOp.initCode from a "neutral" address,
which is explicitly not the entryPoint itself.


## Functions
### createSender

Call the "initCode" factory to create and return the sender account address.


```solidity
function createSender(bytes calldata initCode) external returns (address sender);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`initCode`|`bytes`|the initCode value from a UserOp. contains 20 bytes of factory address, followed by calldata.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`sender`|`address`|the returned address of the created account, or zero address on failure.|


