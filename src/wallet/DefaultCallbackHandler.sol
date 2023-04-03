// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.17;

import "openzeppelin-contracts/utils/introspection/IERC165.sol";
import "src/interfaces/IERC721TokenReceiver.sol";
import "src/interfaces/IERC1155TokenReceiver.sol";
import "src/interfaces/IERC777TokensRecipient.sol";

contract DefaultCallbackHandler is
    IERC721TokenReceiver,
    IERC1155TokenReceiver,
    IERC777TokensRecipient,
    IERC165
{
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return 0x150b7a02;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return 0xf23a6e61;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return 0xbc197c81;
    }

    function tokensReceived(
        address,
        address,
        address,
        uint256,
        bytes calldata,
        bytes calldata
    ) external pure override {
        // We implement this for completeness, doesn't really have any value
    }

    function supportsInterface(
        bytes4 interfaceId
    ) external view virtual override returns (bool) {
        return
            interfaceId == type(IERC1155TokenReceiver).interfaceId ||
            interfaceId == type(IERC721TokenReceiver).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }
}