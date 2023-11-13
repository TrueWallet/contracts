# WalletErrors
[Git Source](https://github.com/TrueWallet/contracts/blob/43e94f0622a36448f24323cfe74a0e2604784f80/src/common/Errors.sol)


## Errors
### InvalidOwner
Throws when an invalid owner address is provided or detected.


```solidity
error InvalidOwner();
```

### InvalidEntryPointOrOwner
Throws when an invalid entry point or owner is provided or detected.


```solidity
error InvalidEntryPointOrOwner();
```

### ZeroAddressProvided
Throws when an address provided is the zero address.


```solidity
error ZeroAddressProvided();
```

### InvalidUpgradeDelay
Throws when an invalid delay is provided for an upgrade.


```solidity
error InvalidUpgradeDelay();
```

### LengthMismatch
Throws when the lengths of two comparable arrays or sets of data do not match.


```solidity
error LengthMismatch();
```

### InvalidSignature
Throws when a provided signature is not valid.


```solidity
error InvalidSignature();
```

### InvalidEntryPoint
Throws when an invalid entry point is provided or detected.


```solidity
error InvalidEntryPoint();
```

### WalletFactory__Create2CallFailed
Throws when create2 call failed.


```solidity
error WalletFactory__Create2CallFailed();
```

