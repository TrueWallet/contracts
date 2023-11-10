# StakeManager
[Git Source](https://github.com/TrueWallet/contracts/blob/db2e75cb332931da5fdaa38bec9e4d367be1d851/src/entrypoint/StakeManager.sol)

**Inherits:**
[IStakeManager](/src/interfaces/IStakeManager.sol/interface.IStakeManager.md)

Manage deposits and stakes.
Deposit is just a balance used to pay for UserOperations (either by a paymaster or a wallet).
Stake is value locked for at least "unstakeDelay" by a paymaster.


## State Variables
### deposits
*maps paymaster to their deposits and stakes*


```solidity
mapping(address => DepositInfo) public deposits;
```


## Functions
### getDepositInfo


```solidity
function getDepositInfo(address account) public view returns (DepositInfo memory info);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`info`|`DepositInfo`|- full deposit information of given account|


### _getStakeInfo


```solidity
function _getStakeInfo(address addr) internal view returns (StakeInfo memory info);
```

### balanceOf

Return the deposit (for gas payment) of the account


```solidity
function balanceOf(address account) public view returns (uint256);
```

### receive


```solidity
receive() external payable;
```

### _incrementDeposit


```solidity
function _incrementDeposit(address account, uint256 amount) internal;
```

### depositTo

Add to the deposit of the given account


```solidity
function depositTo(address account) public payable;
```

### addStake

Add to the account's stake - amount and delay
any pending unstake is first cancelled.


```solidity
function addStake(uint32 unstakeDelaySec) public payable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`unstakeDelaySec`|`uint32`|the new lock duration before the deposit can be withdrawn.|


### unlockStake

Attempt to unlock the stake.
The value can be withdrawn (using withdrawStake) after the unstake delay.


```solidity
function unlockStake() external;
```

### withdrawStake

Withdraw from the (unlocked) stake.
must first call unlockStake and wait for the unstakeDelay to pass


```solidity
function withdrawStake(address payable withdrawAddress) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`withdrawAddress`|`address payable`|the address to send withdrawn value.|


### withdrawTo

Withdraw from the deposit.


```solidity
function withdrawTo(address payable withdrawAddress, uint256 withdrawAmount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`withdrawAddress`|`address payable`|the address to send withdrawn value.|
|`withdrawAmount`|`uint256`|the amount to withdraw.|


