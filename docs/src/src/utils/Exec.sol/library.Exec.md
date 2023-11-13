# Exec
[Git Source](https://github.com/TrueWallet/contracts/blob/43e94f0622a36448f24323cfe74a0e2604784f80/src/utils/Exec.sol)

Utility functions helpful when making different kinds of contract calls in Solidity.


## Functions
### call


```solidity
function call(address to, uint256 value, bytes memory data, uint256 txGas) internal returns (bool success);
```

### staticcall


```solidity
function staticcall(address to, bytes memory data, uint256 txGas) internal view returns (bool success);
```

### delegateCall


```solidity
function delegateCall(address to, bytes memory data, uint256 txGas) internal returns (bool success);
```

### getReturnData


```solidity
function getReturnData(uint256 maxLen) internal pure returns (bytes memory returnData);
```

### revertWithData


```solidity
function revertWithData(bytes memory returnData) internal pure;
```

### callAndRevert


```solidity
function callAndRevert(address to, bytes memory data, uint256 maxLen) internal;
```

