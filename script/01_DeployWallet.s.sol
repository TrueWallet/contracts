// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "forge-std/Script.sol";

import {TrueWallet} from "src/wallet/TrueWallet.sol";
import {MumbaiConfig} from "../config/MumbaiConfig.sol";

contract DeployWalletScript is Script {
    TrueWallet public wallet;
    address public deployerPublicKey;
    uint256 public deployerPrivateKey;

    function setUp() public {
        deployerPublicKey = vm.envAddress("DEPLOYER_EOA_PUBLIC_KEY");
        deployerPrivateKey = vm.envUint("DEPLOYER_EOA_PRIVATE_KEY");
    }

    function run() public {
        vm.startBroadcast(deployerPrivateKey);
        wallet = new TrueWallet();
        vm.stopBroadcast();
    }
}
