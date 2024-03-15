// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./interface/Erc20Swapper.sol";
import "./interface/ISwapRouter.sol";
import "./interface/IWETH9.sol";

// import "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { UUPSUpgradeable } from "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";

import { console2 } from "forge-std/Test.sol";

//TODO: UUPS proxy, change Ownable to OwnableUpgradable
contract Swapper is ERC20Swapper, UUPSUpgradeable, OwnableUpgradeable {
    // WETH address can be different for each network
    address public WETH; //0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14; // Sepolia

    // TODO: check address on Sepolia
    // ISwapRouter constant uniV3Router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);  // main-net address
    ISwapRouter public uniV3Router;

    // Disable initializing on implementation contract
    constructor() {
        _disableInitializers();
    }

    function initialize(address _owner, address _uniV3Router, address _WETH) external initializer {
        // Init inherited contract
        __UUPSUpgradeable_init();
        __Ownable_init(_owner);
        uniV3Router = ISwapRouter(_uniV3Router);
        WETH = _WETH;
    }

    // Makes sure only the owner can upgrade, called from upgradeTo(..)
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function swapEtherToToken(
        address token,
        uint minAmount
    ) external payable override returns (uint) {
        if (msg.value == 0) {
            revert EtherInputZero();
        }
        console2.log("token %s, minAmount: %s", token, minAmount);
        console2.log("msg.value: ", msg.value);
        // wrap Eth to Weth, now contract was msg.value amount of WETH tokens
        console2.log("Eth this: ", address(this).balance);
        console2.log("WETH address: ", WETH);
        IWETH9(WETH).deposit{value: msg.value}();
        // IWETH9(WETH).transfer(msg.sender, msg.value);
        console2.log("Eth this:2 ", address(this).balance);

        uint tokenBalanceBefore = IERC20(token).balanceOf(msg.sender);
        swapWithDex(token, msg.sender, msg.value);
        uint tokenBalanceDiff = IERC20(token).balanceOf(msg.sender) - tokenBalanceBefore;


        console2.log("tokenBalanceDiff: ", tokenBalanceDiff);

        if (tokenBalanceDiff < minAmount) {
            revert AmountOutTooSmall();
        }
        
        return tokenBalanceDiff;
    }

    // TODO: can I mock internal functions in Foundry ?
    /// @dev swap with external dex in this case with uniswapV3 
    function swapWithDex(
        address tokenOut,
        address recipient,
        uint amountIn
    ) internal returns (uint) {
        // IERC20(WETH).transferFrom(msg.sender, address(this), amountIn); // done in swapEtherToToken
        IERC20(WETH).approve(address(uniV3Router), amountIn);

        console2.log("just before swap");

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: WETH,
                tokenOut: tokenOut,
                fee: 3000,  // 0.3% - standard uniswap fee - double check if this is the case for out pools
                recipient: recipient,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,  // we check this value on our own, and want to rely on own errors
                sqrtPriceLimitX96: 0
            });

        uint amountOut = uniV3Router.exactInputSingle(params);
        console2.log("Dex result: amountOut: ", amountOut);
        return amountOut;
    }

    // TODO: add rescue function to retrieve any eth or ERC tokens send to contract accidentally (only admin can do it)
    // TODO: add comments in the Solidity style
}
