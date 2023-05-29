# calldataKeccak
[Git Source](https://github.com/TrueWallet/contracts/blob/b38849a85d65fd71e42df8fc5190581d11c83fec/src/helper/Helpers.sol)

keccak function over calldata.

*copy calldata into memory, do keccak and drop allocated memory. Strangely, this is more efficient than letting solidity do it.*


```solidity
function calldataKeccak(bytes calldata data) pure returns (bytes32 ret);
```

