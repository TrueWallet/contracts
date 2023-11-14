# PendingGuardianEntry
[Git Source](https://github.com/TrueWallet/contracts/blob/3a8d1f53b9460a762889129a9214639685ad5b95/src/modules/SocialRecoveryModule/ISocialRecoveryModule.sol)


```solidity
struct PendingGuardianEntry {
    uint256 pendingUntil;
    uint256 threshold;
    bytes32 guardianHash;
    address[] guardians;
}
```

