# TrueWalletFactory
[Git Source](https://github.com/TrueWallet/contracts/blob/43e94f0622a36448f24323cfe74a0e2604784f80/src/wallet/TrueWalletFactory.sol)

**Inherits:**
Ownable, Pausable, [WalletErrors](/src/common/Errors.sol/contract.WalletErrors.md)

A factory contract for deploying and managing TrueWallet smart contracts.

*This contract allows for the creation of TrueWallet instances using the CREATE2 opcode for predictable addresses.*


## State Variables
### walletImplementation
Address of the wallet implementation contract.


```solidity
address public immutable walletImplementation;
```


### entryPoint
Address of the entry point contract.


```solidity
address public immutable entryPoint;
```


## Functions
### constructor


```solidity
constructor(address _walletImplementation, address _owner, address _entryPoint) Ownable Pausable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_walletImplementation`|`address`|Address of the wallet implementation contract.|
|`_owner`|`address`|Address of the owner of this factory contract.|
|`_entryPoint`|`address`|Address of the entry point contract.|


### createWallet

Deploy a new TrueWallet smart contract.


```solidity
function createWallet(
    address _entryPoint,
    address _walletOwner,
    uint32 _upgradeDelay,
    bytes[] calldata _modules,
    bytes32 _salt
) external whenNotPaused returns (TrueWallet proxy);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_entryPoint`|`address`|The address of the EntryPoint contract for the new wallet.|
|`_walletOwner`|`address`|The owner address for the new wallet.|
|`_upgradeDelay`|`uint32`|Delay (in seconds) before an upgrade can take effect.|
|`_modules`|`bytes[]`|Array of initial module addresses for the wallet.|
|`_salt`|`bytes32`|A salt value used in the CREATE2 opcode for deterministic address generation.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`proxy`|`TrueWallet`|The address of the newly created TrueWallet contract.|


### getWalletAddress

Computes the deterministic address for a potential wallet deployment using CREATE2.

*This doesn't deploy the wallet, just calculates its address.*


```solidity
function getWalletAddress(
    address _entryPoint,
    address _walletOwner,
    uint32 _upgradeDelay,
    bytes[] calldata _modules,
    bytes32 _salt
) public view returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_entryPoint`|`address`|The address of the EntryPoint contract for the new wallet.|
|`_walletOwner`|`address`|The owner address for the new wallet.|
|`_upgradeDelay`|`uint32`|Delay (in seconds) before an upgrade can take effect.|
|`_modules`|`bytes[]`|Array of initial module addresses for the wallet.|
|`_salt`|`bytes32`|A salt value used in the CREATE2 opcode for deterministic address generation.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|Address of the wallet that would be created using the provided parameters.|


### deposit

Deposit funds into the EntryPoint associated with the factory.


```solidity
function deposit() public payable;
```

### withdrawTo

Withdraw funds from the EntryPoint.


```solidity
function withdrawTo(address payable _withdrawAddress, uint256 _withdrawAmount) public onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_withdrawAddress`|`address payable`|The address to send withdrawn funds to.|
|`_withdrawAmount`|`uint256`|The amount of funds to withdraw.|


### addStake

*Add to the account's stake - amount and delay any pending unstake is first cancelled.*


```solidity
function addStake(uint32 _unstakeDelaySec) external payable onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_unstakeDelaySec`|`uint32`|the new lock duration before the deposit can be withdrawn.|


### unlockStake

*Unlock staked funds from the EntryPoint contract.*


```solidity
function unlockStake() external onlyOwner;
```

### withdrawStake

*Withdraw unlocked staked funds from the EntryPoint contract.*


```solidity
function withdrawStake(address payable _withdrawAddress) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_withdrawAddress`|`address payable`|The address to send withdrawn funds to.|


### pause

Pause the factory to prevent new wallet creation.


```solidity
function pause() public onlyOwner;
```

### unpause

Resume operations and allow new wallet creation.


```solidity
function unpause() public onlyOwner;
```

## Events
### TrueWalletCreation
Event emitted when a new TrueWallet is created.


```solidity
event TrueWalletCreation(TrueWallet wallet);
```

