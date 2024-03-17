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

/**
 * @dev Contract that swaps Eth into given token using selected third party Dex.
 *      Contract is upgradable to allow changing the underlying Dex and introduce new features.
 *      
 * @notice There are two management roles in this contract:
 *   - owner: this role is most significant it allows to upgrade the implementation, 
 *     To reduce to risk owner is Timelock contract.
 *   - keeper: this role allows to quickly pause/unpause the contract in case of emergency (like issues with Dex)
 */
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
        __UUPSUpgradeable_init();
        __Ownable_init(_owner);
        __Pausable_init();
        uniV3Router = ISwapRouter(_uniV3Router);
        WETH = _WETH;
        keeper = _keeper;
    }

    // Makes sure only the owner can upgrade, called from upgradeTo(..)
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @dev Swaps the `msg.value` Ether to at least `minAmount` of tokens in `address`, or reverts
     * When emergency contract can we paused and this method is disabled.
     * 
     * @param token - token to swap to
     * @param minAmount - minimum amount of tokens to receive
     */
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

    /**
     * @dev Swap with external dex in this case with uniswapV3 
     * 
     * @param tokenOut - token to swap to
     * @param recipient - recipient who will get the swapped token
     * @param amountIn - amount of WETH to swap
     */
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

    /**
     * @dev Keeper can pause/unpause in case of emergency at ant time, owner role is timelock protected  
     */
    function pause() external onlyKeeper {
        _pause();
    }

    /**
     * @dev Keeper can pause/unpause in case of emergency at ant time, owner role is timelock protected  
     */ 
    function unpause() external onlyKeeper {
        _unpause();
    }

    // TODO: 2. finish readme and check grammar with chatgpt
    // TODO: 4. publish to github and send

    /**
     * @dev Rescue eth in case someone sent it accidentally
     */
    function rescueEth() external onlyOwner {
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Failed to send Native token");
    }
}
