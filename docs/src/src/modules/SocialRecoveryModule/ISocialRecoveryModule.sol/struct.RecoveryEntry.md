# RecoveryEntry
[Git Source](https://github.com/TrueWallet/contracts/blob/43e94f0622a36448f24323cfe74a0e2604784f80/src/modules/SocialRecoveryModule/ISocialRecoveryModule.sol)


```solidity
struct RecoveryEntry {
    address[] newOwners;
    uint256 executeAfter;
    uint256 nonce;
}
```

