# AddressLinkedList
[Git Source](https://github.com/TrueWallet/contracts/blob/43e94f0622a36448f24323cfe74a0e2604784f80/src/libraries/AddressLinkedList.sol)


## State Variables
### SENTINEL_ADDRESS

```solidity
address internal constant SENTINEL_ADDRESS = address(1);
```


### SENTINEL_UINT

```solidity
uint160 internal constant SENTINEL_UINT = 1;
```


## Functions
### onlyAddress


```solidity
modifier onlyAddress(address addr);
```

### add


```solidity
function add(mapping(address => address) storage self, address addr) internal onlyAddress(addr);
```

### replace


```solidity
function replace(mapping(address => address) storage self, address oldAddr, address newAddr) internal;
```

### remove


```solidity
function remove(mapping(address => address) storage self, address addr) internal;
```

### tryRemove


```solidity
function tryRemove(mapping(address => address) storage self, address addr) internal returns (bool);
```

### clear


```solidity
function clear(mapping(address => address) storage self) internal;
```

### isExist


```solidity
function isExist(mapping(address => address) storage self, address addr)
    internal
    view
    onlyAddress(addr)
    returns (bool);
```

### size


```solidity
function size(mapping(address => address) storage self) internal view returns (uint256);
```

### isEmpty


```solidity
function isEmpty(mapping(address => address) storage self) internal view returns (bool);
```

### list

*This function is just an example, please copy this code directly when you need it, you should not call this function*


```solidity
function list(mapping(address => address) storage self, address from, uint256 limit)
    internal
    view
    returns (address[] memory);
```

## Errors
### InvalidAddress

```solidity
error InvalidAddress();
```

### AddressAlreadyExists

```solidity
error AddressAlreadyExists();
```

### AddressNotExists

```solidity
error AddressNotExists();
```

