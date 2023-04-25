// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "forge-std/Test.sol";

import {TrueWallet} from "src/wallet/TrueWallet.sol";
import {TrueWalletProxy} from "src/wallet/TrueWalletProxy.sol";
import {TrueWalletFactory} from "src/wallet/TrueWalletFactory.sol";
import {EntryPoint} from "src/entrypoint/EntryPoint.sol";
import {MockWalletV2} from "../mock/MockWalletV2.sol";
import {MockERC20} from "../mock/MockERC20.sol";
import {MockERC721} from "../mock/MockERC721.sol";

contract TrueWalletProxyUnitTest is Test {
    TrueWallet wallet;
    TrueWalletProxy proxy;
    TrueWalletFactory factory;
    EntryPoint entryPoint;
    MockWalletV2 walletV2;
    MockERC20 erc20token;
    MockERC721 erc721token;

    address ownerAddress = 0x14dC79964da2C08b23698B3D3cc7Ca32193d9955; // anvil account (7)
    uint256 ownerPrivateKey =
        uint256(0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356);

    bytes32 salt;

    function setUp() public {
        entryPoint = new EntryPoint();
        wallet = new TrueWallet();
        factory = new TrueWalletFactory(address(wallet), address(this));
        walletV2 = new MockWalletV2();
        erc20token = new MockERC20();
        erc721token = new MockERC721("Token", "TKN");

        bytes memory data = abi.encodeCall(
            TrueWallet.initialize,
            (address(entryPoint), ownerAddress)
        );

        proxy = new TrueWalletProxy(address(wallet), data);

        salt = keccak256(
            abi.encodePacked(address(factory), address(entryPoint))
        );
    }

    function deployWallet() public returns (TrueWallet proxyWallet) {
        proxyWallet = factory.createWallet(
            address(entryPoint),
            ownerAddress,
            salt
        );

        return proxyWallet;
    }

    function testUpgradeWallet() public {
        TrueWallet proxyWallet = deployWallet();

        assertEq(address(proxyWallet.entryPoint()), address(entryPoint));
        assertEq(proxyWallet.owner(), ownerAddress);

        assertEq(address(entryPoint).balance, 0);

        vm.deal(address(proxyWallet), 1 ether);
        address notOwner = address(13);
        vm.prank(address(notOwner));
        vm.expectRevert();
        proxyWallet.withdrawETH(payable(address(entryPoint)), 1 ether);
        assertEq(address(entryPoint).balance, 0);

        vm.prank(address(ownerAddress));
        proxyWallet.upgradeTo(address(walletV2));

        vm.prank(address(notOwner));
        proxyWallet.withdrawETH(payable(address(entryPoint)), 1 ether);
        assertEq(address(entryPoint).balance, 1 ether);
    }

    function testUpgradeWalletNotOwner() public {
        TrueWallet proxyWallet = deployWallet();

        assertEq(address(proxyWallet.entryPoint()), address(entryPoint));
        assertEq(proxyWallet.owner(), ownerAddress);

        assertEq(address(entryPoint).balance, 0);

        vm.deal(address(proxyWallet), 1 ether);
        address notOwner = address(13);
        vm.prank(address(notOwner));
        vm.expectRevert();
        proxyWallet.withdrawETH(payable(address(entryPoint)), 1 ether);
        assertEq(address(entryPoint).balance, 0);

        vm.prank(address(notOwner));
        vm.expectRevert();
        proxyWallet.upgradeTo(address(walletV2));
    }

    function testUpgradeWalletByEntryPoint() public {
        TrueWallet proxyWallet = deployWallet();

        assertEq(address(proxyWallet.entryPoint()), address(entryPoint));
        assertEq(proxyWallet.owner(), ownerAddress);

        assertEq(address(entryPoint).balance, 0);

        vm.deal(address(proxyWallet), 1 ether);

        vm.prank(address(entryPoint));
        proxyWallet.upgradeTo(address(walletV2));

        address notOwner = address(13);
        vm.prank(address(notOwner));
        proxyWallet.withdrawETH(payable(address(entryPoint)), 1 ether);
        assertEq(address(entryPoint).balance, 1 ether);
    }

    function testProxy() public {
        TrueWallet proxyWallet = TrueWallet(payable(address(proxy)));

        assertEq(address(proxyWallet.entryPoint()), address(entryPoint));
        assertEq(proxyWallet.owner(), ownerAddress);

        assertEq(address(entryPoint).balance, 0);

        vm.deal(address(proxyWallet), 1 ether);
        address notOwner = address(13);
        vm.prank(address(notOwner));
        vm.expectRevert();
        proxyWallet.withdrawETH(payable(address(entryPoint)), 1 ether);
        assertEq(address(entryPoint).balance, 0);

        vm.prank(address(ownerAddress));
        proxyWallet.upgradeTo(address(walletV2));

        vm.prank(address(notOwner));
        proxyWallet.withdrawETH(payable(address(entryPoint)), 1 ether);
        assertEq(address(entryPoint).balance, 1 ether);
    }

    function testProxyState() public {
        TrueWallet proxyWallet = deployWallet();

        assertEq(address(proxyWallet.entryPoint()), address(entryPoint));
        assertEq(proxyWallet.owner(), ownerAddress);

        assertEq(address(entryPoint).balance, 0);

        vm.deal(address(proxyWallet), 2 ether);
        assertEq(address(proxyWallet).balance, 2 ether);

        erc20token.mint(address(proxyWallet), 1 ether);
        assertEq(erc20token.balanceOf(address(proxyWallet)), 1 ether);

        erc721token.safeMint(address(proxyWallet), 1237);

        assertEq(address(proxyWallet).balance, 2 ether);
        assertEq(erc20token.balanceOf(address(proxyWallet)), 1 ether);
        assertEq(erc721token.ownerOf(1237), address(proxyWallet));
        assertEq(erc721token.balanceOf(address(proxyWallet)), 1);

        vm.startPrank(address(ownerAddress));
        proxyWallet.upgradeTo(address(walletV2));

        assertEq(address(proxyWallet).balance, 2 ether);
        assertEq(erc20token.balanceOf(address(proxyWallet)), 1 ether);
        assertEq(erc721token.ownerOf(1237), address(proxyWallet));
        assertEq(erc721token.balanceOf(address(proxyWallet)), 1);
        
        address to = address(0xABCD);

        proxyWallet.withdrawETH(payable(address(entryPoint)), 1 ether);
        proxyWallet.withdrawERC20(address(erc20token), address(entryPoint), 1 ether);
        proxyWallet.withdrawERC721(address(erc721token), 1237, to);

        assertEq(address(proxyWallet).balance, 1 ether);
        assertEq(erc20token.balanceOf(address(proxyWallet)), 0);
        assertEq(erc721token.balanceOf(address(proxyWallet)), 0);
    }
}