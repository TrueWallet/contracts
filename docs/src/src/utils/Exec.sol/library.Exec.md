# Exec
[Git Source](https://github.com/TrueWallet/contracts/blob/3a8d1f53b9460a762889129a9214639685ad5b95/src/utils/Exec.sol)

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

