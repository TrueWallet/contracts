# GuardianInfo
[Git Source](https://github.com/TrueWallet/contracts/blob/3a8d1f53b9460a762889129a9214639685ad5b95/src/modules/SocialRecoveryModule/ISocialRecoveryModule.sol)

This contract allows wallet owners to set guardians for their wallets
and use these guardians for recovery purposes.


```solidity
struct GuardianInfo {
    mapping(address => address) guardians;
    uint256 threshold;
    bytes32 guardianHash;
}
```

