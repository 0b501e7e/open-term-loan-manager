// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { LoanManagerHarness } from "./utils/Harnesses.sol";
import { TestBase }           from "./utils/TestBase.sol";

import {
    MockFactory,
    MockGlobals,
    MockLoan,
    MockPoolManager
} from "./utils/Mocks.sol";

contract RejectNewTermsTests is TestBase {

    address poolDelegate = makeAddr("poolDelegate");
    address refinancer   = makeAddr("refinancer");

    LoanManagerHarness loanManager = new LoanManagerHarness();

    MockFactory     factory     = new MockFactory();
    MockGlobals     globals     = new MockGlobals();
    MockLoan        loan        = new MockLoan();
    MockPoolManager poolManager = new MockPoolManager();

    function setUp() public {
        factory.__setMapleGlobals(address(globals));

        poolManager.__setPoolDelegate(poolDelegate);

        loanManager.__setLocked(1);
        loanManager.__setPoolManager(address(poolManager));
        loanManager.__setFactory(address(factory));
    }

    function test_rejectNewTerms_paused() public {
        globals.__setFunctionPaused(true);

        vm.expectRevert("LM:PAUSED");
        loanManager.rejectNewTerms(address(loan), address(0), 0, new bytes[](0));
    }

    function test_rejectNewTerms_notPoolDelegate() public {
        vm.expectRevert("LM:RNT:NOT_PD");
        loanManager.rejectNewTerms(address(loan), address(0), 0, new bytes[](0));
    }

    function test_rejectNewTerms_success() public {
        loan.__expectCall();
        loan.rejectNewTerms(refinancer, block.timestamp, new bytes[](1));

        vm.prank(poolDelegate);
        loanManager.rejectNewTerms(address(loan), address(refinancer), block.timestamp, new bytes[](1));
    }

}
