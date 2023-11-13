# TrueWallet
[Git Source](https://github.com/TrueWallet/contracts/blob/43e94f0622a36448f24323cfe74a0e2604784f80/src/wallet/TrueWallet.sol)

**Inherits:**
[IWallet](/src/wallet/IWallet.sol/interface.IWallet.md), [Initializable](/src/utils/Initializable.sol/abstract.Initializable.md), [Authority](/src/authority/Authority.sol/abstract.Authority.md), [ModuleManager](/src/base/ModuleManager.sol/abstract.ModuleManager.md), [OwnerManager](/src/base/OwnerManager.sol/abstract.OwnerManager.md), [TokenManager](/src/base/TokenManager.sol/abstract.TokenManager.md), [LogicUpgradeControl](/src/utils/LogicUpgradeControl.sol/contract.LogicUpgradeControl.md), [TokenCallbackHandler](/src/callback/TokenCallbackHandler.sol/contract.TokenCallbackHandler.md)

*This contract provides functionality to execute AA (ERC-4337) UserOperetion
It allows to receive and manage assets using the owner account of the smart contract wallet*


## Functions
### onlyOwner

*Only from EOA owner, or through the account itself (which gets redirected through execute())*


```solidity
modifier onlyOwner();
```

### onlyEntryPointOrOwner

Validate that only the entryPoint or Owner is able to call a method


```solidity
modifier onlyEntryPointOrOwner();
```

### constructor

*This prevents initialization of the implementation contract itself*


```solidity
constructor();
```

### initialize

Initialize function to setup the true wallet contract


```solidity
function initialize(address _entryPoint, address _owner, uint32 _upgradeDelay, bytes[] calldata _modules)
    public
    initializer;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_entryPoint`|`address`|trused entrypoint|
|`_owner`|`address`|wallet sign key address|
|`_upgradeDelay`|`uint32`|upgrade delay which update take effect|
|`_modules`|`bytes[]`|The list of encoded modules to be added and its associated initialization data.|


### receive

*This function is a special fallback function that is triggered when the contract receives Ether*


```solidity
receive() external payable;
```

### entryPoint

Returns the entryPoint address


```solidity
function entryPoint() public view returns (address);
```

### nonce

Returns the contract nonce


```solidity
function nonce() public view returns (uint256);
```

### setEntryPoint

Set the entrypoint contract, restricted to onlyOwner


```solidity
function setEntryPoint(address _newEntryPoint) external onlyOwner;
```

### validateUserOp

Validate that the userOperation is valid


```solidity
function validateUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 missingWalletFunds)
    external
    override
    onlyEntryPointOrOwner
    returns (uint256 validationData);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`userOp`|`UserOperation`|- ERC-4337 User Operation|
|`userOpHash`|`bytes32`|- Hash of the user operation, entryPoint address and chainId|
|`missingWalletFunds`|`uint256`|- Amount of ETH to pay the EntryPoint for processing the transaction|


### execute

Method called by entryPoint or owner to execute the calldata supplied by a wallet


```solidity
function execute(address target, uint256 value, bytes calldata payload) external onlyEntryPointOrOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`target`|`address`|- Address to send calldata payload for execution|
|`value`|`uint256`|- Amount of ETH to forward to target|
|`payload`|`bytes`|- Calldata to send to target for execution|


### executeBatch

Execute a sequence of transactions, called directly by owner or by entryPoint. Maximum 8.


```solidity
function executeBatch(address[] calldata target, uint256[] calldata value, bytes[] calldata payload)
    external
    onlyEntryPointOrOwner;
```

### preUpgradeTo

preUpgradeTo is called before upgrading the wallet


```solidity
function preUpgradeTo(address newImplementation) external onlyEntryPointOrOwner;
```

### getDeposite

Returns the wallet's deposit in EntryPoint


```solidity
function getDeposite() public view returns (uint256);
```

### addDeposite

Add to the deposite of the wallet in EntryPoint. Deposit is used to pay user gas fees


```solidity
function addDeposite() public payable;
```

### withdrawDepositeTo

Withdraw funds from the wallet's deposite in EntryPoint


```solidity
function withdrawDepositeTo(address payable to, uint256 amount) public onlyOwner;
```

### _validateSignature

Validate the signature of the userOperation


```solidity
function _validateSignature(UserOperation calldata userOp, bytes32 userOpHash)
    internal
    virtual
    returns (uint256 validationData);
```

### _payPrefund

Sends to the entrypoint (msg.sender) the missing funds for this transaction.
Pay the EntryPoint in ETH ahead of time for the transaction that it will execute
Amount to pay may be zero, if the entryPoint has sufficient funds or if a paymaster is used
to pay the entryPoint through other means.
(E.g. send to the entryPoint more than the minimum required, so that in future transactions
it will not be required to send again)


```solidity
function _payPrefund(uint256 missingAccountFunds) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`missingAccountFunds`|`uint256`|- The min minimum value this method should send the entrypoint. This value MAY be zero, in case there is enough deposit, or the userOp has a paymaster.|


### _call

Perform and validate the function call


```solidity
function _call(address target, uint256 value, bytes memory data) internal;
```

### _authorizeUpgrade

*Required by the OZ UUPS module*


```solidity
function _authorizeUpgrade(address) internal onlyOwner;
```

### _isOwner

*Returns true if the caller is the wallet owner. Compatibility with OwnerAuth*


```solidity
function _isOwner() internal view override returns (bool);
```

### isValidSignature

Support ERC-1271, verifies that the signer is the owner of the signing contract


```solidity
function isValidSignature(bytes32 hash, bytes memory signature) public view returns (bytes4 magicValue);
```

### supportsInterface

Support ERC165, query if a contract implements an interface


```solidity
function supportsInterface(bytes4 _interfaceID) public view override(TokenCallbackHandler) returns (bool);
```

## Events
### AccountInitialized
All state variables are stored in AccountStorage. Layout with specific storage slot to avoid storage collision.


```solidity
event AccountInitialized(address indexed account, address indexed entryPoint, address owner, uint32 upgradeDelay);
```

### UpdateEntryPoint

```solidity
event UpdateEntryPoint(address indexed newEntryPoint, address indexed oldEntryPoint);
```

### OwnershipTransferred

```solidity
event OwnershipTransferred(address indexed sender, address indexed newOwner);
```

### ReceivedETH

```solidity
event ReceivedETH(address indexed sender, uint256 indexed amount);
```

