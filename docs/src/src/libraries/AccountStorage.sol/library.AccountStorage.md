# AccountStorage
[Git Source](https://github.com/TrueWallet/contracts/blob/43e94f0622a36448f24323cfe74a0e2604784f80/src/libraries/AccountStorage.sol)


## State Variables
### ACCOUNT_SLOT

```solidity
bytes32 private constant ACCOUNT_SLOT = keccak256("truewallet.contracts.AccountStorage");
```


## Functions
### layout


```solidity
function layout() internal pure returns (Layout storage l);
```

## Structs
### Layout

```solidity
struct Layout {
    IEntryPoint entryPoint;
    mapping(address => address) owners;
    uint256[50] __gap_0;
    ILogicUpgradeControl.UpgradeLayout logicUpgrade;
    Initializable.InitializableLayout initializableLayout;
    uint256[50] __gap_1;
    mapping(address => address) modules;
    mapping(address => mapping(bytes4 => bytes4)) moduleSelectors;
    uint256[50] __gap_2;
}
```

