# NonceManager
[Git Source](https://github.com/TrueWallet/contracts/blob/db2e75cb332931da5fdaa38bec9e4d367be1d851/src/entrypoint/NonceManager.sol)

**Inherits:**
[INonceManager](/src/interfaces/INonceManager.sol/interface.INonceManager.md)

Nonce management functionality


## State Variables
### nonceSequenceNumber
The next valid sequence number for a given nonce key.


```solidity
mapping(address => mapping(uint192 => uint256)) public nonceSequenceNumber;
```


## Functions
### getNonce


```solidity
function getNonce(address sender, uint192 key) public view override returns (uint256 nonce);
```

### incrementNonce


```solidity
function incrementNonce(uint192 key) public override;
```

### _validateAndUpdateNonce

Validate nonce uniqueness for this account.
Called just after validateUserOp()


```solidity
function _validateAndUpdateNonce(address sender, uint256 nonce) internal returns (bool);
```

