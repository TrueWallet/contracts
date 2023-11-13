# GuardianInfo
[Git Source](https://github.com/TrueWallet/contracts/blob/43e94f0622a36448f24323cfe74a0e2604784f80/src/modules/SocialRecoveryModule/ISocialRecoveryModule.sol)

This contract allows wallet owners to set guardians for their wallets
and use these guardians for recovery purposes.


```solidity
struct GuardianInfo {
    mapping(address => address) guardians;
    uint256 threshold;
    bytes32 guardianHash;
}
```

