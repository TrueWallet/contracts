# AccountStorage
[Git Source](https://github.com/TrueWallet/contracts/blob/843930f01013ad22976a2d653f9d67aaa82d54f4/src/utils/AccountStorage.sol)


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
### RoleData

```solidity
struct RoleData {
    mapping(address => bool) members;
    bytes32 adminRole;
}
```

### Layout

```solidity
struct Layout {
    IEntryPoint entryPoint;
    address owner;
    uint96 nonce;
    uint256[50] __gap_0;
    ILogicUpgradeControl.UpgradeLayout logicUpgrade;
    Initializable.InitializableLayout initializableLayout;
    uint256[50] __gap_1;
    mapping(bytes32 => RoleData) roles;
    mapping(bytes32 => EnumerableSet.AddressSet) roleMembers;
    uint256[50] __gap_2;
}
```

