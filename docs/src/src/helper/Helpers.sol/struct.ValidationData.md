# ValidationData
[Git Source](https://github.com/TrueWallet/contracts/blob/db2e75cb332931da5fdaa38bec9e4d367be1d851/src/helper/Helpers.sol)

Returned data from validateUserOp.
validateUserOp returns a uint256, with is created by `_packedValidationData` and parsed by `_parseValidationData`


```solidity
struct ValidationData {
    address aggregator;
    uint48 validAfter;
    uint48 validUntil;
}
```

