# function _packValidationData
[Git Source](https://github.com/TrueWallet/contracts/blob/db2e75cb332931da5fdaa38bec9e4d367be1d851/src/helper/Helpers.sol)

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

