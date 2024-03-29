// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRegistry {
    function getBestPoolsWithLimit(
        address fromToken,
        address destToken,
        uint256 limit
    ) external view returns (address[] memory pools);
}
