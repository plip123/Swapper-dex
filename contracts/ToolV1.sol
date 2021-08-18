// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
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
     * @param _percentage Array containing the percentage of the tokens that need to be exchanged
     * @param tokens Array containing the address of the tokens to be exchanged for ETH
     */
    function swapETHToToken(
        uint256[] memory _percentage,
        address[] memory tokens
    ) public payable isValid(_percentage, tokens) {
        uint256 fee = (msg.value).div(1000);
        uint256 _value = (msg.value).sub(fee);
        uint256 amount = 0;
        address[] memory path = new address[](2);
        uint256[] memory amountsOut = new uint256[](2);

        path[0] = router.WETH();

        for (uint256 i = 0; i < _percentage.length; i++) {
            if (_percentage[i] > 0) {
                amount = (_percentage[i].mul(_value)).div(100);
                path[1] = tokens[i];

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
        require(amount > 0, "Not enough ETH");
        require(
            _percentage[0].add(_percentage[1]) <= 100 &&
                _percentage[0].add(_percentage[1]) > 0,
            "Invalid percentage"
        );
        uint256 fee = (amount).div(1000);
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

    /**
     * Modifier that checks if the function inputs are valid.
     * @param _percentage Array containing the percentage of the tokens that need to be exchanged
     * @param _address Array containing the address of the tokens to be exchanged for ETH
     */
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
