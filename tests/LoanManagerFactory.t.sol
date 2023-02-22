// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { Test } from "../modules/forge-std/src/Test.sol";

import { LoanManager }            from "../contracts/LoanManager.sol";
import { LoanManagerFactory }     from "../contracts/LoanManagerFactory.sol";
import { LoanManagerInitializer } from "../contracts/LoanManagerInitializer.sol";

import { MockFactory, MockGlobals, MockPool, MockPoolManager } from "./utils/Mocks.sol";

contract LoanManagerFactoryBase is Test {

    address governor;
    address implementation;
    address initializer;

    address asset   = makeAddr("asset");
    address manager = makeAddr("manager");

    MockGlobals     globals;
    MockPool        pool;
    MockPoolManager poolManager;
    MockFactory     poolManagerFactory;

    LoanManagerFactory factory;

    function setUp() public virtual {
        governor       = makeAddr("governor");
        implementation = address(new LoanManager());
        initializer    = address(new LoanManagerInitializer());

        globals            = new MockGlobals(governor);
        pool               = new MockPool();
        poolManager        = new MockPoolManager();
        poolManagerFactory = new MockFactory();

        vm.startPrank(governor);
        factory = new LoanManagerFactory(address(globals));
        factory.registerImplementation(1, implementation, initializer);
        factory.setDefaultVersion(1);
        vm.stopPrank();

        globals.setValidPoolDeployer(address(this), true);

        pool.__setAsset(asset);
        pool.__setManager(manager);
    }

    function test_createInstance_notPoolDeployer() external {
        globals.setValidPoolDeployer(address(this), false);
        vm.expectRevert();
        LoanManager(factory.createInstance(abi.encode(address(pool)), "SALT"));
    }

    function test_createInstance_invalidPoolManagerFactory() external {
        vm.prank(address(poolManager));
        vm.expectRevert("LMF:CI:INVALID_FACTORY");
        LoanManager(factory.createInstance(abi.encode(address(pool)), "SALT"));
    }

    function test_createInstance_notPoolManager() external {
        globals.__setIsFactory(true);
        poolManager.__setFactory(address(poolManagerFactory));

        vm.prank(address(poolManager));
        vm.expectRevert("LMF:CI:NOT_PM");
        LoanManager(factory.createInstance(abi.encode(address(pool)), "SALT"));
    }

    function testFail_createInstance_notPool() external {
        factory.createInstance(abi.encode(address(1)), "SALT");
    }

    function testFail_createInstance_collision() external {
        factory.createInstance(abi.encode(address(pool)), "SALT");
        factory.createInstance(abi.encode(address(pool)), "SALT");
    }

    function test_createInstance_success() external {
        LoanManager loanManager_ = LoanManager(factory.createInstance(abi.encode(address(pool)), "SALT"));

        assertEq(loanManager_.pool(),        address(pool));
        assertEq(loanManager_.fundsAsset(),  address(asset));
        assertEq(loanManager_.poolManager(), address(manager));
    }

    function test_createInstance_withPoolManager() external {
        globals.__setIsFactory(true);
        poolManager.__setFactory(address(poolManagerFactory));
        poolManagerFactory.__setIsInstance(true);

        vm.prank(address(poolManager));

        LoanManager loanManager_ = LoanManager(factory.createInstance(abi.encode(address(pool)), "SALT"));

        assertEq(loanManager_.pool(),        address(pool));
        assertEq(loanManager_.fundsAsset(),  address(asset));
        assertEq(loanManager_.poolManager(), address(manager));
    }

}
