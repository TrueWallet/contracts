# GuardianInfo
[Git Source](https://github.com/TrueWallet/contracts/blob/db2e75cb332931da5fdaa38bec9e4d367be1d851/src/modules/SocialRecoveryModule/ISocialRecoveryModule.sol)

This contract allows wallet owners to set guardians for their wallets
and use these guardians for recovery purposes.


```solidity
struct GuardianInfo {
    mapping(address => address) guardians;
    uint256 threshold;
    bytes32 guardianHash;
}
```

