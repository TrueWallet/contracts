# TrueWalletProxy
[Git Source](https://github.com/TrueWallet/contracts/blob/43e94f0622a36448f24323cfe74a0e2604784f80/src/wallet/TrueWalletProxy.sol)

**Inherits:**
[Upgradeable](/src/utils/Upgradeable.sol/abstract.Upgradeable.md)


## Functions
### constructor

*Initializes the upgradeable proxy with an initial implementation specified by `logic`.
If `data` is nonempty, it's used as data in a delegate call to `logic`. This will typically be an encoded
function call, and allows initializing the storage of the proxy like a Solidity constructor.*


```solidity
constructor(address logic, bytes memory data) payable;
```

### _delegate

*Delegates the current call to `implementation`.
This function does not return to its internal call site, it will return directly to the external caller.*


```solidity
function _delegate(address implementation) private;
```

### _fallback

*Delegates the current call to the address returned by `_implementation()`.
This function does not return to its internal call site, it will return directly to the external caller.*


```solidity
function _fallback() internal;
```

### fallback

*Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
function in the contract matches the call data.*


```solidity
fallback() external payable;
```

### receive

*Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
is empty.*


```solidity
receive() external payable;
```

