# IWalletFactory
[Git Source](https://github.com/TrueWallet/contracts/blob/b38849a85d65fd71e42df8fc5190581d11c83fec/src/wallet/IWalletFactory.sol)


## Functions
### createWallet

Deploy a smart wallet, with an entryPoint and Owner specified by the user
Intended that all wallets are deployed through this factory, so if no initCode is passed
then just returns the CREATE2 computed address


```solidity
function createWallet(address entryPoint, address walletOwner, uint32 upgradeDelay, bytes32 salt)
    external
    returns (TrueWallet);
```

### getWalletAddress

Deterministically compute the address of a smart wallet using Create2


```solidity
function getWalletAddress(address entryPoint, address walletOwner, uint32 upgradeDelay, bytes32 salt)
    external
    view
    returns (address);
```

