# INonceManager
[Git Source](https://github.com/TrueWallet/contracts/blob/db2e75cb332931da5fdaa38bec9e4d367be1d851/src/interfaces/INonceManager.sol)


## Functions
### getNonce

Return the next nonce for this sender.
Within a given key, the nonce values are sequenced (starting with zero, and incremented by one on each userop)
But UserOp with different keys can come with arbitrary order.


```solidity
function getNonce(address sender, uint192 key) external view returns (uint256 nonce);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`sender`|`address`|the account address|
|`key`|`uint192`|the high 192 bit of the nonce|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`nonce`|`uint256`|a full nonce to pass for next UserOp with this sender.|


### incrementNonce

Manually increment the nonce of the sender.
This method is exposed just for completeness..
Account does NOT need to call it, neither during validation, nor elsewhere,
as the EntryPoint will update the nonce regardless.
Possible use-case is call it with various keys to "initialize" their nonces to one, so that future
UserOperations will not pay extra for the first transaction with a given key.


```solidity
function incrementNonce(uint192 key) external;
```

