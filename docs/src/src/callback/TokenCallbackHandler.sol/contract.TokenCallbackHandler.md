# TokenCallbackHandler
[Git Source](https://github.com/TrueWallet/contracts/blob/3a8d1f53b9460a762889129a9214639685ad5b95/src/callback/TokenCallbackHandler.sol)

**Inherits:**
IERC721Receiver, IERC1155Receiver, IERC777Recipient


## Functions
### onERC721Received


```solidity
function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4);
```

### onERC1155Received


```solidity
function onERC1155Received(address, address, uint256, uint256, bytes calldata)
    external
    pure
    override
    returns (bytes4);
```

### onERC1155BatchReceived


```solidity
function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
    external
    pure
    override
    returns (bytes4);
```

### tokensReceived


```solidity
function tokensReceived(address, address, address, uint256, bytes calldata, bytes calldata) external pure override;
```

### supportsInterface


```solidity
function supportsInterface(bytes4 interfaceId) external view virtual override returns (bool);
```

