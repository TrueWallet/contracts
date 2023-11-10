# ILogicUpgradeControl
[Git Source](https://github.com/TrueWallet/contracts/blob/db2e75cb332931da5fdaa38bec9e4d367be1d851/src/interfaces/ILogicUpgradeControl.sol)

*Interface of the LogicUpgradeControl*


## Events
### PreUpgrade
*Emitted before upgrade logic*


```solidity
event PreUpgrade(address newLogic, uint64 activateTime);
```

### Upgraded
*Emitted when `implementation` is upgraded.*


```solidity
event Upgraded(address newImplementation);
```

## Structs
### UpgradeLayout

```solidity
struct UpgradeLayout {
    uint32 upgradeDelay;
    uint64 activateTime;
    address pendingImplementation;
    uint256[50] __gap;
}
```

