# IWallet
[Git Source](https://github.com/TrueWallet/contracts/blob/db2e75cb332931da5fdaa38bec9e4d367be1d851/src/wallet/IWallet.sol)

**Inherits:**
[IModuleManager](/src/interfaces/IModuleManager.sol/interface.IModuleManager.md), [IOwnerManager](/src/interfaces/IOwnerManager.sol/interface.IOwnerManager.md)


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


### entryPoint

Entrypoint connected to the wallet


```solidity
function entryPoint() external view returns (address);
```

### nonce

Get the nonce on the wallet


```solidity
function nonce() external view returns (uint256);
```

### execute

Method called by the entryPoint to execute a userOperation


```solidity
function execute(address target, uint256 value, bytes calldata payload) external;
```

### executeBatch

Method called by the entryPoint to execute a userOperation with a sequence of transactions


```solidity
function executeBatch(address[] calldata target, uint256[] calldata value, bytes[] calldata payload) external;
```

### isValidSignature

Verifies that the signer is the owner of the signing contract


```solidity
function isValidSignature(bytes32 messageHash, bytes memory signature) external view returns (bytes4);
```

