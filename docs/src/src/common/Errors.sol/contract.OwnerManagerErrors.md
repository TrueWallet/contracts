# OwnerManagerErrors
[Git Source](https://github.com/TrueWallet/contracts/blob/db2e75cb332931da5fdaa38bec9e4d367be1d851/src/common/Errors.sol)


## Errors
### NoOwner
*Throws when an operation requires an owner but none exist.*


```solidity
error NoOwner();
```

### CallerMustBeSelfOfModule
*Throws when the caller must be the contract itself or one of its modules.*


```solidity
error CallerMustBeSelfOfModule();
```

