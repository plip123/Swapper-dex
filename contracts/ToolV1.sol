// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./IRouter.sol";
import "hardhat/console.sol";

contract ToolV1 {
    using SafeMath for uint256;
    IRouter router;
    address recipientAddr;

    /**
     * Constructor
     * @param _recipient Address where fees will be sent
     */
    constructor(address _recipient) {
        router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        recipientAddr = _recipient;
    }

    /**
     * Exchanges from ETH to tokens
     * @param _percentage Array containing the percentage of the two tokens that need to be exchanged
     * @param token1 Address of the first token to be exchanged for ETH
     * @param token2 Address of the second token to be exchanged for ETH
     */
    function swapETHToToken(
        uint256[] memory _percentage,
        address token1,
        address token2
    ) public payable {
        require(msg.value > 0, "Not enough ETH");
        require(
            _percentage[0].add(_percentage[1]) <= 100 &&
                _percentage[0].add(_percentage[1]) > 0,
            "Invalid percentage"
        );

        uint256 fee = (msg.value).div(1000);
        uint256 _value = (msg.value).sub(fee);
        uint256 amount = 0;
        address[] memory path = new address[](2);
        uint256[] memory amountsOut = new uint256[](2);

        path[0] = address(router.WETH());

        if (_percentage[0] > 0) {
            amount = (_percentage[0].mul(_value)).div(100);
            path[1] = token1;

            amountsOut = router.getAmountsOut(amount, path);
            // weth.deposit{value: total}();
            // weth.approve(getInstancePool, total);

            // Exchange ETH for token1
            router.swapExactETHForTokens{value: amount}(
                amountsOut[1],
                path,
                msg.sender,
                block.timestamp
            );
        }

        if (_percentage[1] > 0) {
            path[1] = token2;
            amount = (_percentage[1].mul(_value)).div(100);

            amountsOut = router.getAmountsOut(amount, path);

            // Exchange ETH for token2
            router.swapExactETHForTokens{value: amount}(
                amountsOut[1],
                path,
                msg.sender,
                block.timestamp
            );
        }

        // Transfer fee to recipient
        payable(recipientAddr).transfer(fee);
    }

    /**
     * Exchanges from token to tokens
     * @param _percentage Array containing the percentage of the two tokens that need to be exchanged
     * @param tokenFrom Token to be exchanged
     * @param tokenTo1 Address of the first token to be exchanged for tokenFrom
     * @param tokenTo2 Address of the second token to be exchanged for tokenFrom
     * @param amount Amount of token to be exchanged
     */
    function swapTokenToToken(
        uint256[] memory _percentage,
        address tokenFrom,
        address tokenTo1,
        address tokenTo2,
        uint256 amount
    ) public payable {
        require(amount > 0, "Not enough Token");
        require(
            _percentage[0].add(_percentage[1]) <= 100,
            "Invalid percentage"
        );
        uint256 fee = (msg.value).div(1000);
        uint256 _value = (amount).sub(fee);
        amount = (_percentage[0].mul(_value)).div(100);
        address[] memory path = new address[](2);

        path[0] = tokenFrom;
        path[1] = tokenTo1;

        uint256[] memory amountsOut = router.getAmountsOut(amount, path);

        router.swapExactTokensForTokens(
            amountsOut[1],
            0,
            path,
            msg.sender,
            block.timestamp
        );

        path[1] = tokenTo2;
        amount = (_percentage[1].mul(_value)).div(100);

        amountsOut = router.getAmountsOut(amount, path);

        router.swapExactTokensForTokens(
            amountsOut[1],
            0,
            path,
            msg.sender,
            block.timestamp
        );

        //Transfer fee to recipient
        payable(recipientAddr).transfer(fee);
    }
}
