// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.19;

import {OwnerAuth} from "../authority/OwnerAuth.sol";
import {OwnerManager} from "./OwnerManager.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";
import {ERC1155} from "solmate/tokens/ERC1155.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {WalletErrors} from "src/common/Errors.sol";

/// @title TokenManager
/// @notice This abstract contract defines a set of functionalities to manage various types of token transfers, 
/// including ETH, ERC20, ERC721, and ERC1155 tokens. It ensures that only the owner can initiate the transfers.
abstract contract TokenManager is OwnerAuth, WalletErrors {
    /// @dev Ensures that the function can only be called by the contract owner.
    modifier authorized() {
        if (!_isOwner()) {
            revert InvalidOwner();
        }
        _;
    }

    /// @notice Emitted when ETH is transferred out of the wallet.
    event TransferedETH(address indexed to, uint256 amount);
    /// @notice Emitted when ERC20 tokens are transferred out of the wallet.
    event TransferedERC20(address token, address indexed to, uint256 amount);
    /// @notice Emitted when ERC721 tokens are transferred out of the wallet.
    event TransferedERC721(address indexed collection, uint256 indexed tokenId, address indexed to);
    /// @notice Emitted when ERC1155 tokens are transferred out of the wallet.
    event TransferedERC1155(address indexed collection, uint256 indexed tokenId, uint256 amount, address indexed to);

    /// @notice Transfer ETH out of the wallet.
    /// @param to The recipient's payable address.
    /// @param amount The amount of ETH to transfer.
    function transferETH(address payable to, uint256 amount) external authorized {
        SafeTransferLib.safeTransferETH(to, amount);
        emit TransferedETH(to, amount);
    }

    /// @notice Transfer ERC20 tokens out of the wallet. 
    /// @param token The ERC20 token contract address.
    /// @param to The recipient's address.
    /// @param amount The amount of tokens to transfer.
    function transferERC20(address token, address to, uint256 amount) external authorized {
        SafeTransferLib.safeTransfer(ERC20(token), to, amount);
        emit TransferedERC20(token, to, amount);
    }

    /// @notice Transfer ERC721 tokens out of the wallet.
    /// @param collection The ERC721 token collection contract address.
    /// @param tokenId The unique token ID to transfer.
    /// @param to The recipient's address.
    function transferERC721(address collection, uint256 tokenId, address to) external authorized {
        ERC721(collection).safeTransferFrom(address(this), to, tokenId);
        emit TransferedERC721(collection, tokenId, to);
    }

    /// @notice Transfer ERC1155 tokens out of the wallet.
    /// @param collection The ERC1155 token collection contract address.
    /// @param tokenId The unique token ID to transfer.
    /// @param to The recipient's address.
    /// @param amount The amount of the token type to transfer.
    function transferERC1155(address collection, uint256 tokenId, address to, uint256 amount) external authorized {
        ERC1155(collection).safeTransferFrom(address(this), to, tokenId, amount, "");
        emit TransferedERC1155(collection, tokenId, amount, to);
    }
}