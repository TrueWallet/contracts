# TrueWalletFactory
[Git Source](https://github.com/TrueWallet/contracts/blob/b38849a85d65fd71e42df8fc5190581d11c83fec/src/wallet/TrueWalletFactory.sol)

**Inherits:**
Ownable, Pausable, [WalletErrors](/src/common/Errors.sol/contract.WalletErrors.md)


## State Variables
### walletImplementation

```solidity
address public immutable walletImplementation;
```


## Functions
### constructor


```solidity
constructor(address _walletImplementation, address _owner) Ownable Pausable;
```

### createWallet

Deploy a smart wallet, with an entryPoint and Owner specified by the user
Intended that all wallets are deployed through this factory, so if no initCode is passed
then just returns the CREATE2 computed address


```solidity
function createWallet(address entryPoint, address walletOwner, uint32 upgradeDelay, bytes32 salt)
    external
    whenNotPaused
    returns (TrueWallet);
```

### getWalletAddress

Deterministically compute the address of a smart wallet using Create2


```solidity
function getWalletAddress(address entryPoint, address walletOwner, uint32 upgradeDelay, bytes32 salt)
    public
    view
    returns (address);
```

### pause

Pause the TrueWalletFactory to prevent new wallet creation. OnlyOwner


```solidity
function pause() public onlyOwner;
```

### unpause

Unpause the TrueWalletFactory to allow new wallet creation. OnlyOwner


```solidity
function unpause() public onlyOwner;
```

