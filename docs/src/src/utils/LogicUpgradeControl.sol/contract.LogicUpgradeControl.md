# LogicUpgradeControl
[Git Source](https://github.com/TrueWallet/contracts/blob/3a8d1f53b9460a762889129a9214639685ad5b95/src/utils/LogicUpgradeControl.sol)

**Inherits:**
[ILogicUpgradeControl](/src/interfaces/ILogicUpgradeControl.sol/interface.ILogicUpgradeControl.md), [Upgradeable](/src/utils/Upgradeable.sol/abstract.Upgradeable.md), [UpgradeWalletErrors](/src/common/Errors.sol/contract.UpgradeWalletErrors.md)


## State Variables
### upgradeDelay

```solidity
uint256 public constant upgradeDelay = 2 days;
```


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

