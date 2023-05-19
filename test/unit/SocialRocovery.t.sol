// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "forge-std/Test.sol";

import {TrueWallet} from "src/wallet/TrueWallet.sol";
import {EntryPoint} from "src/entrypoint/EntryPoint.sol";
import {TrueWalletProxy} from "src/wallet/TrueWalletProxy.sol";

contract SocialRecoveryUnitTest is Test {
    TrueWallet wallet;
    TrueWallet walletImpl;
    EntryPoint entryPoint;
    TrueWalletProxy proxy;
    address ownerAddress = 0x14dC79964da2C08b23698B3D3cc7Ca32193d9955; // anvil account (7)
    uint256 ownerPrivateKey =
        uint256(
            0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356
        );

    uint32 upgradeDelay = 172800; // 2 days in seconds

    event GuardianSet(address[] indexed guardians, uint256 threshold);
    event OwnershipRecovered(address indexed sender, address indexed newOwner);
    
    function setUp() public {
        entryPoint = new EntryPoint();
        walletImpl = new TrueWallet();

        bytes memory data = abi.encodeCall(
            TrueWallet.initialize,
            (address(entryPoint), ownerAddress, upgradeDelay)
        );

        proxy = new TrueWalletProxy(address(walletImpl), data);
        wallet = TrueWallet(payable(address(proxy)));
    }

    function encodeError(
        string memory error
    ) internal pure returns (bytes memory encoded) {
        encoded = abi.encodeWithSignature(error);
    }

    function testSetGuardianWithThreshold() public {
        address[] memory guardians = new address[](1);
        guardians[0] = address(21);
        uint256 threshold = 1;

        vm.prank(ownerAddress);
        vm.expectEmit(true, true, false, false);
        emit GuardianSet(guardians, threshold);
        wallet.setGuardianWithThreshold(guardians, threshold);

        bool res = wallet.isGuardian(address(21));
        assertTrue(res);
        uint256 guardianThreshold = wallet.threshold();
        assertEq(guardianThreshold, threshold);
        uint256 guardiansSize = wallet.guardiansCount();
        assertEq(guardiansSize, 1);
    }

    function testSetGuardianWithThresholdNotOwner() public {
        address[] memory guardians = new address[](1);
        guardians[0] = address(21);
        uint256 threshold = 1;

        vm.prank(address(12));
        vm.expectRevert(encodeError("InvalidOwner()"));
        wallet.setGuardianWithThreshold(guardians, threshold);

        bool res = wallet.isGuardian(address(21));
        assertFalse(res);
        uint256 guardianThreshold = wallet.threshold();
        assertEq(guardianThreshold, 0);
        uint256 guardiansSize = wallet.guardiansCount();
        assertEq(guardiansSize, 0);
    }

    function testSetGuardianWithThresholdZeroAddressForGuardian() public {
        address[] memory guardians = new address[](1);
        guardians[0] = address(0);
        uint256 threshold = 1;

        vm.prank(ownerAddress);
        vm.expectRevert(encodeError("ZeroAddressForGuardianProvided()"));
        wallet.setGuardianWithThreshold(guardians, threshold);

        bool res = wallet.isGuardian(address(21));
        assertFalse(res);
        uint256 guardianThreshold = wallet.threshold();
        assertEq(guardianThreshold, 0);
        uint256 guardiansSize = wallet.guardiansCount();
        assertEq(guardiansSize, 0);
    }

    function testSetGuardianWithThresholdDuplicateGuardian() public {
        address[] memory guardians = new address[](2);
        guardians[0] = address(21);
        guardians[1] = address(21);
        uint256 threshold = 1;

        vm.prank(ownerAddress);
        vm.expectRevert(encodeError("DuplicateGuardianProvided()"));
        wallet.setGuardianWithThreshold(guardians, threshold);

        bool res = wallet.isGuardian(address(21));
        assertFalse(res);
        uint256 guardianThreshold = wallet.threshold();
        assertEq(guardianThreshold, 0);
        uint256 guardiansSize = wallet.guardiansCount();
        assertEq(guardiansSize, 0);
    }

    function testSetGuardianWithThresholdInvalidThreshold() public {
        address[] memory guardians = new address[](1);
        guardians[0] = address(21);
        uint256 threshold = 0;

        vm.prank(ownerAddress);
        vm.expectRevert(encodeError("InvalidThreshold()"));
        wallet.setGuardianWithThreshold(guardians, threshold);

        bool res = wallet.isGuardian(address(21));
        assertFalse(res);
        uint256 guardianThreshold = wallet.threshold();
        assertEq(guardianThreshold, 0);
        uint256 guardiansSize = wallet.guardiansCount();
        assertEq(guardiansSize, 0);
    }

    function testSetGuardianWithThresholdInvalidThreshold2() public {
        address[] memory guardians = new address[](1);
        guardians[0] = address(21);
        uint256 threshold = 2;

        vm.prank(ownerAddress);
        vm.expectRevert(encodeError("InvalidThreshold()"));
        wallet.setGuardianWithThreshold(guardians, threshold);

        bool res = wallet.isGuardian(address(21));
        assertFalse(res);
        uint256 guardianThreshold = wallet.threshold();
        assertEq(guardianThreshold, 0);
        uint256 guardiansSize = wallet.guardiansCount();
        assertEq(guardiansSize, 0);
    }

    function testConfirmRecovery() public {
        address guardian1 = address(21);

        address[] memory guardians = new address[](1);
        guardians[0] = guardian1;
        uint256 threshold = 1;

        vm.prank(ownerAddress);
        wallet.setGuardianWithThreshold(guardians, threshold);

        bool res = wallet.isGuardian(address(guardian1));
        assertTrue(res);

        address newOwner = address(22);

        bytes32 recoveryHash = wallet.getRecoveryHash(guardians, newOwner, threshold, wallet.nonce());

        assertFalse(wallet.isExecuted(recoveryHash));

        hoax(address(guardian1), 0.5 ether);
        wallet.confirmRecovery(recoveryHash);
    }

    function testConfirmRecoveryNotGuardian() public {
        address guardian1 = address(21);

        address[] memory guardians = new address[](1);
        guardians[0] = guardian1;
        uint256 threshold = 1;

        vm.prank(ownerAddress);
        wallet.setGuardianWithThreshold(guardians, threshold);

        bool res = wallet.isGuardian(address(guardian1));
        assertTrue(res);

        address newOwner = address(22);

        bytes32 recoveryHash = wallet.getRecoveryHash(guardians, newOwner, threshold, wallet.nonce());

        assertFalse(wallet.isExecuted(recoveryHash));

        hoax(address(newOwner), 0.5 ether);
        vm.expectRevert(encodeError("InvalidGuardian()"));
        wallet.confirmRecovery(recoveryHash);
    }

    function testConfirmRecoveryExecutedHash() public {
        address guardian1 = address(21);

        address[] memory guardians = new address[](1);
        guardians[0] = guardian1;
        uint256 threshold = 1;

        vm.prank(ownerAddress);
        wallet.setGuardianWithThreshold(guardians, threshold);

        bool res = wallet.isGuardian(address(guardian1));
        assertTrue(res);

        address newOwner = address(22);

        bytes32 recoveryHash = wallet.getRecoveryHash(guardians, newOwner, threshold, wallet.nonce());

        assertFalse(wallet.isExecuted(recoveryHash));

        hoax(address(guardian1), 0.5 ether);
        wallet.confirmRecovery(recoveryHash);

        vm.prank(address(guardian1));
        wallet.executeRecovery(newOwner);

        vm.startPrank(address(guardian1));
        vm.expectRevert(encodeError("RecoveryAlreadyExecuted()"));
        wallet.confirmRecovery(recoveryHash);
    }

    function testExecuteRecovery() public {        
        address guardian1 = address(21);

        address[] memory guardians = new address[](1);
        guardians[0] = guardian1;
        uint256 threshold = 1;

        vm.prank(ownerAddress);
        wallet.setGuardianWithThreshold(guardians, threshold);

        bool res = wallet.isGuardian(address(guardian1));
        assertTrue(res);

        address newOwner = address(22);

        bytes32 recoveryHash = wallet.getRecoveryHash(guardians, newOwner, threshold, wallet.nonce());

        hoax(address(guardian1), 0.5 ether);
        wallet.confirmRecovery(recoveryHash);

        assertEq(wallet.owner(), address(ownerAddress));

        vm.prank(address(guardian1));
        wallet.executeRecovery(newOwner);

        assertEq(wallet.owner(), address(newOwner));
    }

    function testExecuteRecoveryWhenIsExecuted() public {        
        address guardian1 = address(21);

        address[] memory guardians = new address[](1);
        guardians[0] = guardian1;
        uint256 threshold = 1;

        vm.prank(ownerAddress);
        wallet.setGuardianWithThreshold(guardians, threshold);

        bool res = wallet.isGuardian(address(guardian1));
        assertTrue(res);

        address newOwner = address(22);

        bytes32 recoveryHash = wallet.getRecoveryHash(guardians, newOwner, threshold, wallet.nonce());

        hoax(address(guardian1), 0.5 ether);
        wallet.confirmRecovery(recoveryHash);

        assertEq(wallet.owner(), address(ownerAddress));

        vm.prank(address(guardian1));
        wallet.executeRecovery(newOwner);

        assertEq(wallet.owner(), address(newOwner));

        bool executed = wallet.isExecuted(recoveryHash);
        assertTrue(executed);

        vm.prank(address(guardian1));
        vm.expectRevert(encodeError("RecoveryAlreadyExecuted()"));
        wallet.executeRecovery(newOwner);

        assertEq(wallet.owner(), address(newOwner));
    }

    function testExecuteRecoveryWhenNotEnoughConfirmations() public {        
        address guardian1 = address(21);

        address[] memory guardians = new address[](1);
        guardians[0] = guardian1;
        uint256 threshold = 1;

        vm.prank(ownerAddress);
        wallet.setGuardianWithThreshold(guardians, threshold);

        bool res = wallet.isGuardian(address(guardian1));
        assertTrue(res);

        address newOwner = address(22);

        bytes32 recoveryHash = wallet.getRecoveryHash(guardians, newOwner, threshold, wallet.nonce());

        vm.prank(address(guardian1));
        vm.expectRevert(encodeError("RecoveryNotEnoughConfirmations()"));
        wallet.executeRecovery(newOwner);

        assertEq(wallet.owner(), address(ownerAddress));
    }
}