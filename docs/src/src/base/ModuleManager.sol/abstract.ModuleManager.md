# ModuleManager
[Git Source](https://github.com/TrueWallet/contracts/blob/3a8d1f53b9460a762889129a9214639685ad5b95/src/base/ModuleManager.sol)

**Inherits:**
[IModuleManager](/src/interfaces/IModuleManager.sol/interface.IModuleManager.md), [ModuleAuth](/src/authority/ModuleAuth.sol/abstract.ModuleAuth.md), [ModuleManagerErrors](/src/common/Errors.sol/contract.ModuleManagerErrors.md)


## Functions
### isAuthorizedModule


```solidity
function isAuthorizedModule(address module) external view override returns (bool);
```

### addModule


```solidity
function addModule(bytes calldata moduleAndData) external override onlyModule;
```

### removeModule


```solidity
function removeModule(address module) external override onlyModule;
```

### listModules


```solidity
function listModules() external view override returns (address[] memory modules, bytes4[][] memory selectors);
```

### executeFromModule


```solidity
function executeFromModule(address to, uint256 value, bytes memory data) external override onlyModule;
```

### _modulesMapping


```solidity
function _modulesMapping() private view returns (mapping(address => address) storage modules);
```

### _moduleSelectorsMapping


```solidity
function _moduleSelectorsMapping()
    private
    view
    returns (mapping(address => mapping(bytes4 => bytes4)) storage moduleSelectors);
```

### _addModule


```solidity
function _addModule(bytes calldata moduleAndData) internal;
```

### _isAuthorizedModule


```solidity
function _isAuthorizedModule() internal view override returns (bool);
```

