// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import {TrueWallet} from "src/wallet/TrueWallet.sol";
import {TrueWalletProxy} from "src/wallet/TrueWalletProxy.sol";
import {EntryPoint} from "src/entrypoint/EntryPoint.sol";
import {MockModule} from "../../mocks/MockModule.sol";
import {ModuleManagerErrors} from "src/common/Errors.sol";
import {MockModuleFailedEmptySelector} from "test/mocks/MockModuleFailedEmptySelector.sol";
import {MockModuleFailedNotSupportInterface} from "test/mocks/MockModuleFailedNotSupportInterface.sol";

contract ModuleManagerUnitTest is Test {
    TrueWallet wallet;
    TrueWallet walletImpl;
    TrueWalletProxy proxy;
    EntryPoint entryPoint;
    address ownerAddress = 0x14dC79964da2C08b23698B3D3cc7Ca32193d9955; // anvil account (7)
    uint256 ownerPrivateKey = uint256(0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356);
    uint256 chainId = block.chainid;

    uint32 upgradeDelay = 172800; // 2 days in seconds

    MockModule module;
    bytes[] modules = new bytes[](1);
    uint32 walletInitValue;
    bytes4 constant functionSign = bytes4(keccak256("transferETH(address,uint256)"));

    address user = makeAddr("user");

    event ModuleInit(address indexed wallet);
    event ModuleDeInit(address indexed wallet);
    event ModuleAdded(address indexed module);
    event ModuleRemoved(address indexed module);
    event ModuleRemovedWithError(address indexed module);

    function setUp() public {
        entryPoint = new EntryPoint();
        walletImpl = new TrueWallet();

        module = new MockModule();
        walletInitValue = 1;
        bytes memory initData = abi.encode(uint32(walletInitValue));
        modules[0] = abi.encodePacked(address(module), initData);

        bytes memory data = abi.encodeCall(
            TrueWallet.initialize,
            (address(entryPoint), ownerAddress, upgradeDelay, modules)
        );

        proxy = new TrueWalletProxy(address(walletImpl), data);
        wallet = TrueWallet(payable(address(proxy)));
    }

    function encodeError(
        string memory error
    ) internal pure returns (bytes memory encoded) {
        encoded = abi.encodeWithSignature(error);
    }

    function testSetupState() public {
        assertTrue(wallet.isOwner(ownerAddress));
        assertEq(address(wallet.entryPoint()), address(entryPoint));
        assertTrue(wallet.isAuthorizedModule(address(module)));

        assertTrue(module.isInit(address(wallet)));
        assertEq(module.requiredFunctions()[0], functionSign);
        assertEq(module.walletInitData(address(wallet)), uint32(walletInitValue));

        (address[] memory _modules, bytes4[][] memory _selectors) = wallet.listModules();
        assertEq(_modules.length, 1);
        assertEq(_modules[0], address(module));
        assertEq(_selectors[0].length, 4);
    }

    MockModule mockModule = new MockModule();

    function testAddModuleByAuthorizedModule() public {
        modules[0] = abi.encodePacked(address(mockModule), abi.encode(uint32(1)));
        assertFalse(mockModule.isInit(address(wallet)));
        assertFalse(wallet.isAuthorizedModule(address(mockModule)));
        (address[] memory _modules,) = wallet.listModules();
        assertEq(_modules.length, 1);
        vm.startPrank(address(module));
        vm.expectEmit(true, true, true, true);
        emit ModuleAdded(address(mockModule));
        emit ModuleInit(address(wallet));
        wallet.addModule(modules[0]);
        vm.stopPrank();
        assertTrue(mockModule.isInit(address(wallet)));
        assertTrue(wallet.isAuthorizedModule(address(mockModule)));
        (_modules,) = wallet.listModules();
        assertEq(_modules.length, 2);
    }

    function testRevertsIfAddModuleByNotAuthorizedModule() public {
        MockModule newModule = new MockModule();
        modules[0] = abi.encodePacked(address(newModule), abi.encode(uint32(1)));
        vm.startPrank(address(user));
        vm.expectRevert(encodeError("CallerMustBeModule()")); 
        wallet.addModule(modules[0]);
        vm.stopPrank();
    }

    function testRevertsIfAddModuleWithModuleAddressEmpty() public {
        bytes[] memory _modules = new bytes[](1);
        vm.startPrank(address(module));
        vm.expectRevert(encodeError("ModuleAddressEmpty()")); 
        wallet.addModule(_modules[0]);
        vm.stopPrank();
    }

    function testRevertsIfModuleSelectorsEmpty() public {
        MockModuleFailedEmptySelector newModule = new MockModuleFailedEmptySelector();
        modules[0] = abi.encodePacked(address(newModule), abi.encode(uint32(1)));
        vm.startPrank(address(module));
        vm.expectRevert(encodeError("InvalidSelector()"));
        wallet.addModule(modules[0]);
        vm.stopPrank();
    }

    function testRevertsIfAddressAlreadyExists() public {
        modules[0] = abi.encodePacked(address(module), abi.encode(uint32(1)));
        vm.startPrank(address(module));
        vm.expectRevert(encodeError("AddressAlreadyExists()")); 
        wallet.addModule(modules[0]);
        vm.stopPrank();
    }

    function testRevertsIfNotSupportInterface() public {
        MockModuleFailedNotSupportInterface newModule = new MockModuleFailedNotSupportInterface();
        modules[0] = abi.encodePacked(address(newModule), abi.encode(uint32(1)));
        vm.startPrank(address(module));
        vm.expectRevert(ModuleManagerErrors.ModuleNotSupportInterface.selector);
        wallet.addModule(modules[0]);
        vm.stopPrank();
    }

    function testRemoveModule() public {
        testAddModuleByAuthorizedModule();
        assertTrue(mockModule.isInit(address(wallet)));
        assertTrue(wallet.isAuthorizedModule(address(mockModule)));
        (address[] memory _modules,) = wallet.listModules();
        assertEq(_modules.length, 2);
        vm.startPrank(address(module));
        vm.expectEmit(true, false, false, true);
        emit ModuleRemoved(address(mockModule));
        emit ModuleDeInit(address(wallet));
        wallet.removeModule(address(mockModule));
        assertFalse(mockModule.isInit(address(wallet)));
        assertFalse(wallet.isAuthorizedModule(address(mockModule)));
        (_modules,) = wallet.listModules();
        assertEq(_modules.length, 1);
    }

    function testRevertsIfRemoveModuleByNotAuthorizedModule() public {
        testAddModuleByAuthorizedModule();
        assertTrue(mockModule.isInit(address(wallet)));
        assertTrue(wallet.isAuthorizedModule(address(mockModule)));
        (address[] memory _modules,) = wallet.listModules();
        assertEq(_modules.length, 2);
        vm.startPrank(address(user));
        vm.expectRevert(encodeError("CallerMustBeModule()"));
        wallet.removeModule(address(mockModule));
        assertTrue(mockModule.isInit(address(wallet)));
        assertTrue(wallet.isAuthorizedModule(address(mockModule)));
        (_modules,) = wallet.listModules();
        assertEq(_modules.length, 2);
    }

    function testExecuteFromModule() public {
        vm.deal(address(wallet), 5 ether);
        assertEq(address(wallet).balance, 5 ether);
        assertEq(address(user).balance, 0);
        uint256 etherTransferAmount = 1 ether;
        bytes memory callData =
        abi.encodeWithSelector(
            wallet.execute.selector,
            address(user),
            etherTransferAmount,
            ""
        );
        assertTrue(wallet.isAuthorizedModule(address(module)));
        vm.deal(address(module), 1 ether);
        vm.startPrank(address(module));
        wallet.executeFromModule(address(user), etherTransferAmount, callData);
        assertEq(address(wallet).balance, 4 ether);
        assertEq(address(user).balance, 1 ether);
    }

    function testRevertsIfModuleExecuteFromModuleRecursive() public {
        vm.deal(address(wallet), 5 ether);
        assertEq(address(wallet).balance, 5 ether);
        assertEq(address(user).balance, 0 ether);
        uint256 etherTransferAmount = 1 ether;
        bytes memory callData = abi.encodeWithSelector(
            wallet.execute.selector,
            address(wallet),
            etherTransferAmount,
            ""
        );
        assertTrue(wallet.isAuthorizedModule(address(module)));
        vm.deal(address(module), 1 ether);
        vm.startPrank(address(module));
        vm.expectRevert(ModuleManagerErrors.ModuleExecuteFromModuleRecursive.selector);
        wallet.executeFromModule(address(wallet), etherTransferAmount, callData);
        assertEq(address(wallet).balance, 5 ether);
        assertEq(address(user).balance, 0 ether);
    }
}