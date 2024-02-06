# IAccount
[Git Source](https://github.com/TrueWallet/contracts/blob/5a052bc82f5ecbfdc3b7fb992a66fa5b770bcc4b/src/interfaces/IAccount.sol)


## Functions
### validateUserOp

Validate user's signature and nonce
the entryPoint will make the call to the recipient only if this validation call returns successfully.
signature failure should be reported by returning SIG_VALIDATION_FAILED (1).
This allows making a "simulation call" without a valid signature
Other failures (e.g. nonce mismatch, or invalid signature format) should still revert to signal failure.

*Must validate caller is the entryPoint.
Must validate the signature and nonce*


```solidity
function validateUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
    external
    returns (uint256 validationData);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`userOp`|`UserOperation`|the operation that is about to be executed.|
|`userOpHash`|`bytes32`|hash of the user's request data. can be used as the basis for signature.|
|`missingAccountFunds`|`uint256`|missing funds on the account's deposit in the entrypoint. This is the minimum amount to transfer to the sender(entryPoint) to be able to make the call. The excess is left as a deposit in the entrypoint, for future calls. can be withdrawn anytime using "entryPoint.withdrawTo()" In case there is a paymaster in the request (or the current deposit is high enough), this value will be zero.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`validationData`|`uint256`|packaged ValidationData structure. use `_packValidationData` and `_unpackValidationData` to encode and decode <20-byte> sigAuthorizer - 0 for valid signature, 1 to mark signature failure, otherwise, an address of an "authorizer" contract. <6-byte> validUntil - last timestamp this operation is valid. 0 for "indefinite" <6-byte> validAfter - first timestamp this operation is valid If an account doesn't use time-range, it is enough to return SIG_VALIDATION_FAILED value (1) for signature failure. Note that the validation code cannot use block.timestamp (or block.number) directly.|


