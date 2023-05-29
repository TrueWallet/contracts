# IWallet
[Git Source](https://github.com/TrueWallet/contracts/blob/b38849a85d65fd71e42df8fc5190581d11c83fec/src/wallet/IWallet.sol)


## Functions
### validateUserOp

Validate user's signature and nonce
the entryPoint will make the call to the recipient only if this validation call returns successfully.

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


### owner

Owner of the contract


```solidity
function owner() external view returns (address);
```

### entryPoint

Entrypoint connected to the wallet


```solidity
function entryPoint() external view returns (address);
```

### nonce

Get the nonce on the wallet


```solidity
function nonce() external view returns (uint96);
```

### execute

Method called by the entryPoint to execute a userOperation


```solidity
function execute(address target, uint256 value, bytes calldata payload) external;
```

### isValidSignature

Verifies that the signer is the owner of the signing contract


```solidity
function isValidSignature(bytes32 messageHash, bytes memory signature) external view returns (bytes4);
```

