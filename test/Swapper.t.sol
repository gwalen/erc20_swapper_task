// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console2, Vm} from "forge-std/Test.sol";
import { Swapper } from "../src/Swapper.sol";
import { SwapperDeployer } from "../script/deployer/SwapperDeployer.s.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract SwapperTest is Test, SwapperDeployer {
    
    address constant UNIV3_ROUTER_MAINNET = 0xE592427A0AEce92De3Edee1F18E0157C05861564; 
    address constant WETH9_MAINNET = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; 
    address constant USDC_MAINNET = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    // address constant USDC_WETH_POOL_MAINNET = 0x8ad599c3A0ff1De082011EFDDc58f1908eb6e6D8;

    uint256 USDC_DECIMALS_MUL = 10 ** 6;

    address OWNER = makeAddr("OWNER");
    address ALICE = makeAddr("ALICE");
    address BOB = makeAddr("BOB");

    // TODO: remove
    Vm _vm = vm;

    function setUp() public {
        _vm.deal(OWNER, 1 ether);

        _vm.startPrank(OWNER);
        deployImplementation();
        deployProxy(OWNER, UNIV3_ROUTER_MAINNET, WETH9_MAINNET);
        _vm.stopPrank();
    }

    function testSwap() public {
        _vm.deal(ALICE, 2 ether);
        _vm.startPrank(ALICE);

        console2.log("swapper address: ", address(swapperProxy));
        uint256 amountOutMin = 1_000 * USDC_DECIMALS_MUL;

        uint256 balance_before = IERC20(USDC_MAINNET).balanceOf(ALICE);
        uint256 amountOut = swapperProxy.swapEtherToToken{value: 1 ether}(USDC_MAINNET, amountOutMin);
        uint256 balance_diff = IERC20(USDC_MAINNET).balanceOf(ALICE) - balance_before;


        assertEq(balance_diff, amountOut);
        assertGe(amountOut, amountOutMin);

        _vm.stopPrank();
    }

}