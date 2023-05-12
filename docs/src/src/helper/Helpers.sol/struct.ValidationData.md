# ValidationData
[Git Source](https://github.com/TrueWallet/contracts/blob/843930f01013ad22976a2d653f9d67aaa82d54f4/src/helper/Helpers.sol)

Returned data from validateUserOp.
validateUserOp returns a uint256, with is created by `_packedValidationData` and parsed by `_parseValidationData`


```solidity
struct ValidationData {
    address aggregator;
    uint48 validAfter;
    uint48 validUntil;
}
```

