// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./interface/IErc20Swapper.sol";
import "./interface/ISwapRouter.sol";
import "./interface/IWETH9.sol";

// import "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { UUPSUpgradeable } from "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin-upgradeable/contracts/utils/PausableUpgradeable.sol";

contract Swapper is IErc20Swapper, UUPSUpgradeable, OwnableUpgradeable, PausableUpgradeable {
    address public WETH;
    ISwapRouter public uniV3Router;
    address public keeper;

    modifier onlyKeeper() {
        if (msg.sender != keeper) {
            revert OnlyKeeperCanAccess();
        }
        _;
    }

    // Disable initializing on implementation contract
    constructor() {
        _disableInitializers();
    }

    function initialize(address _owner, address _keeper, address _uniV3Router, address _WETH) external initializer {
        // Init inherited contract
        __UUPSUpgradeable_init();
        __Ownable_init(_owner);
        __Pausable_init();
        uniV3Router = ISwapRouter(_uniV3Router);
        WETH = _WETH;
        keeper = _keeper;
    }

    // Makes sure only the owner can upgrade, called from upgradeTo(..)
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function swapEtherToToken(
        address token,
        uint minAmount
    ) external payable override whenNotPaused returns(uint) {
        if (msg.value == 0) {
            revert EtherInputZero();
        }
        // wrap Eth to Weth, now contract was msg.value amount of WETH tokens
        IWETH9(WETH).deposit{value: msg.value}();

        uint tokenBalanceBefore = IERC20(token).balanceOf(msg.sender);
        swapWithDex(token, msg.sender, msg.value);
        uint tokenBalanceDiff = IERC20(token).balanceOf(msg.sender) - tokenBalanceBefore;

        if (tokenBalanceDiff < minAmount) {
            revert AmountOutTooSmall();
        }
        
        emit Swapped(token, msg.sender, msg.value, tokenBalanceDiff);
        return tokenBalanceDiff;
    }

    /// @dev swap with external dex in this case with uniswapV3 
    function swapWithDex(
        address tokenOut,
        address recipient,
        uint amountIn
    ) internal {
        // approve router to use our weth in the swap
        IERC20(WETH).approve(address(uniV3Router), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: WETH,
                tokenOut: tokenOut,
                fee: 3000,  // 0.3% - standard uniswap fee, this could be a parameter if needed
                recipient: recipient,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,  // we check this value on our own, and want to rely on own errors
                sqrtPriceLimitX96: 0
            });
        uniV3Router.exactInputSingle(params);
    }

    /// Keeper can pause/unpause in case of emergency at ant time, owner role is timelock protected 
    function pause() external onlyKeeper {
        _pause();
    }

    /// Keeper can pause/unpause in case of emergency at ant time, owner role is timelock protected 
    function unpause() external onlyKeeper {
        _unpause();
    }

    // TODO: add rescue function to retrieve any eth or ERC tokens send to contract accidentally (only admin can do it)
    // TODO: add comments in the Solidity style
    // TODO: deploy on Sepolia testnet
    // TODO: remove console2 and unused imports
    // TODO: add comment or add class to check reentracy guard - but this contract does not store any values 
    //       and only case when it could be attacked in sending eth to with deposit() - but this is WETH9 contract, rather wont get hacked
    //       also if entered agin if external swap gets hacked, nothing would happen

    /**
    * @notice  Rescue eth in case someone sent it accidentally
    */
    function rescueEth() external onlyOwner {
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Failed to send Native token");
    }
}
