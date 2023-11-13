# ILogicUpgradeControl
[Git Source](https://github.com/TrueWallet/contracts/blob/43e94f0622a36448f24323cfe74a0e2604784f80/src/interfaces/ILogicUpgradeControl.sol)

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

