# IAccount
[Git Source](https://github.com/TrueWallet/contracts/blob/843930f01013ad22976a2d653f9d67aaa82d54f4/src/interfaces/IAccount.sol)


## Functions
### validateUserOp

Validate user's signature and nonce.
The entryPoint will make the call to the recipient only if this validation call returns successfully.

*Must validate caller is the entryPoint.
Must validate the signature and nonce*


```solidity
function validateUserOp(
    UserOperation calldata userOp,
    bytes32 userOpHash,
    address aggregator,
    uint256 missingAccountFunds
) external returns (uint256 deadline);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`userOp`|`UserOperation`|the operation that is about to be executed.|
|`userOpHash`|`bytes32`|hash of the user's request data. can be used as the basis for signature.|
|`aggregator`|`address`|the aggregator used to validate the signature. NULL for non-aggregated signature accounts.|
|`missingAccountFunds`|`uint256`|missing funds on the account's deposit in the entrypoint. This is the minimum amount to transfer to the sender(entryPoint) to be able to make the call. The excess is left as a deposit in the entrypoint, for future calls. can be withdrawn anytime using "entryPoint.withdrawTo()" In case there is a paymaster in the request (or the current deposit is high enough), this value will be zero.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`deadline`|`uint256`|the last block timestamp this operation is valid, or zero if it is valid indefinitely. Note that the validation code cannot use block.timestamp (or block.number) directly.|


