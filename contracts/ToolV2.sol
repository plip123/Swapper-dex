// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/IRouter.sol";
import "./interfaces/Balancer/BPool.sol";
import "./interfaces/Balancer/IRegistry.sol";
import "./interfaces/IWeth9.sol";
import "hardhat/console.sol";

contract ToolV2 is Initializable {
    using SafeMath for uint256;
    address recipientAddr;
    IRouter uniswap;
    IRegistry balancer;
    BPool bPool;
    WETH9 weth;

    function initialize(address _recipient) public initializer {
        recipientAddr = _recipient;
        uniswap = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        balancer = IRegistry(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        weth = WETH9(uniswap.WETH());
    }

    function _swapETHToToken(
        uint256[] memory _percentage,
        address[] memory tokens
    ) public payable {
        uint256 fee = (msg.value).div(1000);
        uint256 _value = (msg.value).sub(fee);
        address[] memory path = new address[](2);
        uint256[] memory uniAmountsOut = new uint256[](2);
        address wethAddr = uniswap.WETH();
        uint256 amount = 0;
        address _instancePool;
        uint256 balancerPrice;
        uint256 balancerNum;

        for (uint256 i = 0; i < _percentage.length; i++) {
            amount = (_percentage[i].mul(_value)).div(100);
            path[1] = tokens[i];

            // Uniswap
            uniAmountsOut = uniswap.getAmountsOut(amount, path);
            // Balancer
            _instancePool = balancer.getBestPoolsWithLimit(
                wethAddr,
                path[1],
                1
            )[0];

            bPool = BPool(_instancePool);
            balancerPrice = bPool.getSpotPrice(wethAddr, path[1]);
            balancerNum = amount.div(balancerPrice);

            // Check which of the two DEX is better
            if (uniAmountsOut[1] <= balancerNum) {
                // Exchange ETH for token
                uniswap.swapExactETHForTokens{value: amount}(
                    uniAmountsOut[1],
                    path,
                    msg.sender,
                    block.timestamp
                );
            } else {
                // Wrapped Ether
                weth.deposit{value: amount}();
                weth.approve(_instancePool, amount);

                // Exchange WETH for token
                (uint256 tokenAmountOut, uint256 spotPriceAfter) = bPool
                    .swapExactAmountIn(
                        wethAddr,
                        amount,
                        path[1],
                        balancerNum,
                        balancerPrice.mul(11).div(10)
                    );

                IERC20(path[1]).transfer(msg.sender, tokenAmountOut);
            }
        }

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
        _;
    }
}
