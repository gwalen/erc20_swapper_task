// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console2, Vm} from "forge-std/Test.sol";
import { Swapper } from "../src/Swapper.sol";
import { Erc20Swapper } from "../src/interface/Erc20Swapper.sol";

import { SwapperDeployer } from "../script/deployer/SwapperDeployer.s.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { PausableUpgradeable } from "@openzeppelin-upgradeable/contracts/utils/PausableUpgradeable.sol";


contract SwapperTest is Test, SwapperDeployer {
    
    address constant UNIV3_ROUTER_MAINNET = 0xE592427A0AEce92De3Edee1F18E0157C05861564; 
    address constant WETH9_MAINNET = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; 
    address constant USDC_MAINNET = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    uint256 USDC_DECIMALS_MUL = 10 ** 6;

    address OWNER = makeAddr("OWNER");
    address KEEPER = makeAddr("KEEPER");
    address ALICE = makeAddr("ALICE");

    // TODO: remove
    Vm _vm = vm;

    function setUp() public {
        _vm.deal(OWNER, 1 ether);

        _vm.startPrank(OWNER);
        deployImplementation();
        deployProxy(OWNER, KEEPER, UNIV3_ROUTER_MAINNET, WETH9_MAINNET);
        _vm.stopPrank();
    }

    function testSwap() public {
        _vm.deal(ALICE, 2 ether);
        uint256 amountOutMin = 1_000 * USDC_DECIMALS_MUL;

        _vm.startPrank(ALICE);

        uint256 balance_before = IERC20(USDC_MAINNET).balanceOf(ALICE);
        uint256 amountOut = swapperProxy.swapEtherToToken{value: 1 ether}(USDC_MAINNET, amountOutMin);
        uint256 balance_diff = IERC20(USDC_MAINNET).balanceOf(ALICE) - balance_before;

        assertEq(balance_diff, amountOut);
        assertGe(amountOut, amountOutMin);

        _vm.stopPrank();
    }

    function testSwapEvent() public {
        _vm.deal(ALICE, 2 ether);
        uint256 amountOutMin = 1_000 * USDC_DECIMALS_MUL;

        _vm.startPrank(ALICE);
        
        _vm.expectEmit(false, false, false, false, address(swapperProxy));
        emit Erc20Swapper.Swapped(USDC_MAINNET, ALICE, 1 ether, 0); // the last value will not match as we don't know result yet
        swapperProxy.swapEtherToToken{value: 1 ether}(USDC_MAINNET, amountOutMin);

        _vm.stopPrank();
    }

    function testSwapWhenPaused() public {
        _vm.deal(ALICE, 2 ether);
        uint256 amountOutMin = 1_000 * USDC_DECIMALS_MUL;

        _vm.prank(KEEPER);
        swapperProxy.pause();

        _vm.startPrank(ALICE);
        
        _vm.expectRevert(abi.encodeWithSelector(PausableUpgradeable.EnforcedPause.selector));
        swapperProxy.swapEtherToToken{value: 1 ether}(USDC_MAINNET, amountOutMin);

        _vm.stopPrank();
    }

    function testErrorWithZeroEthInput() public {
        _vm.startPrank(ALICE);
        _vm.expectRevert(abi.encodeWithSelector(Erc20Swapper.EtherInputZero.selector));
        swapperProxy.swapEtherToToken{value: 0}(USDC_MAINNET, 1_000 * USDC_DECIMALS_MUL);
        _vm.stopPrank();
    }

    function testErrorWrongAmountOut() public {
        _vm.deal(ALICE, 2 ether);
        _vm.startPrank(ALICE);
        _vm.expectRevert(abi.encodeWithSelector(Erc20Swapper.AmountOutTooSmall.selector));
        swapperProxy.swapEtherToToken{value: 1 ether}(USDC_MAINNET, 1_000_000 * USDC_DECIMALS_MUL);
        _vm.stopPrank();
    }

    function testOnlyKeeperCanPause() public {
        _vm.startPrank(ALICE);
        _vm.expectRevert(abi.encodeWithSelector(Erc20Swapper.OnlyKeeperCanAccess.selector));
        swapperProxy.pause();
        _vm.stopPrank();
    }

    function testOnlyKeeperCanUnpause() public {
        _vm.prank(KEEPER);
        swapperProxy.pause();

        _vm.startPrank(ALICE);
        _vm.expectRevert(abi.encodeWithSelector(Erc20Swapper.OnlyKeeperCanAccess.selector));
        swapperProxy.unpause();
        _vm.stopPrank();
    }


}