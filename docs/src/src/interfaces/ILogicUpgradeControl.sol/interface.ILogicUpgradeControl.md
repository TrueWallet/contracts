# ILogicUpgradeControl
[Git Source](https://github.com/TrueWallet/contracts/blob/843930f01013ad22976a2d653f9d67aaa82d54f4/src/interfaces/ILogicUpgradeControl.sol)

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

