# EntryPoint
[Git Source](https://github.com/TrueWallet/contracts/blob/db2e75cb332931da5fdaa38bec9e4d367be1d851/src/entrypoint/EntryPoint.sol)

**Inherits:**
[IEntryPoint](/src/interfaces/IEntryPoint.sol/interface.IEntryPoint.md), [StakeManager](/src/entrypoint/StakeManager.sol/abstract.StakeManager.md), [NonceManager](/src/entrypoint/NonceManager.sol/contract.NonceManager.md), ReentrancyGuard

Account-Abstraction (EIP-4337) singleton EntryPoint implementation.
Only one instance required on each chain.


## State Variables
### senderCreator

```solidity
SenderCreator private immutable senderCreator = new SenderCreator();
```


### SIMULATE_FIND_AGGREGATOR
*Internal value used during simulation: need to query aggregator.*


```solidity
address private constant SIMULATE_FIND_AGGREGATOR = address(1);
```


### INNER_OUT_OF_GAS

```solidity
bytes32 private constant INNER_OUT_OF_GAS = hex"deaddead";
```


### REVERT_REASON_MAX_LEN

```solidity
uint256 private constant REVERT_REASON_MAX_LEN = 2048;
```


### SIG_VALIDATION_FAILED
For simulation purposes, validateUserOp (and validatePaymasterUserOp) must return this value
in case of signature failure, instead of revert.


```solidity
uint256 public constant SIG_VALIDATION_FAILED = 1;
```


## Functions
### _compensate

Compensate the caller's beneficiary address with the collected fees of all UserOperations.


```solidity
function _compensate(address payable beneficiary, uint256 amount) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`beneficiary`|`address payable`|the address to receive the fees|
|`amount`|`uint256`|amount to transfer.|


### _executeUserOp

Execute a user op.


```solidity
function _executeUserOp(uint256 opIndex, UserOperation calldata userOp, UserOpInfo memory opInfo)
    private
    returns (uint256 collected);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`opIndex`|`uint256`|index into the opInfo array.|
|`userOp`|`UserOperation`|the userOp to execute.|
|`opInfo`|`UserOpInfo`|the opInfo filled by validatePrepayment for this userOp.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`collected`|`uint256`|the total amount this userOp paid.|


### handleOps

Execute a batch of UserOperation.
no signature aggregator is used.
if any account requires an aggregator (that is, it returned an "actualAggregator" when
performing simulateValidation), then handleAggregatedOps() must be used instead.


```solidity
function handleOps(UserOperation[] calldata ops, address payable beneficiary) public nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`ops`|`UserOperation[]`|the operations to execute|
|`beneficiary`|`address payable`|the address to receive the fees|


### handleAggregatedOps

Execute a batch of UserOperation with Aggregators


```solidity
function handleAggregatedOps(UserOpsPerAggregator[] calldata opsPerAggregator, address payable beneficiary)
    public
    nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`opsPerAggregator`|`UserOpsPerAggregator[]`|the operations to execute, grouped by aggregator (or address(0) for no-aggregator accounts)|
|`beneficiary`|`address payable`|the address to receive the fees|


### simulateHandleOp

Simulate full execution of a UserOperation (including both validation and target execution)
this method will always revert with "ExecutionResult".
it performs full validation of the UserOperation, but ignores signature error.
an optional target address is called after the userop succeeds, and its value is returned
(before the entire call is reverted)
Note that in order to collect the the success/failure of the target call, it must be executed
with trace enabled to track the emitted events.


```solidity
function simulateHandleOp(UserOperation calldata op, address target, bytes calldata targetCallData) external override;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`op`|`UserOperation`|the UserOperation to simulate|
|`target`|`address`|if nonzero, a target address to call after userop simulation. If called, the targetSuccess and targetResult are set to the return from that call.|
|`targetCallData`|`bytes`|callData to pass to target address|


### innerHandleOp

Inner function to handle a UserOperation.
Must be declared "external" to open a call context, but it can only be called by handleOps.


```solidity
function innerHandleOp(bytes memory callData, UserOpInfo memory opInfo, bytes calldata context)
    external
    returns (uint256 actualGasCost);
```

### getUserOpHash

Generate a request Id - unique identifier for this request.
The request ID is a hash over the content of the userOp (except the signature), the entrypoint and the chainid.


```solidity
function getUserOpHash(UserOperation calldata userOp) public view returns (bytes32);
```

### _copyUserOpToMemory

Copy general fields from userOp into the memory opInfo structure.


```solidity
function _copyUserOpToMemory(UserOperation calldata userOp, MemoryUserOp memory mUserOp) internal pure;
```

### simulateValidation

Simulate a call to account.validateUserOp and paymaster.validatePaymasterUserOp.

*this method always revert. Successful result is ValidationResult error. other errors are failures.*

*The node must also verify it doesn't use banned opcodes, and that it doesn't reference storage outside the account's data.*


```solidity
function simulateValidation(UserOperation calldata userOp) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`userOp`|`UserOperation`|the user operation to validate.|


### _getRequiredPrefund


```solidity
function _getRequiredPrefund(MemoryUserOp memory mUserOp) internal pure returns (uint256 requiredPrefund);
```

### _createSenderIfNeeded


```solidity
function _createSenderIfNeeded(uint256 opIndex, UserOpInfo memory opInfo, bytes calldata initCode) internal;
```

### getSenderAddress

Get counterfactual sender address.
Calculate the sender contract address that will be generated by the initCode and salt in the UserOperation.
This method always revert, and returns the address in SenderAddressResult error


```solidity
function getSenderAddress(bytes calldata initCode) public;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`initCode`|`bytes`|the constructor code to be passed into the UserOperation.|


### _simulationOnlyValidations


```solidity
function _simulationOnlyValidations(UserOperation calldata userOp) internal view;
```

### _validateSenderAndPaymaster

Called only during simulation.
This function always reverts to prevent warm/cold storage differentiation in simulation vs execution.


```solidity
function _validateSenderAndPaymaster(bytes calldata initCode, address sender, bytes calldata paymasterAndData)
    external
    view;
```

### _validateAccountPrepayment

Call account.validateUserOp.
Revert (with FailedOp) in case validateUserOp reverts, or account didn't send required prefund.
Decrement account's deposit if needed


```solidity
function _validateAccountPrepayment(
    uint256 opIndex,
    UserOperation calldata op,
    UserOpInfo memory opInfo,
    uint256 requiredPrefund
) internal returns (uint256 gasUsedByValidateAccountPrepayment, uint256 validationData);
```

### _validatePaymasterPrepayment

In case the request has a paymaster:
Validate paymaster has enough deposit.
Call paymaster.validatePaymasterUserOp.
Revert with proper FailedOp in case paymaster reverts.
Decrement paymaster's deposit


```solidity
function _validatePaymasterPrepayment(
    uint256 opIndex,
    UserOperation calldata op,
    UserOpInfo memory opInfo,
    uint256 requiredPreFund,
    uint256 gasUsedByValidateAccountPrepayment
) internal returns (bytes memory context, uint256 validationData);
```

### _validateAccountAndPaymasterValidationData

Revert if either account validationData or paymaster validationData is expired


```solidity
function _validateAccountAndPaymasterValidationData(
    uint256 opIndex,
    uint256 validationData,
    uint256 paymasterValidationData,
    address expectedAggregator
) internal view;
```

### _getValidationData


```solidity
function _getValidationData(uint256 validationData) internal view returns (address aggregator, bool outOfTimeRange);
```

### _validatePrepayment

Validate account and paymaster (if defined).
Also make sure total validation doesn't exceed verificationGasLimit
this method is called off-chain (simulateValidation()) and on-chain (from handleOps)


```solidity
function _validatePrepayment(uint256 opIndex, UserOperation calldata userOp, UserOpInfo memory outOpInfo)
    private
    returns (uint256 validationData, uint256 paymasterValidationData);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`opIndex`|`uint256`|the index of this userOp into the "opInfos" array|
|`userOp`|`UserOperation`|the userOp to validate|
|`outOpInfo`|`UserOpInfo`||


### _handlePostOp

Process post-operation.
Called just after the callData is executed.
If a paymaster is defined and its validation returned a non-empty context, its postOp is called.
The excess amount is refunded to the account (or paymaster - if it was used in the request)


```solidity
function _handlePostOp(
    uint256 opIndex,
    IPaymaster.PostOpMode mode,
    UserOpInfo memory opInfo,
    bytes memory context,
    uint256 actualGas
) private returns (uint256 actualGasCost);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`opIndex`|`uint256`|index in the batch|
|`mode`|`IPaymaster.PostOpMode`|- whether is called from innerHandleOp, or outside (postOpReverted)|
|`opInfo`|`UserOpInfo`|userOp fields and info collected during validation|
|`context`|`bytes`|the context returned in validatePaymasterUserOp|
|`actualGas`|`uint256`|the gas used so far by this user operation|


### getUserOpGasPrice

The gas price this UserOp agrees to pay.
Relayer/block builder might submit the TX with higher priorityFee, but the user should not


```solidity
function getUserOpGasPrice(MemoryUserOp memory mUserOp) internal view returns (uint256);
```

### min


```solidity
function min(uint256 a, uint256 b) internal pure returns (uint256);
```

### getOffsetOfMemoryBytes


```solidity
function getOffsetOfMemoryBytes(bytes memory data) internal pure returns (uint256 offset);
```

### getMemoryBytesFromOffset


```solidity
function getMemoryBytesFromOffset(uint256 offset) internal pure returns (bytes memory data);
```

### numberMarker


```solidity
function numberMarker() internal view;
```

## Structs
### MemoryUserOp

```solidity
struct MemoryUserOp {
    address sender;
    uint256 nonce;
    uint256 callGasLimit;
    uint256 verificationGasLimit;
    uint256 preVerificationGas;
    address paymaster;
    uint256 maxFeePerGas;
    uint256 maxPriorityFeePerGas;
}
```

### UserOpInfo

```solidity
struct UserOpInfo {
    MemoryUserOp mUserOp;
    bytes32 userOpHash;
    uint256 prefund;
    uint256 contextOffset;
    uint256 preOpGas;
}
```

