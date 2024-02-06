# OwnerManager
[Git Source](https://github.com/TrueWallet/contracts/blob/5a052bc82f5ecbfdc3b7fb992a66fa5b770bcc4b/src/base/OwnerManager.sol)

**Inherits:**
[IOwnerManager](/src/interfaces/IOwnerManager.sol/interface.IOwnerManager.md), [Authority](/src/authority/Authority.sol/abstract.Authority.md)

*Provides functionality for adding, removing, checking, and listing owners.*


## Functions
### isOwner


```solidity
function isOwner(address addr) external view returns (bool);
```

### addOwner


```solidity
function addOwner(address owner) external override onlySelfOrModule;
```

### addOwners


```solidity
function addOwners(address[] calldata owners) external override onlySelfOrModule;
```

### resetOwner


```solidity
function resetOwner(address newOwner) external override onlySelfOrModule;
```

### resetOwners


```solidity
function resetOwners(address[] calldata newOwners) external override onlySelfOrModule;
```

### removeOwner


```solidity
function removeOwner(address owner) external override onlySelfOrModule;
```

### _isOwner


```solidity
function _isOwner(address addr) internal view returns (bool);
```

### _addOwner


```solidity
function _addOwner(address owner) internal;
```

### _ownerMapping


```solidity
function _ownerMapping() private view returns (mapping(address => address) storage owners);
```

### _clearOwner


```solidity
function _clearOwner() private;
```

### _addOwners


```solidity
function _addOwners(address[] calldata owners) private;
```

### listOwner


```solidity
function listOwner() public view override returns (address[] memory owners);
```

