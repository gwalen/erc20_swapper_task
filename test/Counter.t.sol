// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Counter} from "../src/Counter.sol";

contract CounterTest is Test {
    Counter public counter;

    address OWNER = makeAddr("OWNER");
    address ALICE = makeAddr("ALICE");
    address BOB = makeAddr("BOB");

    function setUp() public {
        counter = new Counter(OWNER);
        vm.deal(OWNER, 1 ether);
    }

    function testIncrementOnlyWhitelisted() public {
        vm.prank(OWNER);
        counter.addUserToWhitelist(ALICE);

        vm.prank(ALICE);
        counter.increment();

        assertEq(counter.number(), 1);
        assertEq(counter.counterValue(), 1);
    }

    function testIncrementCheckUserCounter() public {
        vm.prank(OWNER);
        counter.addUserToWhitelist(ALICE);

        vm.startPrank(ALICE);
        counter.increment();
        counter.increment();
        vm.stopPrank();

        assertEq(counter.userCounterValue(ALICE), 2);
    }


    function testOnlyAdminCanWhitelist() public {
        vm.startPrank(ALICE);
        vm.expectRevert("Only admin");
        counter.addUserToWhitelist(ALICE);
        vm.stopPrank();
    }

    function testOnlyWhitelistedCanIncrement() public {
        vm.prank(OWNER);
        counter.addUserToWhitelist(ALICE);

        vm.startPrank(BOB);
        vm.expectRevert(
            abi.encodeWithSelector(Counter.OnlyWhitelisted.selector, BOB)
        );
        counter.increment();
        vm.stopPrank();

        vm.startPrank(ALICE);
        counter.increment();
        vm.stopPrank();
    }


}
