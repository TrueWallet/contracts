# SocialRecovery
[Git Source](https://github.com/TrueWallet/contracts/blob/b38849a85d65fd71e42df8fc5190581d11c83fec/src/guardian/SocialRecovery.sol)

**Inherits:**
[SocialRecoveryErrors](/src/common/Errors.sol/contract.SocialRecoveryErrors.md)


## State Variables
### RECOVERY_PERIOD
All state variables are stored in AccountStorage.Layout with specific storage slot to avoid storage collision

*Recovery period after which recovery could be executed*


```solidity
uint256 public constant RECOVERY_PERIOD = 2 days;
```


## Functions
### onlyGuardian

*Only guardian modifier*


```solidity
modifier onlyGuardian();
```

### confirmRecovery

Allows a guardian to confirm a recovery transaction
First call of this method initiate the recovery process


```solidity
function confirmRecovery(bytes32 recoveryHash) public onlyGuardian;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`recoveryHash`|`bytes32`|transaction hash|


### executeRecovery

Lets the guardians execute the recovery request
This method should be called once current recoveryHash is gathered all required count of confirmations


```solidity
function executeRecovery(address newOwner) public onlyGuardian;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newOwner`|`address`|The new owner address|


### _addGuardianWithThreshold

*Lets the owner add a guardian for its wallet*


```solidity
function _addGuardianWithThreshold(address[] calldata _guardians, uint16 _threshold) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_guardians`|`address[]`|List of guardians' addresses|
|`_threshold`|`uint16`|Required number of guardians to confirm replacement|


### _revokeGuardianWithThreshold

Lets the owner revoke a guardian from the wallet


```solidity
function _revokeGuardianWithThreshold(address guardian, uint16 threshold) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`guardian`|`address`|The guardian address to revoke|
|`threshold`|`uint16`|The new required number of guardians to confirm replacement|


### _transferOwnership

*Transfer ownership once recovery requiest is completed successfully*


```solidity
function _transferOwnership(address newOwner) internal;
```

### _getWalletNonce

*Get wallet's nonce*


```solidity
function _getWalletNonce() internal returns (uint96);
```

### cancelRecovery

Lets the owner cancel an ongoing recovery request


```solidity
function cancelRecovery(bytes32 recoveryHash) public;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`recoveryHash`|`bytes32`|hash of recovery requiest that is already initiated|


### isConfirmedByRequiredGuardians

*Returns true if confirmation count is enough*


```solidity
function isConfirmedByRequiredGuardians(bytes32 recoveryHash) public view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`recoveryHash`|`bytes32`|Data hash|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|confirmation status|


### encodeRecoveryData

*Returns the bytes that are hashed*


```solidity
function encodeRecoveryData(address[] memory _guardians, address _newOwner, uint16 _threshold, uint256 _nonce)
    public
    view
    returns (bytes memory);
```

### getRecoveryHash

*Generates the recovery hash that could be signed by the guardian to authorize a recovery*


```solidity
function getRecoveryHash(address[] memory _guardians, address _newOwner, uint16 _threshold, uint256 _nonce)
    public
    view
    returns (bytes32);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes32`|recoveryHash of data encoding owner replacement|


### executeAfter

*Execute recovery after this period*


```solidity
function executeAfter() public view returns (uint64);
```

### threshold

*Retrieves the wallet threshold count. Required number of guardians to confirm recovery*


```solidity
function threshold() public view returns (uint16);
```

### getGuardians

*Gets the list of guaridans addresses*


```solidity
function getGuardians() public view returns (address[] memory);
```

### guardiansCount

*Returns the number of guardians for a wallet*


```solidity
function guardiansCount() public view returns (uint256);
```

### isGuardian

*Checks if an account is a guardian for a wallet*


```solidity
function isGuardian(address guardian) public view returns (bool);
```

### isConfirmedByGuardian


```solidity
function isConfirmedByGuardian(address guardian, bytes32 recoveryHash) public view returns (bool);
```

### isExecuted

*Checks if a recoveryHash is executed*


```solidity
function isExecuted(bytes32 recoveryHash) public view returns (bool);
```

## Events
### GuardianAdded
*Emitted when guardians and threshold are added*


```solidity
event GuardianAdded(address[] indexed guardians, uint16 threshold);
```

### GuardianRevoked
*Emitted when guardian is revoked*


```solidity
event GuardianRevoked(address indexed guardian);
```

### RecoveryConfirmed
*Emitted when recovery is confirmed by guardian*


```solidity
event RecoveryConfirmed(address indexed guardian, bytes32 indexed recoveryHash);
```

### RecoveryExecuted
*Emitted when recovery is executed by guardian*


```solidity
event RecoveryExecuted(address indexed guardian, bytes32 indexed recoveryHash);
```

### RecoveryCanceled
*Emmited when recovey is canceled by owner*


```solidity
event RecoveryCanceled(bytes32 recoveryHash);
```

### OwnershipRecovered
*Emitted when ownership is transfered after recovery execution*


```solidity
event OwnershipRecovered(address indexed sender, address indexed newOwner);
```

