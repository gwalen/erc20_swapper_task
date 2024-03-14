pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {Counter} from "../src/Counter.sol";
import {ISubCounter} from "../src/interface/ISubCounter.sol";
import {SubCounter} from "../src/SubCounter.sol";

contract SubCounterTest is Test {
    Counter public counter;
    ISubCounter public subCounter;

    address OWNER = makeAddr("OWNER");
    address ALICE = makeAddr("ALICE");
    address BOB = makeAddr("BOB");

    Vm _vm = vm; // this wired declaration makes VsCode able to do "go-to-source" on _vm.* methods

    function setUp() public {
        counter = new Counter(OWNER);

        SubCounter subCounterContract = new SubCounter();
        subCounter = ISubCounter(address(subCounterContract));
        subCounterContract.setParent(address(counter));

        _vm.prank(OWNER);
        counter.setSubContract(address(subCounterContract));
    }

    function testSubCounterParent() public {
        address parent = subCounter.parent();
        // console2.log("---counter: ", address(parent));
        // console2.log("---subCounter parent: ", parent);
        assertEq(parent, address(counter));
    }

    function testAddIncrementor() public {
        counter.addIncrementor(ALICE);

        uint256 inc_len = subCounter.incrementorsLen();
        assertEq(inc_len, 1);
    }

    function testAddIncrementorWithRawCall() public {
        bytes4 funcSelector = bytes4(keccak256("addIncrementor(address)"));
        bytes memory callData1 = abi.encodeWithSelector(funcSelector, ALICE);

        bytes memory callData2 = abi.encodeWithSignature("addIncrementor(address)", BOB);
        /**  
         * both callData1 and callData2 are equivalent just the first one is creating the selector manually first
         * and the second has it inlined 
         */
        // only counter can call addIncrementor()
        _vm.startPrank(address(counter));
        (bool success, ) = address(subCounter).call(callData1);
        require(success, "First call with callData1 OK");
        (bool success2, ) = address(subCounter).call(callData2);
        require(success2, "Second call with callData2 OK");

        uint256 inc_len = subCounter.incrementorsLen();
        assertEq(inc_len, 2);
        _vm.stopPrank();
    }

    function testAddIncrementorInfo() public {
        subCounter.addIncrementorInfo(ALICE, ISubCounter.Status.GOOD);
        subCounter.addIncrementorInfo(BOB, ISubCounter.Status.BAD);

        ISubCounter.IncrementorInfo memory info1 = subCounter.readLastIncrementorInfo();
        uint256 timestamp = info1.blockTimestamp;
        console2.log("block timestamp : ", timestamp);

        assertEq(info1.incrementor, BOB);
        assertEq(uint(info1.status), 1);
    }


}