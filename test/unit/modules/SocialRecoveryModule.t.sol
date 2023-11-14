// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import {
    SocialRecoveryModule,
    ISocialRecoveryModule,
    RecoveryEntry
} from "src/modules/SocialRecoveryModule/SocialRecoveryModule.sol";
import {SecurityControlModule} from "src/modules/SecurityControlModule/SecurityControlModule.sol";
import {TrueContractManager, ITrueContractManager} from "src/registry/TrueContractManager.sol";
import {TrueWallet, IWallet} from "src/wallet/TrueWallet.sol";
import {TrueWalletProxy} from "src/wallet/TrueWalletProxy.sol";
import {EntryPoint} from "test/mocks/entrypoint/EntryPoint.sol";
import {createSignature3} from "test/utils/createSignature.sol";

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
    uint256 guardian1PrivateKey;
    uint256 guardian2PrivateKey;
    uint256 guardian3PrivateKey;
    uint256 threshold;
    bytes32 guardianHash;

    bytes[] initModules = new bytes[](2);
    uint32 controlModuleInitData = 1;
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
        (guardian1, guardian1PrivateKey) = makeAddrAndKey("guardian1");
        (guardian2, guardian2PrivateKey) = makeAddrAndKey("guardian2");
        (guardian3, guardian3PrivateKey) = makeAddrAndKey("guardian3");
        guardians[0] = guardian1;
        guardians[1] = guardian2;
        guardians[2] = guardian3;
        threshold = 2;
        bytes memory socialRecoveryModuleInitData = abi.encode(guardians, threshold, guardianHash);

        entryPoint = new EntryPoint();
        walletImpl = new TrueWallet();
        bytes memory securityControlModuleInitData = abi.encode(uint32(controlModuleInitData));
        initModules[0] = abi.encodePacked(address(securityControlModule), securityControlModuleInitData);
        initModules[1] = abi.encodePacked(address(socialRecoveryModule), socialRecoveryModuleInitData);
        bytes memory data = abi.encodeCall(
            TrueWallet.initialize, (address(entryPoint), address(walletOwner), initModules)
        );
        proxy = new TrueWalletProxy(address(walletImpl), data);
        wallet = TrueWallet(payable(address(proxy)));
    }

    ///////////////////////////////////
    //       setupState Tests        //
    ///////////////////////////////////

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

    ///////////////////////////////////
    //       initModule Tests        //
    ///////////////////////////////////

    event ModuleInit(address indexed wallet);
    event ModuleAdded(address indexed module);
    event ModuleRemoved(address indexed module);

    TrueWallet wallet2;
    SocialRecoveryModule socialRecoveryModule2;

    function testInitModule() public {
        // this test needs it's own setup
        socialRecoveryModule2 = new SocialRecoveryModule();

        address[] memory modules = new address[](1);
        modules[0] = address(socialRecoveryModule2);
        vm.prank(address(adminAddress));
        contractManager.add(modules);

        bytes[] memory initModules2 = new bytes[](1);
        bytes memory securityControlModuleInitData = abi.encode(uint32(controlModuleInitData));
        initModules2[0] = abi.encodePacked(address(securityControlModule), securityControlModuleInitData);

        bytes memory data2 = abi.encodeCall(
            TrueWallet.initialize, (address(entryPoint), address(walletOwner), initModules2)
        );

        TrueWalletProxy proxy2 = new TrueWalletProxy(address(walletImpl), data2);
        wallet2 = TrueWallet(payable(address(proxy2)));

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
        socialRecoveryModule2 = new SocialRecoveryModule();

        address[] memory modules = new address[](1);
        modules[0] = address(socialRecoveryModule2);
        vm.prank(address(adminAddress));
        contractManager.add(modules);

        bytes[] memory initModules2 = new bytes[](1);
        bytes memory securityControlModuleInitData = abi.encode(uint32(controlModuleInitData));
        initModules2[0] = abi.encodePacked(address(securityControlModule), securityControlModuleInitData);

        bytes memory data2 = abi.encodeCall(
            TrueWallet.initialize, (address(entryPoint), address(walletOwner), initModules2)
        );

        TrueWalletProxy proxy2 = new TrueWalletProxy(address(walletImpl), data2);
        wallet2 = TrueWallet(payable(address(proxy2)));

        // test
        // (_guardians.length == 0) && (_guardianHash != bytes32(0))
        threshold = 2;
        uint256 salt = 42;
        address[] memory guardiansEmpty;
        // guardianHash = bytes32(keccak256(abi.encodePacked(guardian1, guardian2, guardian3, salt)));
        guardianHash = bytes32(keccak256(abi.encodePacked(guardians, salt)));
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

    ///////////////////////////////////
    // updatePendingGuardians Tests  //
    ///////////////////////////////////

    address[] guardians2 = new address[](3);
    address guardian2_1 = makeAddr("guardian2_1");
    address guardian2_2 = makeAddr("guardian2_2");
    address guardian2_3 = makeAddr("guardian2_3");
    uint256 threshold2;
    bytes32 guardianHash2;

    function testUpdatePendingGuardians() public {
        guardians2[0] = guardian2_1;
        threshold2 = 1;

        vm.prank(address(wallet));
        socialRecoveryModule.updatePendingGuardians(guardians2, threshold2, guardianHash2);

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
        socialRecoveryModule.updatePendingGuardians(guardians2, threshold2, guardianHash2);
    }

    function testRevertsUpdateGuardiansIfOnchainGuardianConfigError() public {
        guardians2[0] = guardian2_1;
        guardians2[1] = guardian2_2;
        guardians2[2] = guardian2_3;
        threshold2 = 2;
        guardianHash2 = bytes32(keccak256(abi.encodePacked(guardian2_1)));

        vm.prank(address(wallet));
        vm.expectRevert(ISocialRecoveryModule.SocialRecovery__OnchainGuardianConfigError.selector);
        socialRecoveryModule.updatePendingGuardians(guardians2, threshold2, guardianHash2);
    }

    function testRevertsUpdateGuardiansWhenInvalidThreshold() public {
        guardians2[0] = guardian2_1;
        guardians2[1] = guardian2_2;
        guardians2[2] = guardian2_3;
        threshold2 = 4;

        vm.prank(address(wallet));
        vm.expectRevert(ISocialRecoveryModule.SocialRecovery__InvalidThreshold.selector);
        socialRecoveryModule.updatePendingGuardians(guardians2, threshold2, guardianHash2);

        vm.prank(address(wallet));
        vm.expectRevert(ISocialRecoveryModule.SocialRecovery__InvalidThreshold.selector);
        socialRecoveryModule.updatePendingGuardians(guardians2, 0, guardianHash2);

        guardianHash2 = bytes32(keccak256(abi.encodePacked(guardian2_1)));
        vm.prank(address(wallet));
        vm.expectRevert(ISocialRecoveryModule.SocialRecovery__InvalidThreshold.selector);
        socialRecoveryModule.updatePendingGuardians(new address[](1), 0, guardianHash2);
    }

    function testCanReUpdateGuardians() public {
        testUpdatePendingGuardians();
        (uint256 pendingUntil, uint256 pendingThreshold, bytes32 pendingGuardianHash, address[] memory guardiansUpdated)
        = socialRecoveryModule.pendingGuarian(address(wallet));
        assertEq(pendingUntil, block.timestamp + 2 days);
        assertEq(pendingThreshold, threshold2);
        assertEq(bytes32(guardianHash2), bytes32(0));
        assertEq(guardiansUpdated.length, guardians2.length);

        guardians2[0] = address(0);
        uint256 threshold3 = 3;
        bytes32 guardianHash3 = bytes32(keccak256(abi.encodePacked(guardian2_1, guardian2_2, guardian2_3)));

        vm.prank(address(wallet));
        socialRecoveryModule.updatePendingGuardians(new address[](0), threshold3, guardianHash3);

        (pendingUntil, pendingThreshold, pendingGuardianHash, guardiansUpdated) =
            socialRecoveryModule.pendingGuarian(address(wallet));

        assertEq(pendingUntil, block.timestamp + 2 days);
        assertEq(pendingThreshold, threshold3);
        assertEq(bytes32(pendingGuardianHash), bytes32(guardianHash3));
        assertEq(guardiansUpdated.length, 0);
    }

    ///////////////////////////////////
    // processGuardianUpdates Tests  //
    ///////////////////////////////////

    function testProcessGuardianUpdates() public {
        testUpdatePendingGuardians();
        (uint256 pendingUntil, uint256 pendingThreshold, bytes32 pendingGuardianHash, address[] memory guardiansUpdated)
        = socialRecoveryModule.pendingGuarian(address(wallet));

        assertEq(pendingUntil, block.timestamp + 2 days);
        assertEq(pendingThreshold, threshold2);
        assertEq(bytes32(pendingGuardianHash), bytes32(guardianHash2));
        assertEq(guardiansUpdated.length, guardians2.length);

        assertEq(socialRecoveryModule.guardiansCount(address(wallet)), 3);
        assertEq(socialRecoveryModule.threshold(address(wallet)), 2);

        vm.prank(address(wallet));
        socialRecoveryModule.processGuardianUpdates(address(wallet));

        assertEq(socialRecoveryModule.guardiansCount(address(wallet)), 1);
        assertEq(socialRecoveryModule.threshold(address(wallet)), pendingThreshold);
        assertEq(socialRecoveryModule.getGuardiansHash(address(wallet)), bytes32(pendingGuardianHash));
    }

    function testRevertsProcessGuardianUpdates() public {
        testUpdatePendingGuardians();
        vm.prank(address(guardian1));
        vm.expectRevert();
        socialRecoveryModule.processGuardianUpdates(address(wallet));
    }

    ///////////////////////////////////
    //   cancelSetGuardians Tests    //
    ///////////////////////////////////

    function testCancelSetGuardiansByOwnerViaWallet() public {
        testUpdatePendingGuardians();
        vm.prank(address(wallet));
        socialRecoveryModule.cancelSetGuardians(address(wallet));

        (uint256 pendingUntil, uint256 pendingThreshold, bytes32 pendingGuardianHash, address[] memory guardiansUpdated)
        = socialRecoveryModule.pendingGuarian(address(wallet));

        assertEq(pendingUntil, 0);
        assertEq(pendingThreshold, 0);
        assertEq(bytes32(pendingGuardianHash), 0);
        assertEq(guardiansUpdated.length, 0);
    }

    function testCancelSetGuardiansByGuardian() public {
        testUpdatePendingGuardians();
        vm.prank(address(guardian1));
        socialRecoveryModule.cancelSetGuardians(address(wallet));

        (uint256 pendingUntil, uint256 pendingThreshold, bytes32 pendingGuardianHash, address[] memory guardiansUpdated)
        = socialRecoveryModule.pendingGuarian(address(wallet));

        assertEq(pendingUntil, 0);
        assertEq(pendingThreshold, 0);
        assertEq(bytes32(pendingGuardianHash), 0);
        assertEq(guardiansUpdated.length, 0);
    }

    function testRevertsCancelSetGuardiansIfUnauthorized() public {
        testUpdatePendingGuardians();
        vm.prank(address(guardian2_1));
        vm.expectRevert(ISocialRecoveryModule.SocialRecovery__Unauthorized.selector);
        socialRecoveryModule.cancelSetGuardians(address(wallet));

        (uint256 pendingUntil, uint256 pendingThreshold, bytes32 pendingGuardianHash, address[] memory guardiansUpdated)
        = socialRecoveryModule.pendingGuarian(address(wallet));

        assertEq(pendingUntil, block.timestamp + 2 days);
        assertEq(pendingThreshold, threshold2);
        assertEq(bytes32(pendingGuardianHash), bytes32(guardianHash2));
        assertEq(guardiansUpdated.length, guardians2.length);
    }

    function testRevertsCancelSetGuardiansWhenNoPendingGuardian() public {
        vm.prank(address(wallet));
        vm.expectRevert(ISocialRecoveryModule.SocialRecovery__NoPendingGuardian.selector);
        socialRecoveryModule.cancelSetGuardians(address(wallet));

        (uint256 pendingUntil, uint256 pendingThreshold, bytes32 pendingGuardianHash, address[] memory guardiansUpdated)
        = socialRecoveryModule.pendingGuarian(address(wallet));

        assertEq(pendingUntil, 0);
        assertEq(pendingThreshold, 0);
        assertEq(bytes32(pendingGuardianHash), 0);
        assertEq(guardiansUpdated.length, 0);
    }

    ////////////////////////////////////
    // revealAnonymousGuardians Tests //
    ////////////////////////////////////

    event AnonymousGuardianRevealed(address indexed wallet, address[] indexed guardians, bytes32 guardianHash);

    function testRevealAnonymousGuardians() public {
        testCanInitWithAnonymousGuardians();
        assertEq(socialRecoveryModule2.guardiansCount(address(wallet2)), 0);
        assertEq(socialRecoveryModule2.threshold(address(wallet2)), 2);

        threshold = 2;
        uint256 salt = 42;
        bytes32 anonymousGuardianHashed = bytes32(keccak256(abi.encodePacked(guardians, salt)));
        assertEq(socialRecoveryModule2.getGuardiansHash(address(wallet2)), anonymousGuardianHashed);
        assertEq(socialRecoveryModule2.getAnonymousGuardianHash(guardians, salt), anonymousGuardianHashed);

        vm.prank(address(wallet2));
        vm.expectEmit(true, true, true, true);
        emit AnonymousGuardianRevealed(address(wallet2), guardians, anonymousGuardianHashed);
        socialRecoveryModule2.revealAnonymousGuardians(address(wallet2), guardians, salt);

        assertEq(socialRecoveryModule2.guardiansCount(address(wallet2)), 3);
        assertEq(socialRecoveryModule2.getGuardiansHash(address(wallet2)), bytes32(0));
    }

    function testRevertsRevealAnonymousGuardiansIfNotAuthorized() public {
        testCanInitWithAnonymousGuardians();
        assertEq(socialRecoveryModule2.guardiansCount(address(wallet2)), 0);
        assertEq(socialRecoveryModule2.threshold(address(wallet2)), 2);

        uint256 salt = 42;
        bytes32 anonymousGuardianHashed = bytes32(keccak256(abi.encodePacked(guardians, salt)));
        assertEq(socialRecoveryModule2.getGuardiansHash(address(wallet2)), anonymousGuardianHashed);

        vm.prank(address(guardian1));
        vm.expectRevert(ISocialRecoveryModule.SocialRecovery__Unauthorized.selector);
        socialRecoveryModule2.revealAnonymousGuardians(address(wallet2), new address[](1), salt);
    }

    function testRevertsRevealAnonymousGuardiansIfGuardianListError() public {
        testCanInitWithAnonymousGuardians();
        assertEq(socialRecoveryModule2.guardiansCount(address(wallet2)), 0);
        assertEq(socialRecoveryModule2.threshold(address(wallet2)), 2);

        uint256 salt = 42;
        bytes32 anonymousGuardianHashed = bytes32(keccak256(abi.encodePacked(guardians, salt)));
        assertEq(socialRecoveryModule2.getGuardiansHash(address(wallet2)), anonymousGuardianHashed);

        vm.prank(address(wallet2));
        vm.expectRevert(ISocialRecoveryModule.SocialRecovery__InvalidGuardianList.selector);
        socialRecoveryModule2.revealAnonymousGuardians(address(wallet2), new address[](1), salt);
    }

    function testRevertsRevealAnonymousGuardiansIfGuardianHashError() public {
        testCanInitWithAnonymousGuardians();
        assertEq(socialRecoveryModule2.guardiansCount(address(wallet2)), 0);
        assertEq(socialRecoveryModule2.threshold(address(wallet2)), 2);

        uint256 notValitSalt = 24;
        vm.prank(address(wallet2));
        vm.expectRevert(ISocialRecoveryModule.SocialRecovery__InvalidGuardianHash.selector);
        socialRecoveryModule2.revealAnonymousGuardians(address(wallet2), guardians, notValitSalt);
    }

    // helper
    function createWalletWithoutSocialRecovery() public returns (TrueWallet) {
        TrueWallet walletNoRecoveryModule;
        bytes[] memory initModule = new bytes[](1);
        controlModuleInitData = 1;
        bytes memory securityControlModuleInitData = abi.encode(uint32(controlModuleInitData));
        initModule[0] = abi.encodePacked(address(securityControlModule), securityControlModuleInitData);
        bytes memory data =
            abi.encodeCall(TrueWallet.initialize, (address(entryPoint), address(walletOwner), initModule));
        proxy = new TrueWalletProxy(address(walletImpl), data);
        walletNoRecoveryModule = TrueWallet(payable(address(proxy)));
        return walletNoRecoveryModule;
    }

    ///////////////////////////////////
    //     approveRecovery Tests     //
    ///////////////////////////////////

    event ApproveRecovery(address indexed wallet, address indexed guardian, bytes32 indexed recoveryHash);

    address newOwner1 = makeAddr("newOwner1");
    address[] newOwners = new address[](1);

    function testApproveRecovery() public {
        newOwners[0] = newOwner1;

        RecoveryEntry memory request = socialRecoveryModule.getRecoveryEntry(address(wallet));
        assertEq(request.newOwners.length, 0);
        assertEq(request.executeAfter, 0);
        assertEq(request.nonce, 0);

        assertEq(socialRecoveryModule.nonce(address(wallet)), 0);
        assertEq(socialRecoveryModule.getRecoveryApprovals(address(wallet), newOwners), 0);
        assertEq(socialRecoveryModule.hasGuardianApproved(guardian1, address(wallet), newOwners), 0);

        uint256 nonce = socialRecoveryModule.nonce(address(wallet));
        bytes32 recoveryHash = socialRecoveryModule.getSocialRecoveryHash(address(wallet), newOwners, nonce);

        vm.prank(address(guardian1));
        vm.expectEmit(true, true, true, true);
        emit ApproveRecovery(address(wallet), address(guardian1), recoveryHash);
        socialRecoveryModule.approveRecovery(address(wallet), newOwners);

        request = socialRecoveryModule.getRecoveryEntry(address(wallet));
        assertEq(request.newOwners.length, newOwners.length);
        assertEq(request.executeAfter, block.timestamp + 2 days);
        assertEq(request.nonce, IWallet(wallet).nonce());

        // assertEq(socialRecoveryModule.nonce(address(wallet)), 1); should be updated after _executeRecovery
        assertEq(socialRecoveryModule.getRecoveryApprovals(address(wallet), newOwners), 1);
        assertEq(socialRecoveryModule.hasGuardianApproved(address(guardian1), address(wallet), newOwners), 1);
    }

    function testRevertsApproveRecoveryIfUnauthorized() public {
        newOwners[0] = newOwner1;
        vm.prank(address(adminAddress));
        vm.expectRevert(ISocialRecoveryModule.SocialRecovery__Unauthorized.selector);
        socialRecoveryModule.approveRecovery(address(wallet), newOwners);
    }

    function testRevertsApproveRecoveryIfOwnersEmpty() public {
        newOwners[0] = newOwner1;
        vm.prank(address(guardian1));
        vm.expectRevert(ISocialRecoveryModule.SocialRecovery__OwnersEmpty.selector);
        socialRecoveryModule.approveRecovery(address(wallet), new address[](0));
    }

    function testRevertsApproveRecoveryIfUnauthorizedWallet() public {
        TrueWallet walletNoRecoveryModule = createWalletWithoutSocialRecovery();
        newOwners[0] = newOwner1;
        vm.prank(address(walletNoRecoveryModule));
        vm.expectRevert(ISocialRecoveryModule.SocialRecovery__Unauthorized.selector);
        socialRecoveryModule.approveRecovery(address(walletNoRecoveryModule), newOwners);
    }

    function testRevertsApproveRecoveryWhenUnrevealedAnonymosGuardians() public {
        testCanInitWithAnonymousGuardians();
        newOwners[0] = newOwner1;
        vm.prank(address(guardian1));
        vm.expectRevert(ISocialRecoveryModule.SocialRecovery__Unauthorized.selector);
        socialRecoveryModule2.approveRecovery(address(wallet), newOwners);
    }

    ////////////////////////////////////
    //      executeRecovery Tests     //
    ////////////////////////////////////

    event SocialRecoveryExecuted(address indexed wallet, address[] indexed newOwners);

    function testExecuteRecoveryWithOnchainGuardians() public {
        assertTrue(wallet.isOwner(walletOwner));
        assertEq(socialRecoveryModule.guardiansCount(address(wallet)), 3);
        assertEq(socialRecoveryModule.threshold(address(wallet)), 2);

        RecoveryEntry memory request = socialRecoveryModule.getRecoveryEntry(address(wallet));
        assertEq(request.newOwners.length, 0);
        assertEq(request.executeAfter, 0);
        assertEq(request.nonce, 0);

        testApproveRecovery();
        request = socialRecoveryModule.getRecoveryEntry(address(wallet));
        assertEq(request.newOwners.length, newOwners.length);
        assertEq(request.executeAfter, block.timestamp + 2 days);
        assertEq(request.nonce, IWallet(wallet).nonce());

        request = socialRecoveryModule.getRecoveryEntry(address(wallet));
        // uint256 recoveryNonce = request.nonce;
        // bytes32 recoveryHash = socialRecoveryModule.getSocialRecoveryHash(address(wallet), newOwners, recoveryNonce);

        vm.prank(address(guardian2));
        socialRecoveryModule.approveRecovery(address(wallet), newOwners);

        assertEq(socialRecoveryModule.getRecoveryApprovals(address(wallet), newOwners), 2);
        assertEq(socialRecoveryModule.hasGuardianApproved(address(guardian2), address(wallet), newOwners), 1);

        uint256 executeAfter = request.executeAfter;
        vm.warp(executeAfter);

        vm.prank(address(guardian3));
        vm.expectEmit(true, true, true, true);
        emit SocialRecoveryExecuted(address(wallet), newOwners);
        socialRecoveryModule.executeRecovery(address(wallet));

        assertTrue(wallet.isOwner(newOwner1));

        request = socialRecoveryModule.getRecoveryEntry(address(wallet));
        assertEq(request.newOwners.length, 0);
        assertEq(request.executeAfter, 0);
        assertEq(request.nonce, 0);
    }

    function testRevertsExecuteRecoveryWithOnchainGuardians() public {
        assertTrue(wallet.isOwner(walletOwner));
        assertEq(socialRecoveryModule.guardiansCount(address(wallet)), 3);
        assertEq(socialRecoveryModule.threshold(address(wallet)), 2);

        RecoveryEntry memory request = socialRecoveryModule.getRecoveryEntry(address(wallet));
        assertEq(request.newOwners.length, 0);
        assertEq(request.executeAfter, 0);
        assertEq(request.nonce, 0);

        testApproveRecovery();
        request = socialRecoveryModule.getRecoveryEntry(address(wallet));
        assertEq(request.newOwners.length, newOwners.length);
        assertEq(request.executeAfter, block.timestamp + 2 days);
        assertEq(request.nonce, IWallet(wallet).nonce());

        vm.prank(address(guardian3));
        vm.expectRevert(ISocialRecoveryModule.SocialRecovery__RecoveryPeriodStillPending.selector);
        socialRecoveryModule.executeRecovery(address(wallet));

        uint256 executeAfter = request.executeAfter;
        vm.warp(executeAfter);

        vm.prank(address(guardian1));
        vm.expectRevert(ISocialRecoveryModule.SocialRecovery__NotEnoughApprovals.selector);
        socialRecoveryModule.executeRecovery(address(wallet));

        request = socialRecoveryModule.getRecoveryEntry(address(wallet));
        assertEq(request.newOwners.length, newOwners.length);
        assertEq(request.executeAfter, executeAfter);
        assertEq(request.nonce, IWallet(wallet).nonce());

        assertTrue(wallet.isOwner(walletOwner));
    }

    function testRevertsExecuteRecoveryWhenNotRevealedAnonymousGuardians() public {
        testCanInitWithAnonymousGuardians();
        vm.prank(address(guardian1));
        vm.expectRevert(ISocialRecoveryModule.SocialRecovery__NoOngoingRecovery.selector);
        socialRecoveryModule.executeRecovery(address(wallet));
    }

    ////////////////////////////////////
    //      cancelRecovery Tests      //
    ////////////////////////////////////

    event SocialRecoveryCanceled(address indexed wallet, uint256 nonce);

    function testCancelRecovery() public {
        testApproveRecovery();
        RecoveryEntry memory request = socialRecoveryModule.getRecoveryEntry(address(wallet));
        assertEq(request.newOwners.length, newOwners.length);
        assertEq(request.executeAfter, block.timestamp + 2 days);
        assertEq(request.nonce, IWallet(wallet).nonce());

        vm.prank(address(wallet));
        vm.expectEmit(true, true, true, true);
        emit SocialRecoveryCanceled(address(wallet), request.nonce);
        socialRecoveryModule.cancelRecovery(address(wallet));

        request = socialRecoveryModule.getRecoveryEntry(address(wallet));
        assertEq(request.newOwners.length, 0);
        assertEq(request.executeAfter, 0);
        assertEq(request.nonce, 0);
    }

    function testRevertsCancelRecovery() public {
        TrueWallet walletNoRecoveryModule = createWalletWithoutSocialRecovery();
        vm.prank(address(guardian1));
        vm.expectRevert(ISocialRecoveryModule.SocialRecovery__Unauthorized.selector);
        socialRecoveryModule.cancelRecovery(address(walletNoRecoveryModule));

        vm.prank(address(guardian1));
        vm.expectRevert(ISocialRecoveryModule.SocialRecovery__NoOngoingRecovery.selector);
        socialRecoveryModule.cancelRecovery(address(wallet));

        testApproveRecovery();
        RecoveryEntry memory request = socialRecoveryModule.getRecoveryEntry(address(wallet));
        assertEq(request.newOwners.length, newOwners.length);
        assertEq(request.executeAfter, block.timestamp + 2 days);
        assertEq(request.nonce, IWallet(wallet).nonce());

        vm.prank(address(guardian1));
        vm.expectRevert(ISocialRecoveryModule.SocialRecovery__OnlyWalletItselfCanCancelRecovery.selector);
        socialRecoveryModule.cancelRecovery(address(wallet));

        vm.prank(address(walletOwner));
        vm.expectRevert(ISocialRecoveryModule.SocialRecovery__OnlyWalletItselfCanCancelRecovery.selector);
        socialRecoveryModule.cancelRecovery(address(wallet));

        request = socialRecoveryModule.getRecoveryEntry(address(wallet));
        assertEq(request.newOwners.length, newOwners.length);
        assertEq(request.executeAfter, block.timestamp + 2 days);
        assertEq(request.nonce, IWallet(wallet).nonce());
    }

    ////////////////////////////////////
    //   batchApproveRecovery Tests   //
    ////////////////////////////////////

    // If (numConfirmed < threshold) => pending recovery
    function testBatchApproveRecoveryWhenNumConfirmedLowerThreshold() public {
        assertTrue(wallet.isOwner(walletOwner));
        assertEq(socialRecoveryModule.threshold(address(wallet)), 2);
        assertEq(socialRecoveryModule.guardiansCount(address(wallet)), 3);
        assertTrue(socialRecoveryModule.isGuardian(address(wallet), guardian1));
        assertTrue(socialRecoveryModule.isGuardian(address(wallet), guardian2));
        assertTrue(socialRecoveryModule.isGuardian(address(wallet), guardian3));

        RecoveryEntry memory request = socialRecoveryModule.getRecoveryEntry(address(wallet));
        assertEq(request.newOwners.length, 0);
        assertEq(request.executeAfter, 0);
        assertEq(request.nonce, 0);

        newOwners[0] = newOwner1;
        uint256 nonce = socialRecoveryModule.nonce(address(wallet));
        bytes32 recoveryHash = socialRecoveryModule.getSocialRecoveryHash(address(wallet), newOwners, nonce);

        bytes memory sign1 = createSignature3(recoveryHash, guardian1PrivateKey, vm);
        uint256 signatureCount = 1;

        vm.prank(address(guardian1));
        socialRecoveryModule.batchApproveRecovery(address(wallet), newOwners, signatureCount, sign1);

        request = socialRecoveryModule.getRecoveryEntry(address(wallet));
        assertEq(request.newOwners.length, newOwners.length);
        assertEq(request.executeAfter, block.timestamp + 2 days);
        assertEq(request.nonce, IWallet(wallet).nonce());

        assertTrue(wallet.isOwner(walletOwner));
    }

    // If (numConfirmed == numGuardian) => execute recovery
    function testBatchApproveRecoveryWhenExactMatchOfNumConfirmedAndThreshold() public {
        assertTrue(wallet.isOwner(walletOwner));
        assertEq(socialRecoveryModule.threshold(address(wallet)), 2);
        assertEq(socialRecoveryModule.guardiansCount(address(wallet)), 3);
        assertTrue(socialRecoveryModule.isGuardian(address(wallet), guardian1));
        assertTrue(socialRecoveryModule.isGuardian(address(wallet), guardian2));
        assertTrue(socialRecoveryModule.isGuardian(address(wallet), guardian3));

        RecoveryEntry memory request = socialRecoveryModule.getRecoveryEntry(address(wallet));
        assertEq(request.newOwners.length, 0);
        assertEq(request.executeAfter, 0);
        assertEq(request.nonce, 0);

        newOwners[0] = newOwner1;
        uint256 nonce = socialRecoveryModule.nonce(address(wallet));
        bytes32 recoveryHash = socialRecoveryModule.getSocialRecoveryHash(address(wallet), newOwners, nonce);

        bytes memory sign1 = createSignature3(recoveryHash, guardian1PrivateKey, vm);
        bytes memory sign2 = createSignature3(recoveryHash, guardian2PrivateKey, vm);
        bytes memory sign3 = createSignature3(recoveryHash, guardian3PrivateKey, vm);
        bytes memory signatures = abi.encodePacked(sign1, sign2, sign3);
        uint256 signatureCount = 3;

        vm.prank(address(guardian1));
        vm.expectEmit(true, true, true, true);
        emit SocialRecoveryExecuted(address(wallet), newOwners);
        socialRecoveryModule.batchApproveRecovery(address(wallet), newOwners, signatureCount, signatures);

        request = socialRecoveryModule.getRecoveryEntry(address(wallet));
        assertEq(request.newOwners.length, 0);
        assertEq(request.executeAfter, 0);
        assertEq(request.nonce, 0);

        assertTrue(wallet.isOwner(newOwner1));
        assertEq(socialRecoveryModule.getRecoveryApprovals(address(wallet), newOwners), 3);
    }

    // separate set up
    address[] guardians3 = new address[](5);
    address guardian3_1;
    uint256 guardian3_1PrivateKey;
    address guardian3_2;
    uint256 guardian3_2PrivateKey;
    address guardian3_3;
    uint256 guardian3_3PrivateKey;
    address guardian3_4;
    uint256 guardian3_4PrivateKey;
    address guardian3_5;
    uint256 guardian3_5PrivateKey;

    event Log(address[] arr);
    event PendingRecovery(address indexed wallet, address[] indexed newOwners, uint256 nonce, uint256 executeAfter);
    event BatchApproveRecovery(
        address indexed wallet,
        address[] indexed newOwners,
        uint256 signatureCount,
        bytes signatures,
        bytes32 indexed recoveryHash
    );

    // helper for batch approve recovery test
    function sortAddresses(address[] memory arr) internal pure returns (address[] memory) {
        for (uint256 i = 1; i < arr.length; i++) {
            address key = arr[i];
            uint256 j = i;
            while (j > 0 && arr[j - 1] > key) {
                arr[j] = arr[j - 1];
                j--;
            }
            arr[j] = key;
        }
        return arr;
    }

    // If (_signatureCount > threshold) => pending recovery
    function testBatchApproveRecoveryWhenNumConfirmedHigherThreshold() public {
        assertTrue(wallet.isOwner(walletOwner));
        assertEq(socialRecoveryModule.threshold(address(wallet)), 2);
        assertEq(socialRecoveryModule.guardiansCount(address(wallet)), 3);
        assertTrue(socialRecoveryModule.isGuardian(address(wallet), guardian1));
        assertTrue(socialRecoveryModule.isGuardian(address(wallet), guardian2));
        assertTrue(socialRecoveryModule.isGuardian(address(wallet), guardian3));

        (guardian3_1, guardian3_1PrivateKey) = makeAddrAndKey("guardian3_1");
        (guardian3_2, guardian3_2PrivateKey) = makeAddrAndKey("guardian3_2");
        (guardian3_3, guardian3_3PrivateKey) = makeAddrAndKey("guardian3_3");
        (guardian3_4, guardian3_4PrivateKey) = makeAddrAndKey("guardian3_4");
        (guardian3_5, guardian3_5PrivateKey) = makeAddrAndKey("guardian3_5");
        threshold = 3;
        guardianHash = bytes32(0);

        guardians3[0] = guardian3_1;
        guardians3[1] = guardian3_2;
        guardians3[2] = guardian3_3;
        guardians3[3] = guardian3_4;
        guardians3[4] = guardian3_5;

        vm.prank(address(wallet));
        socialRecoveryModule.updatePendingGuardians(guardians3, threshold, guardianHash);

        (uint256 pendingUntil, uint256 pendingThreshold, bytes32 pendingGuardianHash, address[] memory guardiansUpdated)
        = socialRecoveryModule.pendingGuarian(address(wallet));

        assertEq(pendingUntil, block.timestamp + 2 days);
        assertEq(pendingThreshold, threshold);
        assertEq(bytes32(pendingGuardianHash), bytes32(guardianHash));
        assertEq(guardiansUpdated.length, guardians3.length);

        RecoveryEntry memory request = socialRecoveryModule.getRecoveryEntry(address(wallet));
        assertEq(request.newOwners.length, 0);
        assertEq(request.executeAfter, 0);
        assertEq(request.nonce, 0);

        vm.warp(pendingUntil - 1 hours);
        vm.prank(address(wallet));
        socialRecoveryModule.processGuardianUpdates(address(wallet));
        assertEq(socialRecoveryModule.guardiansCount(address(wallet)), 5);

        assertEq(socialRecoveryModule.threshold(address(wallet)), 3);
        assertEq(socialRecoveryModule.guardiansCount(address(wallet)), 5);
        assertTrue(socialRecoveryModule.isGuardian(address(wallet), guardian3_1));
        assertTrue(socialRecoveryModule.isGuardian(address(wallet), guardian3_2));
        assertTrue(socialRecoveryModule.isGuardian(address(wallet), guardian3_3));
        assertTrue(socialRecoveryModule.isGuardian(address(wallet), guardian3_4));
        assertTrue(socialRecoveryModule.isGuardian(address(wallet), guardian3_5));

        newOwners[0] = newOwner1;
        uint256 nonce = socialRecoveryModule.nonce(address(wallet));
        bytes32 recoveryHash = socialRecoveryModule.getSocialRecoveryHash(address(wallet), newOwners, nonce);

        bytes memory sign1 = createSignature3(recoveryHash, guardian3_1PrivateKey, vm);
        bytes memory sign2 = createSignature3(recoveryHash, guardian3_2PrivateKey, vm);
        bytes memory sign3 = createSignature3(recoveryHash, guardian3_3PrivateKey, vm);
        bytes memory sign4 = createSignature3(recoveryHash, guardian3_4PrivateKey, vm);

        // rearrange signatures based on the sorted addresses - sortedGuardianArray
        bytes memory signatures = abi.encodePacked(sign4, sign3, sign2, sign1);
        uint256 signatureCount = 4;

        // reduce the length of the guardian list
        address[] memory batchGuardianArray = new address[](4);
        for (uint256 i; i < guardians3.length - 1;) {
            batchGuardianArray[i] = guardians3[i];
            unchecked {
                i++;
            }
        }

        // sorting guardian addresses
        address[] memory sortedGuardianArray = new address[](4);
        sortedGuardianArray = sortAddresses(batchGuardianArray);
        emit Log(sortedGuardianArray);

        vm.prank(address(guardian1));
        vm.expectEmit(true, true, true, true);
        emit PendingRecovery(address(wallet), newOwners, 0, block.timestamp + 2 days);
        emit BatchApproveRecovery(address(wallet), newOwners, signatureCount, signatures, recoveryHash);
        socialRecoveryModule.batchApproveRecovery(address(wallet), newOwners, signatureCount, signatures);

        request = socialRecoveryModule.getRecoveryEntry(address(wallet));
        assertEq(request.newOwners.length, newOwners.length);
        assertEq(request.executeAfter, block.timestamp + 2 days);
        assertEq(request.nonce, IWallet(wallet).nonce());

        assertTrue(wallet.isOwner(walletOwner));
        assertEq(socialRecoveryModule.getRecoveryApprovals(address(wallet), newOwners), 4);
        assertEq(socialRecoveryModule.hasGuardianApproved(guardian3_1, address(wallet), newOwners), 1);
        assertEq(socialRecoveryModule.hasGuardianApproved(guardian3_2, address(wallet), newOwners), 1);
        assertEq(socialRecoveryModule.hasGuardianApproved(guardian3_3, address(wallet), newOwners), 1);
        assertEq(socialRecoveryModule.hasGuardianApproved(guardian3_4, address(wallet), newOwners), 1);
        assertEq(socialRecoveryModule.hasGuardianApproved(guardian3_5, address(wallet), newOwners), 0);
    }

    function testRevertsBatchApproveRecoveryIfAnonymousGuardianNotRevealed() public {
        testCanInitWithAnonymousGuardians();
        assertEq(socialRecoveryModule2.guardiansCount(address(wallet2)), 0);

        newOwners[0] = newOwner1;
        uint256 nonce = socialRecoveryModule2.nonce(address(wallet2));
        bytes32 recoveryHash = socialRecoveryModule2.getSocialRecoveryHash(address(wallet2), newOwners, nonce);

        bytes memory sign1 = createSignature3(recoveryHash, guardian1PrivateKey, vm);
        uint256 signatureCount = 1;

        vm.prank(address(guardian1));
        vm.expectRevert(ISocialRecoveryModule.SocialRecovery__AnonymousGuardianNotRevealed.selector);
        socialRecoveryModule2.batchApproveRecovery(address(wallet2), newOwners, signatureCount, sign1);
    }

    function testRevertsBatchRecoveryIfOwnersEmpty() public {
        newOwners[0] = newOwner1;
        uint256 nonce = socialRecoveryModule.nonce(address(wallet));
        bytes32 recoveryHash = socialRecoveryModule.getSocialRecoveryHash(address(wallet), newOwners, nonce);

        bytes memory sign1 = createSignature3(recoveryHash, guardian1PrivateKey, vm);
        uint256 signatureCount = 1;

        vm.prank(address(guardian1));
        vm.expectRevert(ISocialRecoveryModule.SocialRecovery__OwnersEmpty.selector);
        socialRecoveryModule.batchApproveRecovery(address(wallet), new address[](0), signatureCount, sign1);
    }

    function testRevertsBatchRecoveryWhenUnauthorizedWallet() public {
        TrueWallet walletNoRecoveryModule = createWalletWithoutSocialRecovery();
        newOwners[0] = newOwner1;
        uint256 nonce = socialRecoveryModule.nonce(address(walletNoRecoveryModule));
        bytes32 recoveryHash =
            socialRecoveryModule.getSocialRecoveryHash(address(walletNoRecoveryModule), newOwners, nonce);

        bytes memory sign1 = createSignature3(recoveryHash, guardian1PrivateKey, vm);
        uint256 signatureCount = 1;

        vm.prank(address(guardian1));
        vm.expectRevert(ISocialRecoveryModule.SocialRecovery__Unauthorized.selector);
        socialRecoveryModule.batchApproveRecovery(address(walletNoRecoveryModule), newOwners, signatureCount, sign1);
    }

    ////////////////////////////////////
    //          deInit Tests          //
    ////////////////////////////////////

    function testDeInitWalletFromSocialRecoveryModule() public {
        assertEq(socialRecoveryModule.guardiansCount(address(wallet)), 3);
        assertEq(socialRecoveryModule.getGuardiansHash(address(wallet)), bytes32(0));
        assertEq(socialRecoveryModule.threshold(address(wallet)), 2);

        assertTrue(wallet.isAuthorizedModule(address(socialRecoveryModule)));
        assertTrue(socialRecoveryModule.isInit(address(wallet)));
        (address[] memory _modules,) = wallet.listModules();
        assertEq(_modules.length, 2);

        bytes memory data =
            abi.encodeWithSelector(bytes4(keccak256("removeModule(address)")), address(socialRecoveryModule));

        vm.prank(address(wallet));
        securityControlModule.execute(address(wallet), data);

        (_modules,) = wallet.listModules();
        assertEq(_modules.length, 1);
        assertFalse(wallet.isAuthorizedModule(address(socialRecoveryModule)));
        assertFalse(socialRecoveryModule.isInit(address(wallet)));
        assertEq(socialRecoveryModule.threshold(address(wallet)), 0);

        /// delete walletGuardian[_sender]; will reset the threshold and guardianHash to their default values because they are not mappings.
        /// This is why you see the threshold being reset to 0.
        /// However, for the guardians mapping within the struct, delete only resets the state of the value types and does not iterate over the keys of the mapping to delete them.
        /// This is why the list of guardians remains.
        // assertEq(socialRecoveryModule.guardiansCount(address(wallet)), 0);
        // assertEq(socialRecoveryModule.getGuardiansHash(address(wallet)), bytes32(0));
    }

    function testRevertsDeInitWalletFromSocialRecoveryModuleWhenInvalidOwner() public {
        assertEq(socialRecoveryModule.guardiansCount(address(wallet)), 3);
        assertEq(socialRecoveryModule.getGuardiansHash(address(wallet)), bytes32(0));
        assertEq(socialRecoveryModule.threshold(address(wallet)), 2);

        assertTrue(wallet.isAuthorizedModule(address(socialRecoveryModule)));
        assertTrue(socialRecoveryModule.isInit(address(wallet)));
        (address[] memory _modules,) = wallet.listModules();
        assertEq(_modules.length, 2);

        bytes memory data =
            abi.encodeWithSelector(bytes4(keccak256("removeModule(address)")), address(socialRecoveryModule));

        vm.prank(address(guardian1));
        vm.expectRevert(); // ISecurityControlModule.SecurityControlModule__InvalidOwner.selector
        securityControlModule.execute(address(wallet), data);

        (_modules,) = wallet.listModules();
        assertEq(_modules.length, 2);
        assertTrue(wallet.isAuthorizedModule(address(socialRecoveryModule)));
        assertTrue(socialRecoveryModule.isInit(address(wallet)));
        assertEq(socialRecoveryModule.threshold(address(wallet)), 2);
    }
}
