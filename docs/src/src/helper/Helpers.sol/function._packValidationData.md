# function _packValidationData
[Git Source](https://github.com/TrueWallet/contracts/blob/843930f01013ad22976a2d653f9d67aaa82d54f4/src/helper/Helpers.sol)

### _packValidationData(ValidationData)
helper to pack the return value for validateUserOp


```solidity
function _packValidationData(ValidationData memory data) pure returns (uint256);
```

### _packValidationData(bool, uint48, uint48)
helper to pack the return value for validateUserOp, when not using an aggregator


```solidity
function _packValidationData(bool sigFailed, uint48 validUntil, uint48 validAfter) pure returns (uint256);
```

