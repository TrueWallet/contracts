// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import {TrueWallet} from "src/wallet/TrueWallet.sol";
import {TrueWalletProxy} from "src/wallet/TrueWalletProxy.sol";
import {UserOperation} from "src/interfaces/UserOperation.sol";
import {EntryPoint} from "src/entrypoint/EntryPoint.sol";
import {MockSignatureChecker} from "../mock/MockSignatureChecker.sol";
import {getUserOperation} from "./Fixtures.sol";
import {createSignature, createSignature2} from "test/utils/createSignature.sol";
import {ECDSA, SignatureChecker} from "openzeppelin-contracts/utils/cryptography/SignatureChecker.sol";
import {MockModule} from "../mock/MockModule.sol";

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

    function testSetupState() public {
        assertEq(wallet.owner(), address(ownerAddress));
        assertEq(address(wallet.entryPoint()), address(entryPoint));
        assertTrue(wallet.isAuthorizedModule(address(module)));

        assertTrue(module.isInit(address(wallet)));
        assertEq(module.requiredFunctions()[0], functionSign);
        assertEq(module.walletInitData(address(wallet)), uint32(walletInitValue));
    }

}