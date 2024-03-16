// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import { Test } from "forge-std/Test.sol";
import "./deployer/SwapperDeployer.s.sol";
import "../src/Swapper.sol";

contract MainDeployer is Script, Test, SwapperDeployer {

    // SwapperDeployer swapperDeployer;
    address owner;
    address uniV3Router;
    address wEth;

    function setUp() internal {
        owner = vm.envAddress("OWNER_ADDRESS");
        uniV3Router = vm.envAddress("SEPOLIA_UNI_V3_ROUTER");
        wEth = vm.envAddress("SEPOLIA_WETH");
    }

    function run() external  {
        setUp();

        vm.startBroadcast();
        deployImplementation();
        deployProxy(owner, uniV3Router, wEth);
        
        vm.stopBroadcast();

        console2.log("Proxy address: ", address(swapperProxy));
        verify();
    }


    function verify() internal {
        Swapper swapper = Swapper(swapperProxy);
        assertEq(swapper.owner(), owner, "wrong owner");
        assertEq(address(swapper.uniV3Router()), uniV3Router, "wrong uniV3Router");
        assertEq(swapper.WETH(), wEth, "wrong WETH");
    }

}