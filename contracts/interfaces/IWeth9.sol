// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface WETH9 {
    function deposit() external payable;

    function approve(address guy, uint256 wad) external returns (bool);
}
