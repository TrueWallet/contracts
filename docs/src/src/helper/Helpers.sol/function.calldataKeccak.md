# calldataKeccak
[Git Source](https://github.com/TrueWallet/contracts/blob/843930f01013ad22976a2d653f9d67aaa82d54f4/src/helper/Helpers.sol)

keccak function over calldata.

*copy calldata into memory, do keccak and drop allocated memory. Strangely, this is more efficient than letting solidity do it.*


```solidity
function calldataKeccak(bytes calldata data) pure returns (bytes32 ret);
```

