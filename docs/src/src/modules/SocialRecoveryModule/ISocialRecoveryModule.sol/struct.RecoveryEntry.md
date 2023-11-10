# RecoveryEntry
[Git Source](https://github.com/TrueWallet/contracts/blob/db2e75cb332931da5fdaa38bec9e4d367be1d851/src/modules/SocialRecoveryModule/ISocialRecoveryModule.sol)


```solidity
struct RecoveryEntry {
    address[] newOwners;
    uint256 executeAfter;
    uint256 nonce;
}
```

