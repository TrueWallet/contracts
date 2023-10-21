// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import {SocialRecoveryModule, ISocialRecoveryModule} from "src/modules/SocialRecoveryModule/SocialRecoveryModule.sol";
import {SecurityControlModule} from "src/modules/SecurityControlModule/SecurityControlModule.sol";
import {TrueContractManager, ITrueContractManager} from "src/registry/TrueContractManager.sol";
import {TrueWallet} from "src/wallet/TrueWallet.sol";
import {TrueWalletProxy} from "src/wallet/TrueWalletProxy.sol";
import {EntryPoint} from "src/entrypoint/EntryPoint.sol";

contract SocialRecoveryModuleUnitTest is Test {
    SocialRecoveryModule socialRecoveryModule;
    SecurityControlModule securityControlModule;
    TrueContractManager contractManager;
    TrueWallet wallet;
    TrueWallet walletImpl;
    TrueWalletProxy proxy;
    EntryPoint entryPoint;

    address adminAddress;
    uint256 adminPrivateKey;
    address walletOwner;
    uint256 walletPrivateKey;

    address[] guardians = new address[](3);
    address guardian1;
    address guardian2;
    address guardian3;
    uint256 threshold;
    bytes32 guardianHash;

    bytes[] initModules = new bytes[](2);
    uint32 controlModuleInitData = 1;
    uint32 upgradeDelay = 172800;
    bytes moduleAddressAndInitData;

    function setUp() public {
        (adminAddress, adminPrivateKey) = makeAddrAndKey("adminAddress");

        contractManager = new TrueContractManager(adminAddress);
        securityControlModule = new SecurityControlModule(ITrueContractManager(contractManager));
        socialRecoveryModule = new SocialRecoveryModule();

        address[] memory modules = new address[](2);
        modules[0] = address(securityControlModule);
        modules[1] = address(socialRecoveryModule);
        vm.prank(address(adminAddress));
        contractManager.add(modules);

        (walletOwner, walletPrivateKey) = makeAddrAndKey("walletOwner");

        guardian1 = makeAddr("guardian1");
        guardian2 = makeAddr("guardian2");
        guardian3 = makeAddr("guardian3");
        guardians[0] = guardian1;
        guardians[1] = guardian2;
        guardians[2] = guardian3;
        threshold = 2;
        bytes memory socialRecoveryModuleInitData = abi.encode(guardians, threshold, guardianHash);
        // (address[] memory _guardians, uint256 _threshold, bytes32 _guardianHash) =
        //     abi.decode(data, (address[], uint256, bytes32));

        entryPoint = new EntryPoint();
        walletImpl = new TrueWallet();
        bytes memory securityControlModuleInitData = abi.encode(uint32(controlModuleInitData));
        initModules[0] = abi.encodePacked(address(securityControlModule), securityControlModuleInitData);
        initModules[1] = abi.encodePacked(address(socialRecoveryModule), socialRecoveryModuleInitData);
        bytes memory data = abi.encodeCall(
            TrueWallet.initialize, (address(entryPoint), address(walletOwner), upgradeDelay, initModules)
        );

        proxy = new TrueWalletProxy(address(walletImpl), data);
        wallet = TrueWallet(payable(address(proxy)));
    }

    function testSetupState() public {
        assertTrue(wallet.isAuthorizedModule(address(securityControlModule)));
        assertTrue(wallet.isAuthorizedModule(address(socialRecoveryModule)));
        (address[] memory _modules, bytes4[][] memory _selectors) = wallet.listModules();
        assertEq(_modules.length, 2);
        assertEq(_modules[0], address(socialRecoveryModule)); // [0] - revers order in returned list of modules
        assertEq(_selectors[0].length, 2);

        // assertEq(socialRecoveryModule.walletInitSeed(address(wallet)), 1);
        assertEq(socialRecoveryModule.nonce(address(wallet)), 0);
        assertTrue(contractManager.isTrueModule(address(socialRecoveryModule)));

        bytes4[] memory selectors = socialRecoveryModule.requiredFunctions();
        assertEq(selectors[0], bytes4(keccak256("resetOwner(address)")));
        assertEq(selectors[1], bytes4(keccak256("resetOwners(address[])")));
    }

    function testGuardianCount() public {
        assertEq(socialRecoveryModule.guardiansCount(address(wallet)), 3);
    }

    function testGetGuardians() public {
        address[] memory walletGuardians = socialRecoveryModule.getGuardians(address(wallet));
        assertEq(walletGuardians.length, 3);
        assertEq(walletGuardians[0], guardian3);
        assertEq(walletGuardians[1], guardian2);
        assertEq(walletGuardians[2], guardian1);
    }

    function testIsGuardian() public {
        assertTrue(socialRecoveryModule.isGuardian(address(wallet), guardian1));
        assertTrue(socialRecoveryModule.isGuardian(address(wallet), guardian2));
        assertTrue(socialRecoveryModule.isGuardian(address(wallet), guardian3));
        assertFalse(socialRecoveryModule.isGuardian(address(wallet), adminAddress));
    }

    function testGetThreshold() public {
        assertEq(socialRecoveryModule.threshold(address(wallet)), 2);
    }

    event ModuleInit(address indexed wallet);
    event ModuleAdded(address indexed module);
    event ModuleRemoved(address indexed module);

    function testInitModule() public {
        // this test needs it's own setup
        SocialRecoveryModule socialRecoveryModule2 = new SocialRecoveryModule();

        address[] memory modules = new address[](1);
        modules[0] = address(socialRecoveryModule2);
        vm.prank(address(adminAddress));
        contractManager.add(modules);

        bytes[] memory initModules2 = new bytes[](1);
        bytes memory securityControlModuleInitData = abi.encode(uint32(controlModuleInitData));
        initModules2[0] = abi.encodePacked(address(securityControlModule), securityControlModuleInitData);

        bytes memory data2 = abi.encodeCall(
            TrueWallet.initialize, (address(entryPoint), address(walletOwner), upgradeDelay, initModules2)
        );

        TrueWalletProxy proxy2 = new TrueWalletProxy(address(walletImpl), data2);
        TrueWallet wallet2 = TrueWallet(payable(address(proxy2)));

        // tests
        // negative cases
        assertFalse(wallet2.isAuthorizedModule(address(socialRecoveryModule2)));
        // if (_threshold == 0 || _threshold > _guardians.length)
        threshold = 0;
        bytes memory socialRecoveryModuleInitData = abi.encode(guardians, threshold, guardianHash);
        moduleAddressAndInitData = abi.encodeWithSelector(
            bytes4(keccak256("addModule(bytes)")),
            abi.encodePacked(address(socialRecoveryModule2), socialRecoveryModuleInitData)
        );
        vm.prank(address(walletOwner));
        // vm.expectRevert("SocialRecovery__InvalidThreshold()");
        vm.expectRevert();
        securityControlModule.execute(address(wallet2), moduleAddressAndInitData);

        threshold = 4;
        socialRecoveryModuleInitData = abi.encode(guardians, threshold, guardianHash);
        moduleAddressAndInitData = abi.encodeWithSelector(
            bytes4(keccak256("addModule(bytes)")),
            abi.encodePacked(address(socialRecoveryModule2), socialRecoveryModuleInitData)
        );
        vm.prank(address(walletOwner));
        // vm.expectRevert("SocialRecovery__InvalidThreshold()");
        vm.expectRevert();
        securityControlModule.execute(address(wallet2), moduleAddressAndInitData);

        // if (_guardians.length > 0) => if (_guardianHash != bytes32(0)) revert
        guardianHash = bytes32(keccak256(abi.encodePacked(guardian1)));
        threshold = 2;
        socialRecoveryModuleInitData = abi.encode(guardians, threshold, guardianHash);
        moduleAddressAndInitData = abi.encodeWithSelector(
            bytes4(keccak256("addModule(bytes)")),
            abi.encodePacked(address(socialRecoveryModule2), socialRecoveryModuleInitData)
        );
        vm.prank(address(walletOwner));
        // vm.expectRevert("SocialRecovery__OnchainGuardianConfigError()");
        vm.expectRevert();
        securityControlModule.execute(address(wallet2), moduleAddressAndInitData);

        // if (_guardians.length == 0) => if (_guardianHash == bytes32(0)) revert
        address[] memory guardiansEmpty;
        guardianHash = bytes32(0);
        threshold = 2;
        socialRecoveryModuleInitData = abi.encode(guardiansEmpty, threshold, guardianHash);
        moduleAddressAndInitData = abi.encodeWithSelector(
            bytes4(keccak256("addModule(bytes)")),
            abi.encodePacked(address(socialRecoveryModule2), socialRecoveryModuleInitData)
        );
        vm.prank(address(walletOwner));
        // vm.expectRevert("SocialRecovery__AnonymousGuardianConfigError()");
        vm.expectRevert();
        securityControlModule.execute(address(wallet2), moduleAddressAndInitData);

        // positive case with onchain guardians
        // if (_guardians.length > 0)
        guardianHash = bytes32(0);
        threshold = 2;
        socialRecoveryModuleInitData = abi.encode(guardians, threshold, guardianHash);
        moduleAddressAndInitData = abi.encodeWithSelector(
            bytes4(keccak256("addModule(bytes)")),
            abi.encodePacked(address(socialRecoveryModule2), socialRecoveryModuleInitData)
        );
        vm.prank(address(walletOwner));
        emit ModuleAdded(address(socialRecoveryModule2));
        emit ModuleInit(address(wallet2));
        securityControlModule.execute(address(wallet2), moduleAddressAndInitData);

        assertTrue(wallet2.isAuthorizedModule(address(socialRecoveryModule2)));
    }

    function testCanInitWithAnonymousGuardians() public {
        // setup
        SocialRecoveryModule socialRecoveryModule2 = new SocialRecoveryModule();

        address[] memory modules = new address[](1);
        modules[0] = address(socialRecoveryModule2);
        vm.prank(address(adminAddress));
        contractManager.add(modules);

        bytes[] memory initModules2 = new bytes[](1);
        bytes memory securityControlModuleInitData = abi.encode(uint32(controlModuleInitData));
        initModules2[0] = abi.encodePacked(address(securityControlModule), securityControlModuleInitData);

        bytes memory data2 = abi.encodeCall(
            TrueWallet.initialize, (address(entryPoint), address(walletOwner), upgradeDelay, initModules2)
        );

        TrueWalletProxy proxy2 = new TrueWalletProxy(address(walletImpl), data2);
        TrueWallet wallet2 = TrueWallet(payable(address(proxy2)));

        // test
        // (_guardians.length == 0) && (_guardianHash != bytes32(0))
        threshold = 2;
        address[] memory guardiansEmpty;
        guardianHash = bytes32(keccak256(abi.encodePacked(guardian1, guardian2, guardian3)));
        bytes memory socialRecoveryModuleInitData = abi.encode(guardiansEmpty, threshold, guardianHash);
        moduleAddressAndInitData = abi.encodeWithSelector(
            bytes4(keccak256("addModule(bytes)")),
            abi.encodePacked(address(socialRecoveryModule2), socialRecoveryModuleInitData)
        );
        vm.prank(address(walletOwner));
        emit ModuleAdded(address(socialRecoveryModule2));
        emit ModuleInit(address(wallet2));
        securityControlModule.execute(address(wallet2), moduleAddressAndInitData);

        assertTrue(wallet2.isAuthorizedModule(address(socialRecoveryModule2)));
        assertEq(socialRecoveryModule2.guardiansCount(address(wallet2)), 0);
        assertEq(socialRecoveryModule2.threshold(address(wallet2)), 2);
    }

    // updateGuardians tests
    address[] guardians2 = new address[](3);
    address guardian2_1 = makeAddr("guardian2_1");
    address guardian2_2 = makeAddr("guardian2_2");
    address guardian2_3 = makeAddr("guardian2_3");
    uint256 threshold2;
    bytes32 guardianHash2;

    function testUpdateGuardians() public {
        guardians2[0] = guardian2_1;
        threshold2 = 1;

        vm.prank(address(wallet));
        socialRecoveryModule.updateGuardians(guardians2, threshold2, guardianHash2);

        (uint256 pendingUntil, uint256 pendingThreshold, bytes32 pendingGuardianHash, address[] memory guardiansUpdated)
        = socialRecoveryModule.pendingGuarian(address(wallet));

        assertEq(pendingUntil, block.timestamp + 2 days);
        assertEq(pendingThreshold, threshold2);
        assertEq(bytes32(pendingGuardianHash), bytes32(guardianHash2));
        assertEq(guardiansUpdated.length, guardians2.length);
    }

    function testRevertsUpdateGuardiansWhenUnauthorized() public {
        guardians2[0] = guardian2_1;
        guardians2[1] = guardian2_2;
        guardians2[2] = guardian2_3;
        threshold2 = 2;

        vm.prank(address(securityControlModule));
        vm.expectRevert(); // ISocialRecoveryModule.SocialRecovery__Unauthorized.selector
        socialRecoveryModule.updateGuardians(guardians2, threshold2, guardianHash2);
    }

    function testRevertsUpdateGuardiansIfOnchainGuardianConfigError() public {
        guardians2[0] = guardian2_1;
        guardians2[1] = guardian2_2;
        guardians2[2] = guardian2_3;
        threshold2 = 2;
        guardianHash2 = bytes32(keccak256(abi.encodePacked(guardian2_1)));

        vm.prank(address(wallet));
        vm.expectRevert(ISocialRecoveryModule.SocialRecovery__OnchainGuardianConfigError.selector);
        socialRecoveryModule.updateGuardians(guardians2, threshold2, guardianHash2);
    }

    function testRevertsUpdateGuardiansWhenInvalidThreshold() public {
        guardians2[0] = guardian2_1;
        guardians2[1] = guardian2_2;
        guardians2[2] = guardian2_3;
        threshold2 = 4;

        vm.prank(address(wallet));
        vm.expectRevert(ISocialRecoveryModule.SocialRecovery__InvalidThreshold.selector);
        socialRecoveryModule.updateGuardians(guardians2, threshold2, guardianHash2);

        vm.prank(address(wallet));
        vm.expectRevert(ISocialRecoveryModule.SocialRecovery__InvalidThreshold.selector);
        socialRecoveryModule.updateGuardians(guardians2, 0, guardianHash2);

        guardianHash2 = bytes32(keccak256(abi.encodePacked(guardian2_1)));
        vm.prank(address(wallet));
        vm.expectRevert(ISocialRecoveryModule.SocialRecovery__InvalidThreshold.selector);
        socialRecoveryModule.updateGuardians(new address[](1), 0, guardianHash2);
    }
}
