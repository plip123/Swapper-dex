// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/IRouter.sol";
import "./interfaces/Balancer/BPool.sol";
import "./interfaces/Balancer/IRegistry.sol";
import "./interfaces/IWeth9.sol";

contract ToolV2 is Initializable {
    using SafeMath for uint256;
    IRouter router;
    address recipientAddr;
    IRegistry balancer;
    BPool bPool;
    WETH9 weth;

    function _swapETHToToken(
        uint256[] memory _percentage,
        address[] memory tokens
    ) public payable isValid(_percentage, tokens) {
        address[] memory path = new address[](2);
        uint256[] memory uniAmountsOut = new uint256[](2);
        uint256 amount = 0;
        address _instancePool;
        uint256 balancerPrice;
        uint256 balancerNum;
        path[0] = router.WETH();
        balancer = IRegistry(0x7226DaaF09B3972320Db05f5aB81FF38417Dd687);
        weth = WETH9(router.WETH());

        for (uint256 i = 0; i < _percentage.length; i++) {
            amount = (
                _percentage[i].mul((msg.value).sub((msg.value).div(1000)))
            ).div(100);
            path[1] = tokens[i];

            // Uniswap
            uniAmountsOut = router.getAmountsOut(amount, path);
            // Balancer
            _instancePool = balancer.getBestPoolsWithLimit(
                router.WETH(),
                path[1],
                1
            )[0];

            bPool = BPool(_instancePool);
            balancerPrice = bPool.getSpotPrice(router.WETH(), path[1]);
            balancerNum = amount.div(balancerPrice);

            // Check which of the two DEX is better
            if (uniAmountsOut[1] >= balancerNum) {
                // Exchange ETH for token
                router.swapExactETHForTokens{value: amount}(
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
                (uint256 tokenAmountOut, ) = bPool.swapExactAmountIn(
                    router.WETH(),
                    amount,
                    path[1],
                    balancerNum,
                    balancerPrice.mul(11).div(10)
                );

                IERC20(path[1]).transfer(msg.sender, tokenAmountOut);
            }
        }

        // Transfer fee to recipient
        payable(recipientAddr).transfer((msg.value).div(1000));
    }

    modifier isValid(uint256[] memory _percentage, address[] memory _address) {
        require(msg.value > 0, "Not enough ETH");
        require(_percentage.length == _address.length, "Data don't match");

        uint256 max = 0;

        for (uint256 i = 0; i < _percentage.length; i++) {
            max = max.add(_percentage[i]);
        }

        require(max == 100, "Invalid percentage");
        _;
    }
}
