# calldataKeccak
[Git Source](https://github.com/TrueWallet/contracts/blob/db2e75cb332931da5fdaa38bec9e4d367be1d851/src/helper/Helpers.sol)

keccak function over calldata.

*copy calldata into memory, do keccak and drop allocated memory. Strangely, this is more efficient than letting solidity do it.*


```solidity
function calldataKeccak(bytes calldata data) pure returns (bytes32 ret);
```

