// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

interface Erc20Swapper {

    error EtherInputZero();
    error AmountOutTooSmall();
    error OnlyKeeperCanAccess();

    event Swapped(address token, address user, uint256 amountIn, uint256 amountOut);

    /// @dev swaps the `msg.value` Ether to at least `minAmount` of tokens in `address`, or reverts
    /// @param token The address of ERC-20 token to swap
    /// @param minAmount The minimum amount of tokens transferred to msg.sender
    /// @return The actual amount of transferred tokens
    function swapEtherToToken(address token, uint minAmount) external payable returns (uint);
}