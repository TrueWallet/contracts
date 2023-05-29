# IAggregatedAccount
[Git Source](https://github.com/TrueWallet/contracts/blob/b38849a85d65fd71e42df8fc5190581d11c83fec/src/interfaces/IAggregatedAccount.sol)

**Inherits:**
[IAccount](/src/interfaces/IAccount.sol/interface.IAccount.md)

Aggregated account, that support IAggregator.
- the validateUserOp will be called only after the aggregator validated this account (with all other accounts of this aggregator).
- the validateUserOp MUST validate the aggregator parameter, and MAY ignore the userOp.signature field.


## Functions
### getAggregator

Return the address of the signature aggregator the account supports.


```solidity
function getAggregator() external view returns (address);
```

