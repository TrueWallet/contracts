// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import {TrueWallet} from "src/wallet/TrueWallet.sol";
import {TrueWalletProxy} from "src/wallet/TrueWalletProxy.sol";
import {TrueWalletFactory} from "src/wallet/TrueWalletFactory.sol";
import {EntryPoint, IEntryPoint} from "src/entrypoint/EntryPoint.sol";
import {MockWalletV2} from "../../mocks/MockWalletV2.sol";
import {MockERC20} from "../../mocks/MockERC20.sol";
import {MockERC721} from "../../mocks/MockERC721.sol";
import {ILogicUpgradeControl} from "src/interfaces/ILogicUpgradeControl.sol";
import {MockModule} from "../../mocks/MockModule.sol";

contract TrueWalletProxyUnitTest is Test {
    TrueWallet wallet;
    TrueWalletProxy proxy;
    TrueWalletFactory factory;
    EntryPoint entryPoint;
    MockWalletV2 walletV2;
    MockERC20 erc20token;
    MockERC721 erc721token;

    address ownerAddress = 0x14dC79964da2C08b23698B3D3cc7Ca32193d9955; // anvil account (7)
    uint256 ownerPrivateKey = uint256(0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356);

    uint32 upgradeDelay = 172800; // 2 days in seconds
    bytes32 salt;

    MockModule mockModule;
    bytes[] modules = new bytes[](1);

    function setUp() public {
        entryPoint = new EntryPoint();
        wallet = new TrueWallet();
        factory = new TrueWalletFactory(address(wallet), address(this), address(entryPoint));
        walletV2 = new MockWalletV2();
        erc20token = new MockERC20();
        erc721token = new MockERC721("Token", "TKN");

        mockModule = new MockModule();
        bytes memory initData = abi.encode(uint32(1));
        modules[0] = abi.encodePacked(mockModule, initData);

        bytes memory data = abi.encodeCall(
            TrueWallet.initialize,
            (address(entryPoint), ownerAddress, upgradeDelay, modules)
        );

        proxy = new TrueWalletProxy(address(wallet), data);

        salt = keccak256(
            abi.encodePacked(
                address(factory),
                address(entryPoint),
                upgradeDelay
            )
        );
    }

    function deployWallet() public returns (TrueWallet proxyWallet) {
        proxyWallet = factory.createWallet(
            address(entryPoint),
            ownerAddress,
            upgradeDelay,
            modules,
            salt
        );
    }

    function preUpgrade(TrueWallet proxyWallet) public {
        proxyWallet.preUpgradeTo(address(walletV2));
        vm.warp(block.timestamp + upgradeDelay);
    }

    function encodeError(
        string memory error
    ) internal pure returns (bytes memory encoded) {
        encoded = abi.encodeWithSignature(error);
    }

    function testUpgradeWallet() public {
        TrueWallet proxyWallet = deployWallet();

        assertEq(address(proxyWallet.entryPoint()), address(entryPoint));
        assertTrue(proxyWallet.isOwner(ownerAddress));

        assertEq(address(entryPoint).balance, 0);

        vm.deal(address(proxyWallet), 1 ether);
        address notOwner = address(13);
        vm.prank(address(notOwner));
        vm.expectRevert();
        proxyWallet.transferETH(payable(address(entryPoint)), 1 ether);
        assertEq(address(entryPoint).balance, 0);

        vm.prank(address(ownerAddress));
        preUpgrade(proxyWallet);

        ILogicUpgradeControl.UpgradeLayout memory layout = proxyWallet
            .logicUpgradeInfo();
        assertEq(address(walletV2), layout.pendingImplementation);
        assertEq(layout.activateTime, upgradeDelay + 1);

        proxyWallet.upgrade();

        vm.prank(address(notOwner));
        proxyWallet.transferETH(payable(address(entryPoint)), 1 ether);
        assertEq(address(entryPoint).balance, 1 ether);

        ILogicUpgradeControl.UpgradeLayout memory layoutAfter = proxyWallet
            .logicUpgradeInfo();
        assertEq(address(0), layoutAfter.pendingImplementation);
        assertEq(layoutAfter.activateTime, 0);
    }

    function testPreUpgradeWalletNeitherOwnerNorEntryPoint() public {
        TrueWallet proxyWallet = deployWallet();

        assertEq(address(proxyWallet.entryPoint()), address(entryPoint));
        assertTrue(proxyWallet.isOwner(ownerAddress));

        assertEq(address(entryPoint).balance, 0);

        vm.deal(address(proxyWallet), 1 ether);
        address notOwner = address(13);
        vm.prank(address(notOwner));
        vm.expectRevert();
        proxyWallet.transferETH(payable(address(entryPoint)), 1 ether);
        assertEq(address(entryPoint).balance, 0);

        vm.prank(address(notOwner));
        vm.expectRevert();
        preUpgrade(proxyWallet);
    }

    function testUpgradeWalletByEntryPoint() public {
        TrueWallet proxyWallet = deployWallet();

        assertEq(address(proxyWallet.entryPoint()), address(entryPoint));
        assertTrue(proxyWallet.isOwner(ownerAddress));

        assertEq(address(entryPoint).balance, 0);

        vm.deal(address(proxyWallet), 1 ether);

        vm.prank(address(entryPoint));
        preUpgrade(proxyWallet);
        proxyWallet.upgrade();

        address notOwner = address(13);
        vm.prank(address(notOwner));
        proxyWallet.transferETH(payable(address(entryPoint)), 1 ether);
        assertEq(address(entryPoint).balance, 1 ether);
    }

    function testProxy() public {
        TrueWallet proxyWallet = TrueWallet(payable(address(proxy)));

        assertEq(address(proxyWallet.entryPoint()), address(entryPoint));
        assertTrue(proxyWallet.isOwner(ownerAddress));

        assertEq(address(entryPoint).balance, 0);

        vm.deal(address(proxyWallet), 1 ether);
        address notOwner = address(13);
        vm.prank(address(notOwner));
        vm.expectRevert();
        proxyWallet.transferETH(payable(address(entryPoint)), 1 ether);
        assertEq(address(entryPoint).balance, 0);

        vm.prank(address(ownerAddress));
        preUpgrade(proxyWallet);
        proxyWallet.upgrade();

        vm.prank(address(notOwner));
        proxyWallet.transferETH(payable(address(entryPoint)), 1 ether);
        assertEq(address(entryPoint).balance, 1 ether);
    }

    function testProxyState() public {
        TrueWallet proxyWallet = deployWallet();

        assertEq(address(proxyWallet.entryPoint()), address(entryPoint));
        assertTrue(proxyWallet.isOwner(ownerAddress));

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

        vm.prank(address(ownerAddress));
        preUpgrade(proxyWallet);
        proxyWallet.upgrade();

        assertEq(address(proxyWallet.entryPoint()), address(entryPoint));
        assertTrue(proxyWallet.isOwner(ownerAddress));

        assertEq(address(proxyWallet).balance, 2 ether);
        assertEq(erc20token.balanceOf(address(proxyWallet)), 1 ether);
        assertEq(erc721token.ownerOf(1237), address(proxyWallet));
        assertEq(erc721token.balanceOf(address(proxyWallet)), 1);

        address to = address(0xABCD);

        proxyWallet.transferETH(payable(address(entryPoint)), 1 ether);
        vm.startPrank(address(ownerAddress));
        proxyWallet.transferERC20(
            address(erc20token),
            address(entryPoint),
            1 ether
        );
        proxyWallet.transferERC721(address(erc721token), 1237, to);

        assertEq(address(proxyWallet).balance, 1 ether);
        assertEq(erc20token.balanceOf(address(proxyWallet)), 0);
        assertEq(erc721token.balanceOf(address(proxyWallet)), 0);
    }

    function testPreUpgradeToZeroAddress() public {
        TrueWallet proxyWallet = deployWallet();

        assertEq(address(proxyWallet.entryPoint()), address(entryPoint));
        assertTrue(proxyWallet.isOwner(ownerAddress));

        assertEq(address(entryPoint).balance, 0);

        vm.prank(address(ownerAddress));
        proxyWallet.preUpgradeTo(address(0));

        ILogicUpgradeControl.UpgradeLayout memory layout = proxyWallet
            .logicUpgradeInfo();
        assertEq(layout.pendingImplementation, address(0));
        assertEq(layout.activateTime, 0);
    }

    function testUpgradeInCaseZeroAddress() public {
        TrueWallet proxyWallet = deployWallet();

        assertEq(address(proxyWallet.entryPoint()), address(entryPoint));
        assertTrue(proxyWallet.isOwner(ownerAddress));

        assertEq(address(entryPoint).balance, 0);

        vm.prank(address(ownerAddress));
        proxyWallet.preUpgradeTo(address(0));

        ILogicUpgradeControl.UpgradeLayout memory layout = proxyWallet
            .logicUpgradeInfo();
        assertEq(layout.pendingImplementation, address(0));
        assertEq(layout.activateTime, 0);

        vm.expectRevert(encodeError("UpgradeDelayNotElapsed()"));
        proxyWallet.upgrade();
    }

    function testUpgradeWhenActivateTimeNotStarted() public {
        TrueWallet proxyWallet = deployWallet();

        assertEq(address(proxyWallet.entryPoint()), address(entryPoint));
        assertTrue(proxyWallet.isOwner(ownerAddress));

        assertEq(address(entryPoint).balance, 0);

        vm.prank(address(ownerAddress));
        proxyWallet.preUpgradeTo(address(walletV2));

        ILogicUpgradeControl.UpgradeLayout memory layout = proxyWallet
            .logicUpgradeInfo();
        assertEq(layout.pendingImplementation, address(walletV2));
        assertEq(layout.activateTime, upgradeDelay + 1);

        vm.expectRevert(encodeError("UpgradeDelayNotElapsed()"));
        proxyWallet.upgrade();
    }
}
