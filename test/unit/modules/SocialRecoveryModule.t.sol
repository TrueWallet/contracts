// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import {SocialRecoveryModule} from "src/modules/SocialRecoveryModule/SocialRecoveryModule.sol";
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

    

    // test for _init, updateGuardians, 
    // fn: isGuardian:walletGuardian, threshold:walletGuardian, nonce:walletRecoveryNonce

}