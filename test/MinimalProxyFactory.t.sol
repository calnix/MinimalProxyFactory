// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "lib/forge-std/src/Test.sol";
import "lib/forge-std/src/console.sol";
import { MinimalProxyFactory } from "../src/MinimalProxyFactory.sol";
import { SimpleNameRegister } from "../test/SimpleRegistry.sol";

abstract contract StateZero is Test {
    address deployer;
    address user;

    MinimalProxyFactory public minimalProxyFactory;
    SimpleNameRegister public simpleRegistry;

    /// @notice Emit event when a name is registered
    event Register(address indexed holder, string name);

    /// @notice Emit event when a name is released
    event Release(address indexed holder, string name);

    function setUp() public virtual {
        deployer = makeAddr('deployer');
        vm.label(deployer, 'deployer');

        user = makeAddr('user');
        vm.label(user, 'user');

        vm.startPrank(deployer);
        simpleRegistry = new SimpleNameRegister();
        vm.label(address(simpleRegistry), 'simpleRegistry');

        minimalProxyFactory = new MinimalProxyFactory();
        vm.label(address(minimalProxyFactory), 'minimalProxyFactory');

        vm.stopPrank();
    }
}


contract StateZeroTest is StateZero {

    function testDeploy() public {
        console2.log('Address of deployed should be the same as pre-determined approach');

        uint256 salt = 1234;

        address deployedProxy = minimalProxyFactory.deploy(address(simpleRegistry), salt);       
        address newGenerated = minimalProxyFactory.getAddress(address(simpleRegistry), salt);

        assertTrue(deployedProxy == newGenerated);
    }


    function testDeployDifferingSalt() public {
        console2.log('Address of newJoin deployed should change with different salts');

        uint256 salt1 = 1234;
        uint256 salt2 = 4567;

        address deployedProxy = minimalProxyFactory.deploy(address(simpleRegistry), salt1);       
        address newGenerated = minimalProxyFactory.getAddress(address(simpleRegistry), salt2);


        assertTrue(deployedProxy != newGenerated);
    }
}

abstract contract StateDeployed is StateZero {
    address deployedProxy;

    function setUp() public virtual override {
        super.setUp();

        uint256 salt = 1234;
        deployedProxy = minimalProxyFactory.deploy(address(simpleRegistry), salt);       
    }
}


contract StateDeployedTest is StateDeployed {
    function testProxyRegister(string memory testString) public {
        
        vm.expectEmit(true, false, false, false);
        emit Register(user, testString);

        vm.prank(user);
        SimpleNameRegister(deployedProxy).register(testString);

        assertTrue(SimpleNameRegister(deployedProxy).holder(testString) == user);
        assertTrue(simpleRegistry.holder(testString) == address(0));

    }

    function testProxyRelease(string memory testString) public {
        SimpleNameRegister(deployedProxy).register(testString);

        vm.expectEmit(true, false, false, false);
        emit Release(address(this), testString);
        SimpleNameRegister(deployedProxy).release(testString);

        assertTrue(SimpleNameRegister(deployedProxy).holder(testString) == address(0));
        assertTrue(simpleRegistry.holder(testString) == address(0));
    }

    // ownership of master and clone are independent 
    function testInitialise() public {
        console2.log('Factory is deployer of proxy, therefore owner');

        assertTrue(SimpleNameRegister(deployedProxy).owner() == address(minimalProxyFactory));
        assertTrue(simpleRegistry.owner() == address(0));
    }

    function testChangeOwner(address newOwner) public {
        console2.log('Deployer of Factory is Master: can enact ownership transfer of proxy');

        vm.prank(deployer);
        minimalProxyFactory.changeOwner(deployedProxy, newOwner);

        assertTrue(SimpleNameRegister(deployedProxy).owner() == newOwner);

    }
}