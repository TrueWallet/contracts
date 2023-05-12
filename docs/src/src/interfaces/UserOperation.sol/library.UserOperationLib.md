# UserOperationLib
[Git Source](https://github.com/TrueWallet/contracts/blob/843930f01013ad22976a2d653f9d67aaa82d54f4/src/interfaces/UserOperation.sol)


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

