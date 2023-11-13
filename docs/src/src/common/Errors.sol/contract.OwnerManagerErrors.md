# OwnerManagerErrors
[Git Source](https://github.com/TrueWallet/contracts/blob/43e94f0622a36448f24323cfe74a0e2604784f80/src/common/Errors.sol)


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

