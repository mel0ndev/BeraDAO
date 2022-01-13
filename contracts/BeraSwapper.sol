// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "./ancillary/IOracle.sol";


contract BeraSwapper {

    ISwapRouter public immutable swapRouter;
    IOracle public oracle;
    address private constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint24 private constant DAI_FEE = 3000;

    constructor(ISwapRouter _swapRouter, IOracle _oracle) {
        swapRouter = _swapRouter;
        oracle = _oracle;
    }

    // amount here refers to how much of the token shorted is passed back into the swapRouter
    // used for both opening and closing positions
    function _swapShort(
        address user,
        address tokenToShort, //what token is shorted //opposite on close
        address tokenSupplied, //dai on open //opposite on close
        uint24 poolFee,
        uint amount,
        uint amountOutMin) external returns(uint amountOut) {

        TransferHelper.safeTransferFrom(tokenSupplied, user, address(this), amount);
        TransferHelper.safeApprove(tokenSupplied, address(swapRouter), amount);

        (, uint8 returnValue) = oracle.getPoolForTWAP(tokenToShort, poolFee);
        if (returnValue == 1) {

            ISwapRouter.ExactInputParams memory multiParams =
            ISwapRouter.ExactInputParams({
                path: abi.encodePacked(tokenSupplied, DAI_FEE, WETH_ADDRESS, poolFee, tokenToShort),
                recipient: msg.sender,
                deadline: block.timestamp, //solhint-disable not-rely-on-time
                amountIn: amount,
                amountOutMinimum: amountOutMin
            });

            // Executes the swap.
            amountOut = swapRouter.exactInput(multiParams);
          //don't judge me for using else it is readable >:(
        } else {

            ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: tokenSupplied,
                tokenOut: tokenToShort,
                fee: poolFee,
                recipient: msg.sender, //refers to pool that calls function
                deadline: block.timestamp, //solhint-disable not-rely-on-time
                amountIn: amount, //amountToSend
                amountOutMinimum: amountOutMin, //used to check price
                sqrtPriceLimitX96: 0
            });

            //execute the swap
            amountOut = swapRouter.exactInputSingle(params);
        }
    }

    //PLACEHOLDER ---> TODO
    function _supplyShort(
        address user,
        address tokenSupplied,
        uint amount,
        address associatedPool) external {
        //transfer tokens to pool
        TransferHelper.safeTransferFrom(tokenSupplied, user, address(associatedPool), amount);
        TransferHelper.safeApprove(tokenSupplied, address(associatedPool), amount);

    }

}
