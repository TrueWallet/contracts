# PendingGuardianEntry
[Git Source](https://github.com/TrueWallet/contracts/blob/43e94f0622a36448f24323cfe74a0e2604784f80/src/modules/SocialRecoveryModule/ISocialRecoveryModule.sol)


```solidity
struct PendingGuardianEntry {
    uint256 pendingUntil;
    uint256 threshold;
    bytes32 guardianHash;
    address[] guardians;
}
```

