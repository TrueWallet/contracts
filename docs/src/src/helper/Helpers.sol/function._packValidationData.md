# function _packValidationData
[Git Source](https://github.com/TrueWallet/contracts/blob/b38849a85d65fd71e42df8fc5190581d11c83fec/src/helper/Helpers.sol)

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

