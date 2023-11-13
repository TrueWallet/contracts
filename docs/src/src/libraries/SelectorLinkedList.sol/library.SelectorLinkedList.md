# SelectorLinkedList
[Git Source](https://github.com/TrueWallet/contracts/blob/43e94f0622a36448f24323cfe74a0e2604784f80/src/libraries/SelectorLinkedList.sol)


## State Variables
### SENTINEL_SELECTOR

```solidity
bytes4 internal constant SENTINEL_SELECTOR = 0x00000001;
```


### SENTINEL_UINT

```solidity
uint32 internal constant SENTINEL_UINT = 1;
```


## Functions
### isSafeSelector


```solidity
function isSafeSelector(bytes4 selector) internal pure returns (bool);
```

### onlySelector


```solidity
modifier onlySelector(bytes4 selector);
```

### add


```solidity
function add(mapping(bytes4 => bytes4) storage self, bytes4 selector) internal onlySelector(selector);
```

### add


```solidity
function add(mapping(bytes4 => bytes4) storage self, bytes4[] memory selectors) internal;
```

### replace


```solidity
function replace(mapping(bytes4 => bytes4) storage self, bytes4 oldSelector, bytes4 newSelector) internal;
```

### remove


```solidity
function remove(mapping(bytes4 => bytes4) storage self, bytes4 selector) internal;
```

### clear


```solidity
function clear(mapping(bytes4 => bytes4) storage self) internal;
```

### isExist


```solidity
function isExist(mapping(bytes4 => bytes4) storage self, bytes4 selector)
    internal
    view
    onlySelector(selector)
    returns (bool);
```

### size


```solidity
function size(mapping(bytes4 => bytes4) storage self) internal view returns (uint256);
```

### isEmpty


```solidity
function isEmpty(mapping(bytes4 => bytes4) storage self) internal view returns (bool);
```

### list


```solidity
function list(mapping(bytes4 => bytes4) storage self, bytes4 from, uint256 limit)
    internal
    view
    returns (bytes4[] memory);
```

## Errors
### InvalidSelector

```solidity
error InvalidSelector();
```

### SelectorAlreadyExists

```solidity
error SelectorAlreadyExists();
```

### SelectorNotExists

```solidity
error SelectorNotExists();
```

