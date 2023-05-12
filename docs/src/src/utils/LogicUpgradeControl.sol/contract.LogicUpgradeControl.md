# LogicUpgradeControl
[Git Source](https://github.com/TrueWallet/contracts/blob/843930f01013ad22976a2d653f9d67aaa82d54f4/src/utils/LogicUpgradeControl.sol)

**Inherits:**
[ILogicUpgradeControl](/src/interfaces/ILogicUpgradeControl.sol/interface.ILogicUpgradeControl.md), [Upgradeable](/src/utils/Upgradeable.sol/abstract.Upgradeable.md)


## Functions
### logicUpgradeInfo

*Returns Logic updgrade layout info*


```solidity
function logicUpgradeInfo() public view returns (ILogicUpgradeControl.UpgradeLayout memory);
```

### _preUpgradeTo

*preUpgradeTo is called before upgrading the wallet*


```solidity
function _preUpgradeTo(address newImplementation) internal;
```

### upgrade

*Perform implementation upgrade*


```solidity
function upgrade() external;
```

### getImplementation

*Returns the current implementation address*


```solidity
function getImplementation() public view;
```

## Errors
### UpgradeDelayNotElapsed

```solidity
error UpgradeDelayNotElapsed();
```

