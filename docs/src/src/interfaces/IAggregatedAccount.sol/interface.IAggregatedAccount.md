# IAggregatedAccount
[Git Source](https://github.com/TrueWallet/contracts/blob/db2e75cb332931da5fdaa38bec9e4d367be1d851/src/interfaces/IAggregatedAccount.sol)

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

