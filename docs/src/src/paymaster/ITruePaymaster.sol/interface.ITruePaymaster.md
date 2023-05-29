# ITruePaymaster
[Git Source](https://github.com/TrueWallet/contracts/blob/b38849a85d65fd71e42df8fc5190581d11c83fec/src/paymaster/ITruePaymaster.sol)

**Inherits:**
[IPaymaster](/src/interfaces/IPaymaster.sol/interface.IPaymaster.md)


## Functions
### getStake

Get the Paymaster stake on the entryPoint, which is used for DDOS protection.


```solidity
function getStake() external view returns (uint112);
```

### getDeposit

Get the Paymaster deposit on the entryPoint, which is used to pay for gas.


```solidity
function getDeposit() external view returns (uint112);
```

### deposit

Add a deposit for this paymaster to the entryPoint.


```solidity
function deposit() external payable;
```

### addStake

Add to the account's stake - amount and delay.


```solidity
function addStake(uint32 _unstakeDelaySeconds) external payable;
```

