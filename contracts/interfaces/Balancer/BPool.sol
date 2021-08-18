// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface BPool {
    function getSpotPrice(address tokenIn, address tokenOut)
        external
        view
        returns (uint256 spotPrice);

    function swapExactAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        address tokenOut,
        uint256 minAmountOut,
        uint256 maxPrice
    ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter);
}
