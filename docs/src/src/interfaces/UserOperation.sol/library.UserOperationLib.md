# UserOperationLib
[Git Source](https://github.com/TrueWallet/contracts/blob/b38849a85d65fd71e42df8fc5190581d11c83fec/src/interfaces/UserOperation.sol)


## Functions
### getSender


```solidity
function getSender(UserOperation calldata userOp) internal pure returns (address);
```

### gasPrice


```solidity
function gasPrice(UserOperation calldata userOp) internal view returns (uint256);
```

### pack


```solidity
function pack(UserOperation calldata userOp) internal pure returns (bytes memory ret);
```

### hash


```solidity
function hash(UserOperation calldata userOp) internal pure returns (bytes32);
```

### min


```solidity
function min(uint256 a, uint256 b) internal pure returns (uint256);
```

