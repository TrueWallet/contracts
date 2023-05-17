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

    function testAddGuardianWithThreshold() public {
        address[] memory _guardians = new address[](1);
        _guardians[0] = address(21);
        uint256 _threshold = 1;

        vm.prank(ownerAddress);
        wallet.addGuardianWithThreshold(_guardians, _threshold);

        bool res = wallet.isGuardian(address(21));
        assertTrue(res);
        uint256 guardianThreshold = wallet.threshold();
        assertEq(guardianThreshold, _threshold);
        uint256 guardiansSize = wallet.guardiansCount();
        assertEq(guardiansSize, 1);
    }

    function testExecuteRecovery() public {
        console.log(address(wallet));
        
        address guardian1 = address(21);

        address[] memory guardians = new address[](1);
        guardians[0] = guardian1;
        uint256 threshold = 1;

        vm.prank(ownerAddress);
        wallet.addGuardianWithThreshold(guardians, threshold);

        bool res = wallet.isGuardian(address(guardian1));
        assertTrue(res);

        address newOwner = address(22);

        bytes memory data = abi.encodeWithSignature("transferOwnershipAfterRecovery(address)", newOwner);
        bytes32 dataHash = wallet.getDataHash(data);

        hoax(address(guardian1), 0.5 ether);
        wallet.confirmRecovery(dataHash);

        assertEq(wallet.owner(), address(ownerAddress));

        vm.prank(address(guardian1));
        wallet.executeRecovery(newOwner);

        assertEq(wallet.owner(), address(newOwner));
    }
}