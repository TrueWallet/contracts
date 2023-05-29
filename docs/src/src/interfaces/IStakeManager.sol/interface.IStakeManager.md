# IStakeManager
[Git Source](https://github.com/TrueWallet/contracts/blob/b38849a85d65fd71e42df8fc5190581d11c83fec/src/interfaces/IStakeManager.sol)

Manage deposits and stakes.
Deposit is just a balance used to pay for UserOperations (either by a paymaster or an account).
Stake is value locked for at least "unstakeDelay" by a paymaster.


## Functions
### getDepositInfo


```solidity
function getDepositInfo(address account) external view returns (DepositInfo memory info);
```

### balanceOf

Return the deposit (for gas payment) of the account


```solidity
function balanceOf(address account) external view returns (uint256);
```

### depositTo

Add to the deposit of the given account


```solidity
function depositTo(address account) external payable;
```

### addStake

Add to the account's stake - amount and delay
any pending unstake is first cancelled.


```solidity
function addStake(uint32 _unstakeDelaySec) external payable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_unstakeDelaySec`|`uint32`|the new lock duration before the deposit can be withdrawn.|


### unlockStake

Attempt to unlock the stake.
the value can be withdrawn (using withdrawStake) after the unstake delay.


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


## Events
### Deposited

```solidity
event Deposited(address indexed account, uint256 totalDeposit);
```

### Withdrawn

```solidity
event Withdrawn(address indexed account, address withdrawAddress, uint256 withdrawAmount);
```

### StakeLocked
Emitted when stake or unstake delay are modified


```solidity
event StakeLocked(address indexed account, uint256 totalStaked, uint256 withdrawTime);
```

### StakeUnlocked
Emitted once a stake is scheduled for withdrawal


```solidity
event StakeUnlocked(address indexed account, uint256 withdrawTime);
```

### StakeWithdrawn

```solidity
event StakeWithdrawn(address indexed account, address withdrawAddress, uint256 withdrawAmount);
```

## Structs
### DepositInfo
*sizes were chosen so that (deposit,staked) fit into one cell (used during handleOps)
and the rest fit into a 2nd cell.
112 bit allows for 2^15 eth
64 bit for full timestamp
32 bit allow 150 years for unstake delay*


```solidity
struct DepositInfo {
    uint112 deposit;
    bool staked;
    uint112 stake;
    uint32 unstakeDelaySec;
    uint64 withdrawTime;
}
```

