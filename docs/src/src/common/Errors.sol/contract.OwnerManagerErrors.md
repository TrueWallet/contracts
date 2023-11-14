# OwnerManagerErrors
[Git Source](https://github.com/TrueWallet/contracts/blob/3a8d1f53b9460a762889129a9214639685ad5b95/src/common/Errors.sol)


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

