# ValidationData
[Git Source](https://github.com/TrueWallet/contracts/blob/b38849a85d65fd71e42df8fc5190581d11c83fec/src/helper/Helpers.sol)

Returned data from validateUserOp.
validateUserOp returns a uint256, with is created by `_packedValidationData` and parsed by `_parseValidationData`


```solidity
struct ValidationData {
    address aggregator;
    uint48 validAfter;
    uint48 validUntil;
}
```

