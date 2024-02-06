// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";

import {Deployer} from "src/deployer/Deployer.sol";
import {TrueWallet} from "src/wallet/TrueWallet.sol";
import {TrueWalletFactory} from "src/wallet/TrueWalletFactory.sol";
import {TrueContractManager, ITrueContractManager} from "src/registry/TrueContractManager.sol";
import {SecurityControlModule} from "src/modules/SecurityControlModule/SecurityControlModule.sol";
import {SocialRecoveryModule} from "src/modules/SocialRecoveryModule/SocialRecoveryModule.sol";
import {MumbaiConfig} from "../config/MumbaiConfig.sol";
import {SepoliaConfig} from "../config/SepoliaConfig.sol";

/// @title Execute Deployer Script
/// @dev This script demonstrates the process of deploying deterministic contracts across different EVM blockchains.
/// @notice The script uses the Deployer contract to deploy various components of a wallet system, including the wallet factory, contract manager, 
/// security control module, and social recovery module, ensuring the same contract addresses across different chains by using a consistent deployer and salt.
contract ExecuteDeployerScript is Script {
    address public deployer;
    address public entryPoint;
    address public walletImpl;

    address public factory;
    address public contractManager;
    address public securityControlModule;
    address public socialRecoveryModule;

    address public ownerPublicKey;
    uint256 public ownerPrivateKey;
    address public deployerPublicKey;
    uint256 public deployerPrivateKey;

    function setUp() public {
        ownerPublicKey = vm.envAddress("OWNER");
        ownerPrivateKey = vm.envUint("PRIVATE_KEY_TESTNET");
        deployerPublicKey = vm.envAddress("DEPLOYER_EOA_PUBLIC_KEY");
        deployerPrivateKey = vm.envUint("DEPLOYER_EOA_PRIVATE_KEY");

        entryPoint = SepoliaConfig.ENTRY_POINT_V6;
        walletImpl = SepoliaConfig.WALLET_IMPL_1; 
        deployer = SepoliaConfig.DEPLOYER_CONTRACT_1;
        // factory = SepoliaConfig.FACTORY_1;
        // contractManager = SepoliaConfig.CONTRACT_MANAGER_1;
        // socialRecoveryModule = SepoliaConfig.SOCIAL_RECOVERY_MODULE_1;
    }

    function run() public {
        vm.startBroadcast(ownerPrivateKey);
        console2.log("==Deployer Address==  addr=%s", address(deployer));

        deployFactory();
        // deployContractManager();
        // deploySecurityControlModule();
        // deploySocialRecoveryModule();

        vm.stopBroadcast();
    }

    /// @dev Deploys using CREATE2/CREATE3 for deterministic addresses, ensuring the same address across EVM chains.
    // 01_deploy TrueWalletFactory
    function deployFactory() public {
        require(
            address(walletImpl) != address(0) || address(entryPoint) != address(0)
                || address(ownerPublicKey) != address(0),
            "Zero address"
        );

        bytes32 salt =
            keccak256(abi.encodePacked(bytes(_getTrueWalletFactoryCode(walletImpl, ownerPublicKey, entryPoint))));

        address calculateAddress = Deployer(deployer).getContractAddress(salt);
        console2.log("==Calculated Factory==  addr=%s", calculateAddress);

        bytes memory factoryCode = _getTrueWalletFactoryCode(walletImpl, ownerPublicKey, entryPoint);

        factory = Deployer(deployer).deploy(salt, factoryCode);
        console2.log("==Deployed Factory==  addr=%s", factory);

        require(address(calculateAddress) == address(factory), "Not the same address");

        TrueWalletFactory(factory).addStake{value: 0.5 ether}(84600);
    }

    // 02_deploy TrueContractManager
    function deployContractManager() public {
        bytes32 salt = keccak256(abi.encodePacked(bytes(_getTrueContractManagerCode(ownerPublicKey))));
        address calculateAddress = Deployer(deployer).getContractAddress(salt);
        console2.log("==Calculated ContractManager==  addr=%s", calculateAddress);

        bytes memory contractManagerCode = _getTrueContractManagerCode(ownerPublicKey);

        contractManager = Deployer(deployer).deploy(salt, contractManagerCode);
        console2.log("==Deployed ContractManager==  addr=%s", contractManager);

        require(address(calculateAddress) == address(contractManager), "Not the same address");
    }
    
    // 03_deploy SecurityControlModule
    function deploySecurityControlModule() public {
        require(address(contractManager) != address(0), "Zero address");
        bytes32 salt = keccak256(abi.encodePacked(bytes(_getSecurityControlModuleCode(contractManager))));
        address calculateAddress = Deployer(deployer).getContractAddress(salt);
        console2.log("==Calculated SecurityControlModule==  addr=%s", calculateAddress);

        bytes memory securityControlModuleCode = _getSecurityControlModuleCode(address(contractManager));

        securityControlModule = Deployer(deployer).deploy(salt, securityControlModuleCode);
        console2.log("==Deployed SecurityControlModule==  addr=%s", securityControlModule);

        require(address(calculateAddress) == address(securityControlModule), "Not the same address");

        address[] memory modules = new address[](1);
        modules[0] = address(securityControlModule);
        TrueContractManager(contractManager).add(modules);
    }

    // 04_deploy SocialRecoveryModule
    function deploySocialRecoveryModule() public {
        bytes32 salt = keccak256(abi.encodePacked(bytes(_getSocialRecoveryModuleCode())));
        address calculateAddress = Deployer(deployer).getContractAddress(salt);
        console2.log("==Calculated SocialRecoveryModule==  addr=%s", calculateAddress);

        bytes memory socialRecoveryModuleCode = _getSocialRecoveryModuleCode();

        socialRecoveryModule = Deployer(deployer).deploy(salt, socialRecoveryModuleCode);
        console2.log("==Deployed SocialRecoveryModule==  addr=%s", socialRecoveryModule);

        require(address(calculateAddress) == address(socialRecoveryModule), "Not the same address");

        address[] memory modules = new address[](1);
        modules[0] = address(socialRecoveryModule);
        TrueContractManager(contractManager).add(modules);
    }

    /// @dev Additional private helper functions to generate the creation code for different components.
    function _getTrueWalletFactoryCode(address _walletImpl, address _owner, address _entryPoint)
        private
        pure
        returns (bytes memory)
    {
        bytes memory encodeInitParams = abi.encode(address(_walletImpl), address(_owner), address(_entryPoint));
        return abi.encodePacked(type(TrueWalletFactory).creationCode, encodeInitParams);
    }

    function _getTrueContractManagerCode(address _owner) private pure returns (bytes memory) {
        bytes memory encodeInitParams = abi.encode(address(_owner));
        return abi.encodePacked(type(TrueContractManager).creationCode, encodeInitParams);
    }

    function _getSecurityControlModuleCode(address _trueContractManager) private pure returns (bytes memory) {
        bytes memory encodeInitParams = abi.encode(address(_trueContractManager));
        return abi.encodePacked(type(SecurityControlModule).creationCode, encodeInitParams);
    }

    function _getSocialRecoveryModuleCode() private pure returns (bytes memory) {
        return type(SocialRecoveryModule).creationCode;
    }
}
