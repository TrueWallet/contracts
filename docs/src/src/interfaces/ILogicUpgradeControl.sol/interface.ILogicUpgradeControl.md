# ILogicUpgradeControl
[Git Source](https://github.com/TrueWallet/contracts/blob/3a8d1f53b9460a762889129a9214639685ad5b95/src/interfaces/ILogicUpgradeControl.sol)

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
    uint64 activateTime;
    address pendingImplementation;
    uint256[50] __gap;
}
```

