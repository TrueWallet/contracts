# IWalletFactory
[Git Source](https://github.com/TrueWallet/contracts/blob/db2e75cb332931da5fdaa38bec9e4d367be1d851/src/wallet/IWalletFactory.sol)


## Functions
### createWallet

Deploy a smart wallet, with an entryPoint and Owner specified by the user
Intended that all wallets are deployed through this factory, so if no initCode is passed
then just returns the CREATE2 computed address


```solidity
function createWallet(
    address entryPoint,
    address walletOwner,
    uint32 upgradeDelay,
    bytes[] calldata modules,
    bytes32 salt
) external returns (TrueWallet);
```

### getWalletAddress

Deterministically compute the address of a smart wallet using Create2


```solidity
function getWalletAddress(
    address entryPoint,
    address walletOwner,
    uint32 upgradeDelay,
    bytes[] calldata modules,
    bytes32 salt
) external view returns (address);
```

