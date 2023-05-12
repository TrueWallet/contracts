# IAggregatedAccount
[Git Source](https://github.com/TrueWallet/contracts/blob/843930f01013ad22976a2d653f9d67aaa82d54f4/src/interfaces/IAggregatedAccount.sol)

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

