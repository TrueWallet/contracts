# LogicUpgradeControl
[Git Source](https://github.com/TrueWallet/contracts/blob/db2e75cb332931da5fdaa38bec9e4d367be1d851/src/utils/LogicUpgradeControl.sol)

**Inherits:**
[ILogicUpgradeControl](/src/interfaces/ILogicUpgradeControl.sol/interface.ILogicUpgradeControl.md), [Upgradeable](/src/utils/Upgradeable.sol/abstract.Upgradeable.md), [UpgradeWalletErrors](/src/common/Errors.sol/contract.UpgradeWalletErrors.md)


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

