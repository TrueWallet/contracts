# SocialRecoveryErrors
[Git Source](https://github.com/TrueWallet/contracts/blob/b38849a85d65fd71e42df8fc5190581d11c83fec/src/common/Errors.sol)


## Errors
### InvalidOwner
*Reverts in case not valid owner*


```solidity
error InvalidOwner();
```

### InvalidGuardian
*Reverts in case not valid guardian*


```solidity
error InvalidGuardian();
```

### InvalidThreshold
*Reverts in case not valid threshold*


```solidity
error InvalidThreshold();
```

### ZeroAddressForGuardianProvided
*Reverts when zero address is assigned for guardian*


```solidity
error ZeroAddressForGuardianProvided();
```

### DuplicateGuardianProvided
*Reverts when guardian provided is already in the list*


```solidity
error DuplicateGuardianProvided();
```

### RecoveryAlreadyExecuted
*Reverts when the particular recovery requist is already executed*


```solidity
error RecoveryAlreadyExecuted();
```

### RecoveryNotEnoughConfirmations
*Reverts when not enough confirmation from guardians for recovery requist*


```solidity
error RecoveryNotEnoughConfirmations();
```

### RecoveryPeriodStillPending
*Reverts when recovery period is still pending before execution*


```solidity
error RecoveryPeriodStillPending();
```

### RecoveryNotInitiated
*Reverts when no ongoing recovery requiests*


```solidity
error RecoveryNotInitiated();
```

