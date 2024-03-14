// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {Counter} from "../src/Counter.sol";

contract CounterScript is Script {

    address anvilTestAccount1 = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    function setUp() public {}

    function run() public {
        // vm.startBroadcast(0xa0Ee7A142d267C1f36714E4a8F75612F20a79720);
        vm.startBroadcast();
        Counter counter = new Counter(anvilTestAccount1);
        
        vm.stopBroadcast();

        console2.log("counter address: ", address(counter));
    }
}
