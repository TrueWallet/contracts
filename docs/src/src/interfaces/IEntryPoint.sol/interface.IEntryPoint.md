# IEntryPoint
[Git Source](https://github.com/TrueWallet/contracts/blob/b38849a85d65fd71e42df8fc5190581d11c83fec/src/interfaces/IEntryPoint.sol)

**Inherits:**
[IStakeManager](/src/interfaces/IStakeManager.sol/interface.IStakeManager.md)


## Functions
### handleOps

Execute a batch of UserOperation.
No signature aggregator is used.
If any account requires an aggregator (that is, it returned an "actualAggregator" when
performing simulateValidation), then handleAggregatedOps() must be used instead.


```solidity
function handleOps(UserOperation[] calldata ops, address payable beneficiary) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`ops`|`UserOperation[]`|the operations to execute|
|`beneficiary`|`address payable`|the address to receive the fees|


### handleAggregatedOps

Execute a batch of UserOperation with Aggregators.


```solidity
function handleAggregatedOps(UserOpsPerAggregator[] calldata opsPerAggregator, address payable beneficiary) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`opsPerAggregator`|`UserOpsPerAggregator[]`|the operations to execute, grouped by aggregator (or address(0) for no-aggregator accounts).|
|`beneficiary`|`address payable`|the address to receive the fees.|


### getUserOpHash

Generate a request Id - unique identifier for this request.
The request ID is a hash over the content of the userOp (except the signature), the entrypoint and the chainid.


```solidity
function getUserOpHash(UserOperation calldata userOp) external view returns (bytes32);
```

### simulateValidation

Simulate a call to account.validateUserOp and paymaster.validatePaymasterUserOp.

*this method always revert. Successful result is SimulationResult error. other errors are failures.*

*The node must also verify it doesn't use banned opcodes, and that it doesn't reference storage outside the account's data.*


```solidity
function simulateValidation(UserOperation calldata userOp) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`userOp`|`UserOperation`|the user operation to validate.|


### getSenderAddress

Get counterfactual sender address.
Calculate the sender contract address that will be generated by the initCode and salt in the UserOperation.
This method always revert, and returns the address in SenderAddressResult error.


```solidity
function getSenderAddress(bytes memory initCode) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`initCode`|`bytes`|the constructor code to be passed into the UserOperation.|


## Events
### UserOperationEvent
An event emitted after each successful request.


```solidity
event UserOperationEvent(
    bytes32 indexed userOpHash,
    address indexed sender,
    address indexed paymaster,
    uint256 nonce,
    uint256 actualGasCost,
    uint256 actualGasPrice,
    bool success
);
```

### UserOperationRevertReason
An event emitted if the UserOperation "callData" reverted with non-zero length


```solidity
event UserOperationRevertReason(bytes32 indexed userOpHash, address indexed sender, uint256 nonce, bytes revertReason);
```

## Errors
### FailedOp
A custom revert error of handleOps, to identify the offending op.
NOTE: if simulateValidation passes successfully, there should be no reason for handleOps to fail on it.


```solidity
error FailedOp(uint256 opIndex, address paymaster, string reason);
```

### SignatureValidationFailed
Error case when a signature aggregator fails to verify the aggregated signature it had created.


```solidity
error SignatureValidationFailed(address aggregator);
```

### SimulationResult
Successful result from simulateValidation.


```solidity
error SimulationResult(uint256 preOpGas, uint256 prefund, uint256 deadline, PaymasterInfo paymasterInfo);
```

### SimulationResultWithAggregation
Successful result from simulateValidation, if the account returns a signature aggregator.


```solidity
error SimulationResultWithAggregation(
    uint256 preOpGas, uint256 prefund, uint256 deadline, PaymasterInfo paymasterInfo, AggregationInfo aggregationInfo
);
```

### SenderAddressResult
Return value of getSenderAddress.


```solidity
error SenderAddressResult(address sender);
```

## Structs
### UserOpsPerAggregator

```solidity
struct UserOpsPerAggregator {
    UserOperation[] userOps;
    IAggregator aggregator;
    bytes signature;
}
```

### PaymasterInfo
Returned paymaster info.
If the UserOperation contains a paymaster, these fields are filled with the paymaster's stake value and delay.
A bundler must verify these values are above the minimal required values, or else reject the UserOperation.


```solidity
struct PaymasterInfo {
    uint256 paymasterStake;
    uint256 paymasterUnstakeDelay;
}
```

### AggregationInfo
Returned aggregated signature info.
The aggregator returned by the account, and its current stake.


```solidity
struct AggregationInfo {
    address actualAggregator;
    uint256 aggregatorStake;
    uint256 aggregatorUnstakeDelay;
}
```
