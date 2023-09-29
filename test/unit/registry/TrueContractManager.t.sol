// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import {TrueContractManager} from "src/registry/TrueContractManager.sol";
import {MockModule} from "../../mocks/MockModule.sol";

contract TrueContractManagerUnitTest is Test {
    TrueContractManager contractManager;
    MockModule module;

    address ownerAddress = makeAddr("ownerAddress");
    address user = makeAddr("user");

    event TrueContractManagerAdded(address indexed module);
    event TrueContractManagerRemoved(address indexed module);

    function setUp() public {
        contractManager = new TrueContractManager(address(ownerAddress));
        module = new MockModule();
    }

    function testSetupState() public {
        assertEq(contractManager.owner(), ownerAddress);
    }

    function testAddContract() public {
        assertFalse(contractManager.isTrueModule(address(module)));
        address[] memory modules = new address[](1);
        modules[0] = address(module);
        vm.prank(address(ownerAddress));
        vm.expectEmit(true, false, false, true);
        emit TrueContractManagerAdded(address(module));
        contractManager.add(modules);
        assertTrue(contractManager.isTrueModule(address(module)));
    }

    function testRevertsIfAddContractByNotOwner() public {
        assertFalse(contractManager.isTrueModule(address(module)));
        address[] memory modules = new address[](1);
        modules[0] = address(module);
        vm.prank(address(user));
        vm.expectRevert("UNAUTHORIZED");
        contractManager.add(modules);
        assertFalse(contractManager.isTrueModule(address(module)));
    }

    function testRevertsIfNotContractProvided() public {
        address[] memory modules = new address[](1);
        modules[0] = address(user);
        vm.prank(address(ownerAddress));
        vm.expectRevert(TrueContractManager.TrueContractManager__NotContractProvided.selector);
        contractManager.add(modules);
    }

    function testRevertsIfContractAlreadyRegistered() public {
        testAddContract();
        assertTrue(contractManager.isTrueModule(address(module)));
        address[] memory modules = new address[](1);
        modules[0] = address(module);
        vm.prank(address(ownerAddress));
        vm.expectRevert(TrueContractManager.TrueContractManager__ContractAlreadyRegistered.selector);
        contractManager.add(modules);
        assertTrue(contractManager.isTrueModule(address(module)));
    }

    function testCanAddListOfContracts() public {
        MockModule module2 = new MockModule();
        assertFalse(contractManager.isTrueModule(address(module)));
        assertFalse(contractManager.isTrueModule(address(module2)));
        address[] memory modules = new address[](2);
        modules[0] = address(module);
        modules[1] = address(module2);
        vm.prank(address(ownerAddress));
        contractManager.add(modules);
        assertTrue(contractManager.isTrueModule(address(module)));
        assertTrue(contractManager.isTrueModule(address(module2)));
    }

    function testRemoveContract() public {
        testAddContract();
        assertTrue(contractManager.isTrueModule(address(module)));
        address[] memory modules = new address[](1);
        modules[0] = address(module);
        vm.prank(address(ownerAddress));
        vm.expectEmit(true, false, false, true);
        emit TrueContractManagerRemoved(address(module));
        contractManager.remove(modules);
        assertFalse(contractManager.isTrueModule(address(module)));
    }

    function testRevertsIfRemoveContractByNotOwner() public {
        testAddContract();
        assertTrue(contractManager.isTrueModule(address(module)));
        address[] memory modules = new address[](1);
        modules[0] = address(module);
        vm.prank(address(user));
        vm.expectRevert("UNAUTHORIZED");
        contractManager.remove(modules);
        assertTrue(contractManager.isTrueModule(address(module)));
    }

    function testRevertsIfContractNotRegistered() public {
        testAddContract();
        assertTrue(contractManager.isTrueModule(address(module)));
        MockModule module2 = new MockModule();
        address[] memory modules = new address[](1);
        modules[0] = address(module2);
        vm.prank(address(ownerAddress));
        vm.expectRevert(TrueContractManager.TrueContractManager__ContractNotRegistered.selector);
        contractManager.remove(modules);
        assertTrue(contractManager.isTrueModule(address(module)));
    }
}