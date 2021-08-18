// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "./IRouter.sol";
import "hardhat/console.sol";

contract ToolV2 is Initializable {
    using SafeMath for uint256;
    address recipientAddr;
    IRouter uniswap;
    Registry balancer;
    IERC20 weth;

    constructor(address _recipient) public initializer {
        recipientAddr = _recipient;
        uniswap = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        balancer = Registry(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        weth = IERC20(0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2);
    }

    function _swapETHToToken(
        uint256[] memory _percentage,
        address[] memory tokens
    ) public payale {
        uint256 fee = (msg.value).div(1000);
        uint256 _value = (msg.value).sub(fee);

        // Transfer fee to recipient
        payable(recipientAddr).transfer(fee);
    }

    modifier isValid(uint256[] memory _percentage, address[] memory _address) {
        require(_percentage.length == _address.length, "Data don't match");
        require(msg.value > 0, "Not enough ETH");

        uint256 max = 0;

        for (uint256 i = 0; i < _percentage.length; i++) {
            max = max.add(_percentage[i]);
        }

        require(max <= 100 && max > 0, "Invalid percentage");
    }
}
