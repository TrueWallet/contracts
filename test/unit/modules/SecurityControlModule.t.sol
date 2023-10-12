// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import {SecurityControlModule} from "src/modules/SecurityControlModule/SecurityControlModule.sol";
import {TrueContractManager, ITrueContractManager} from "src/registry/TrueContractManager.sol";
import {TrueWallet} from "src/wallet/TrueWallet.sol";
import {TrueWalletProxy} from "src/wallet/TrueWalletProxy.sol";
import {EntryPoint} from "src/entrypoint/EntryPoint.sol";
import {MockModule2} from "../../mocks/MockModule2.sol";
import {MockModule2FailedInvalidSelector} from "../../mocks/MockModule2FailedInvalidSelector.sol";

contract SecurityControlModuleUnitTest is Test {
    SecurityControlModule securityControlModule;
    TrueContractManager contractManager;
    TrueWallet wallet;
    TrueWallet walletImpl;
    TrueWalletProxy proxy;
    EntryPoint entryPoint;
    MockModule2 module;
    MockModule2FailedInvalidSelector moduleWithInvalidSelector;

    address adminAddress;
    uint256 adminPrivateKey;
    address walletOwner;
    uint256 walletPrivateKey;

    bytes[] initModules = new bytes[](1);
    uint32 moduleInitData = 1;
    uint32 upgradeDelay = 172800;
    bytes moduleAddressAndInitData;

    event Execute(address target, bytes data, address sender);

    function setUp() public {
        (adminAddress, adminPrivateKey) = makeAddrAndKey("adminAddress");

        contractManager = new TrueContractManager(adminAddress);
        securityControlModule = new SecurityControlModule(ITrueContractManager(contractManager));

        address[] memory modules = new address[](1);
        modules[0] = address(securityControlModule);
        vm.prank(address(adminAddress));
        contractManager.add(modules);

        (walletOwner, walletPrivateKey) = makeAddrAndKey("walletOwner");

        entryPoint = new EntryPoint();
        walletImpl = new TrueWallet();
        bytes memory initData = abi.encode(uint32(moduleInitData));
        initModules[0] = abi.encodePacked(address(securityControlModule), initData);
        bytes memory data = abi.encodeCall(
            TrueWallet.initialize, (address(entryPoint), address(walletOwner), upgradeDelay, initModules)
        );

        proxy = new TrueWalletProxy(address(walletImpl), data);
        wallet = TrueWallet(payable(address(proxy)));

        module = new MockModule2();

        bytes memory initModuleData = abi.encode(uint32(1)); // can't be zero
        moduleAddressAndInitData = abi.encodeWithSelector(
            bytes4(keccak256("addModule(bytes)")), abi.encodePacked(address(module), initModuleData)
        );
    }

    function testSetupState() public {
        assertTrue(wallet.isAuthorizedModule(address(securityControlModule)));
        (address[] memory _modules, bytes4[][] memory _selectors) = wallet.listModules();
        assertEq(_modules.length, 1);
        assertEq(_modules[0], address(securityControlModule));
        assertEq(_selectors[0].length, 3);

        assertEq(securityControlModule.walletInitSeed(address(wallet)), 1);
        assertEq(address(securityControlModule.trueContractManager()), address(contractManager));

        bytes4[] memory selectors = securityControlModule.requiredFunctions();
        assertEq(selectors[0], bytes4(keccak256("addModule(bytes)")));
        assertEq(selectors[1], bytes4(keccak256("removeModule(address)")));
        assertEq(selectors[2], bytes4(keccak256("executeFromModule(address,uint256,bytes)")));
    }

    function testExecuteAddModule() public {
        address[] memory modules = new address[](1);
        modules[0] = address(module);
        vm.prank(address(adminAddress));
        contractManager.add(modules);
        assertTrue(contractManager.isTrueModule(address(module)));

        (address[] memory _modules,) = wallet.listModules();
        assertEq(_modules.length, 1);

        vm.prank(address(walletOwner));
        vm.expectEmit(true, true, true, true);
        emit Execute(address(wallet), bytes(moduleAddressAndInitData), address(walletOwner));
        securityControlModule.execute(address(wallet), moduleAddressAndInitData);

        assertTrue(wallet.isAuthorizedModule(address(module)));
        assertTrue(module.isInit(address(wallet)));

        (_modules,) = wallet.listModules();
        assertEq(_modules.length, 2);
    }

    function testRevertsExecuteIfExecuteError() public {
        moduleWithInvalidSelector = new MockModule2FailedInvalidSelector();
        address[] memory modules = new address[](1);
        modules[0] = address(moduleWithInvalidSelector);
        vm.prank(address(adminAddress));
        contractManager.add(modules);
        assertTrue(contractManager.isTrueModule(address(moduleWithInvalidSelector)));

        bytes memory data = abi.encodeWithSelector(
            bytes4(keccak256("addModule(bytes)")),
            abi.encodePacked(address(moduleWithInvalidSelector), abi.encode(uint32(1)))
        );

        vm.prank(address(walletOwner));
        vm.expectRevert();
        // vm.expectRevert(
        //     abi.encodeWithSelector(
        //         SecurityControlModule.SecurityControlModule__ExecuteError.selector, address(wallet), data, address(walletOwner), res)
        // );
        securityControlModule.execute(address(wallet), data);
    }

    function testRevertsExecuteIfInvalidModule() public {
        // not whitelisted in contractManager
        vm.prank(address(walletOwner));
        vm.expectRevert(SecurityControlModule.SecurityControlModule__InvalidModule.selector);
        bytes memory initData;
        securityControlModule.execute(
            address(wallet),
            abi.encodeWithSelector(bytes4(keccak256("addModule(bytes)")), abi.encodePacked(address(module), initData))
        );
    }

    function testRevertsExecuteIfUnsupportedSelector() public {
        address[] memory modules = new address[](1);
        modules[0] = address(module);
        vm.prank(address(adminAddress));
        contractManager.add(modules);
        assertTrue(contractManager.isTrueModule(address(module)));

        bytes memory data = abi.encodeWithSelector(
            bytes4(keccak256("addOwner(bytes)")), abi.encodePacked(address(module), abi.encode(uint32(1)))
        );

        vm.prank(address(walletOwner));
        vm.expectRevert(
            abi.encodeWithSelector(
                SecurityControlModule.SecurityControlModule__UnsupportedSelector.selector,
                bytes4(keccak256("addOwner(bytes)"))
            )
        );
        securityControlModule.execute(address(wallet), data);
    }

    function testRevertsExecuteIfInvalidOwner() public {
        address[] memory modules = new address[](1);
        modules[0] = address(module);
        vm.prank(address(adminAddress));
        contractManager.add(modules);
        assertTrue(contractManager.isTrueModule(address(module)));

        // bytes memory initData = abi.encode(uint32(1)); // can't be zero
        // bytes memory data = abi.encodeWithSelector(
        //     bytes4(keccak256("addModule(bytes)")), abi.encodePacked(address(module), initData)
        // );

        address user = makeAddr("user");
        vm.prank(address(user));
        vm.expectRevert(abi.encodeWithSelector(SecurityControlModule.SecurityControlModule__InvalidOwner.selector));
        securityControlModule.execute(address(wallet), moduleAddressAndInitData);
    }

    function testRevertsExecuteIfWalletNotInitialized() public {
        // this test needs it's own setup
        SecurityControlModule securityControlModule2 = new SecurityControlModule(ITrueContractManager(contractManager));
        address[] memory modules = new address[](1);
        modules[0] = address(securityControlModule2);
        vm.prank(address(adminAddress));
        contractManager.add(modules);

        (walletOwner, walletPrivateKey) = makeAddrAndKey("walletOwner");

        entryPoint = new EntryPoint();
        walletImpl = new TrueWallet();
        bytes memory initData = abi.encode(uint32(moduleInitData));
        initModules[0] = abi.encodePacked(address(securityControlModule2), initData);
        bytes memory data = abi.encodeCall(
            TrueWallet.initialize, (address(entryPoint), address(walletOwner), upgradeDelay, initModules)
        );

        proxy = new TrueWalletProxy(address(walletImpl), data);
        wallet = TrueWallet(payable(address(proxy)));

        // test
        module = new MockModule2();
        address[] memory _modules = new address[](1);
        _modules[0] = address(module);
        vm.prank(address(adminAddress));
        contractManager.add(_modules);
        assertTrue(contractManager.isTrueModule(address(module)));

        vm.prank(address(walletOwner));
        vm.expectRevert(abi.encodeWithSelector(SecurityControlModule.SecurityControlModule__NotInitialized.selector));
        securityControlModule.execute(address(wallet), moduleAddressAndInitData);
    }

    function testExecuteRemoveModule() public {
        testExecuteAddModule();
        assertTrue(wallet.isAuthorizedModule(address(module)));
        assertTrue(module.isInit(address(wallet)));
        (address[] memory _modules,) = wallet.listModules();
        assertEq(_modules.length, 2);

        bytes memory data = abi.encodeWithSelector(bytes4(keccak256("removeModule(address)")), address(module));

        vm.prank(address(walletOwner));
        securityControlModule.execute(address(wallet), data);

        (_modules,) = wallet.listModules();
        assertEq(_modules.length, 1);
        assertFalse(wallet.isAuthorizedModule(address(module)));
        assertFalse(module.isInit(address(wallet)));
    }

    function testRevertsExecuteRemoveModuleIfSelfRemove() public {
        testExecuteAddModule();
        assertTrue(wallet.isAuthorizedModule(address(module)));
        assertTrue(module.isInit(address(wallet)));
        (address[] memory _modules,) = wallet.listModules();
        assertEq(_modules.length, 2);

        bytes memory data =
            abi.encodeWithSelector(bytes4(keccak256("removeModule(address)")), address(securityControlModule));

        vm.prank(address(walletOwner));
        vm.expectRevert(SecurityControlModule.SecurityControlModule__UnableSelfRemove.selector);
        securityControlModule.execute(address(wallet), data);

        (_modules,) = wallet.listModules();
        assertEq(_modules.length, 2);
    }

    function testRevertsExecuteRemoveModuleIfInvalidOwner() public {
        testExecuteAddModule();
        assertTrue(wallet.isAuthorizedModule(address(module)));
        assertTrue(module.isInit(address(wallet)));
        (address[] memory _modules,) = wallet.listModules();
        assertEq(_modules.length, 2);

        bytes memory data = abi.encodeWithSelector(bytes4(keccak256("removeModule(address)")), address(module));

        address user = makeAddr("user");
        vm.prank(address(user));
        vm.expectRevert(abi.encodeWithSelector(SecurityControlModule.SecurityControlModule__InvalidOwner.selector));
        securityControlModule.execute(address(wallet), data);

        (_modules,) = wallet.listModules();
        assertEq(_modules.length, 2);
        assertTrue(wallet.isAuthorizedModule(address(module)));
        assertTrue(module.isInit(address(wallet)));
    }

    function testRevertsExecuteRemoveModuleIfExecuteError() public {
        testExecuteAddModule();
        assertTrue(wallet.isAuthorizedModule(address(module)));
        assertTrue(module.isInit(address(wallet)));
        (address[] memory _modules,) = wallet.listModules();
        assertEq(_modules.length, 2);

        address moduleToRemove = _modules[1];
        bytes memory data = abi.encodeWithSelector(
            bytes4(keccak256("removeModule(address)")), abi.encodePacked(address(moduleToRemove))
        );

        vm.prank(address(walletOwner));
        vm.expectRevert(); // SecurityControlModule__ExecuteError
        securityControlModule.execute(address(wallet), data);

        (_modules,) = wallet.listModules();
        assertEq(_modules.length, 2);
        assertTrue(wallet.isAuthorizedModule(address(module)));
        assertTrue(module.isInit(address(wallet)));
    }
}
