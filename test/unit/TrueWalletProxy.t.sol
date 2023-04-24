// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "forge-std/Test.sol";

import {TrueWalletProxy} from "src/wallet/TrueWalletProxy.sol";
import {TrueWallet} from "src/wallet/TrueWallet.sol";
import {TrueWalletFactory} from "src/wallet/TrueWalletFactory.sol";
import {EntryPoint} from "src/entrypoint/EntryPoint.sol";
import {MockWalletV2} from "../mock/MockWalletV2.sol";

contract TrueWalletProxyUnitTest is Test {
    TrueWalletFactory factory;
    TrueWalletProxy proxy;
    TrueWallet wallet;
    EntryPoint entryPoint;
    MockWalletV2 walletV2;

    address ownerAddress = 0x14dC79964da2C08b23698B3D3cc7Ca32193d9955; // anvil account (7)
    uint256 ownerPrivateKey =
        uint256(
            0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356
        );
    uint256 chainId = block.chainid;

    bytes32 salt;

    function setUp() public {
        entryPoint = new EntryPoint();
        wallet = new TrueWallet();
        factory = new TrueWalletFactory(address(wallet), address(this));
        walletV2 = new MockWalletV2();

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
        TrueWallet proxyWallet = factory.createWallet(
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
}
