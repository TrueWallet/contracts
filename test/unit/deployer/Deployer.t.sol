// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import {Deployer, CREATE3, Ownable} from "src/deployer/Deployer.sol";
import {TrueWallet} from "src/wallet/TrueWallet.sol";
import {EntryPoint} from "test/mocks/protocol/EntryPoint.sol";
import {
    DeployCodeGenerator,
    TrueWalletFactory,
    TrueContractManager,
    SecurityControlModule,
    SocialRecoveryModule
} from "src/deployer/DeployCodeGenerator.sol";

contract DeployerUnitTest is Test {
    Deployer deployer;
    TrueWallet wallet;
    EntryPoint entryPoint;
    TrueContractManager contractManager;
    DeployCodeGenerator deployCodeGenerator;
    bytes32 salt;

    address adminAddress;
    uint256 adminPrivateKey;

    event ContractDeployed(address indexed contractAddress);

    function setUp() public {
        (adminAddress, adminPrivateKey) = makeAddrAndKey("adminAddress");
        entryPoint = new EntryPoint();
        deployer = new Deployer(adminAddress);
        deployCodeGenerator = new DeployCodeGenerator();
    }

    function testSetupState() public {
        assertEq(deployer.owner(), address(adminAddress));
        assertTrue(
            deployCodeGenerator.getTrueWalletFactoryCode(address(wallet), adminAddress, address(entryPoint)).length > 0
        );
        assertTrue(deployCodeGenerator.getTrueContractManagerCode(adminAddress).length > 0);
        assertTrue(deployCodeGenerator.getSecurityControlModuleCode(address(contractManager)).length > 0);
        assertTrue(deployCodeGenerator.getSocialRecoveryModuleCode().length > 0);
        assertTrue(deployCodeGenerator.getTrueWalletImplCode().length > 0);
    }

    function testDeployWalletImpl() public {
        salt = keccak256(abi.encodePacked(bytes(deployCodeGenerator.getTrueWalletImplCode())));
        address calculateAddress = deployer.getContractAddress(salt);
        assertFalse(calculateAddress.code.length > 0);
        bytes memory walletCode = deployCodeGenerator.getTrueWalletImplCode();
        vm.prank(address(this));
        vm.expectRevert(Ownable.Unauthorized.selector);
        deployer.deploy(salt, walletCode);
        vm.prank(adminAddress);
        address deployedContract = deployer.deploy(salt, walletCode);
        assertEq(calculateAddress, deployedContract);
        assertTrue(calculateAddress.code.length > 0);
        wallet = TrueWallet(payable(address(deployedContract)));
    }

    function testDeployFactory() public {
        testDeployWalletImpl();
        salt = keccak256(
            abi.encodePacked(
                bytes(deployCodeGenerator.getTrueWalletFactoryCode(address(wallet), adminAddress, address(entryPoint)))
            )
        );
        address calculateAddress = deployer.getContractAddress(salt);
        assertFalse(calculateAddress.code.length > 0);
        bytes memory factoryCode =
            deployCodeGenerator.getTrueWalletFactoryCode(address(wallet), adminAddress, address(entryPoint));
        vm.prank(adminAddress);
        vm.expectEmit(true, true, true, true);
        emit ContractDeployed(calculateAddress);
        address deployedContract = deployer.deploy(salt, factoryCode);
        assertEq(calculateAddress, deployedContract);
        assertTrue(calculateAddress.code.length > 0);
        assertEq(TrueWalletFactory(deployedContract).walletImplementation(), address(wallet));
        assertEq(TrueWalletFactory(deployedContract).entryPoint(), address(entryPoint));
        assertEq(TrueWalletFactory(deployedContract).owner(), address(adminAddress));
        vm.prank(adminAddress);
        vm.expectRevert(CREATE3.DeploymentFailed.selector);
        address _deployedContract = deployer.deploy(salt, factoryCode);
        assertEq(_deployedContract.code.length, 0);
    }

    function testDeployContractManager() public {
        salt = keccak256(abi.encodePacked(bytes(deployCodeGenerator.getTrueContractManagerCode(address(adminAddress)))));
        address calculateAddress = deployer.getContractAddress(salt);
        assertFalse(calculateAddress.code.length > 0);
        bytes memory contractManagerCode = deployCodeGenerator.getTrueContractManagerCode(address(adminAddress));
        vm.prank(adminAddress);
        address deployedContract = deployer.deploy(salt, contractManagerCode);
        assertEq(calculateAddress, deployedContract);
        assertTrue(calculateAddress.code.length > 0);
        assertEq(TrueContractManager(deployedContract).owner(), address(adminAddress));
        contractManager = TrueContractManager(address(deployedContract));
    }

    function testDeploySecurityControlModule() public {
        testDeployContractManager();
        salt = keccak256(
            abi.encodePacked(bytes(deployCodeGenerator.getSecurityControlModuleCode(address(contractManager))))
        );
        address calculateAddress = deployer.getContractAddress(salt);
        assertFalse(calculateAddress.code.length > 0);
        bytes memory contractManagerCode = deployCodeGenerator.getSecurityControlModuleCode(address(contractManager));
        vm.prank(adminAddress);
        address deployedContract = deployer.deploy(salt, contractManagerCode);
        assertEq(calculateAddress, deployedContract);
        assertTrue(calculateAddress.code.length > 0);
        assertEq(address(SecurityControlModule(deployedContract).trueContractManager()), address(contractManager));
    }

    function testDeploySocialRecoveryModule() public {
        salt = keccak256(abi.encodePacked(bytes(deployCodeGenerator.getSocialRecoveryModuleCode())));
        address calculateAddress = deployer.getContractAddress(salt);
        assertFalse(calculateAddress.code.length > 0);
        bytes memory socialRacoveryCode = deployCodeGenerator.getSocialRecoveryModuleCode();
        vm.prank(address(this));
        vm.expectRevert(Ownable.Unauthorized.selector);
        deployer.deploy(salt, socialRacoveryCode);
        vm.prank(adminAddress);
        address deployedContract = deployer.deploy(salt, socialRacoveryCode);
        assertEq(calculateAddress, deployedContract);
        assertTrue(calculateAddress.code.length > 0);
    }
}
