// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "forge-std/Script.sol";

import {Deployer} from "src/deployer/Deployer.sol";
import {MumbaiConfig} from "../config/MumbaiConfig.sol";

contract DeployDeployerScript is Script {
    Deployer public deployer;
    address public entryPoint;
    address public walletImplementation;

    address public ownerPublicKey;
    address public deployerPublicKey;
    uint256 public deployerPrivateKey;

    function setUp() public {
        ownerPublicKey = vm.envAddress("OWNER");
        deployerPublicKey = vm.envAddress("DEPLOYER_EOA_PUBLIC_KEY");
        deployerPrivateKey = vm.envUint("DEPLOYER_EOA_PRIVATE_KEY");
    }

    function run() public {
        vm.startBroadcast(deployerPrivateKey);
        deployer = new Deployer(ownerPublicKey);
        vm.stopBroadcast();
    }
}
