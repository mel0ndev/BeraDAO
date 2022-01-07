// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";


contract BeraSwapper {

    ISwapRouter public immutable swapRouter;

    constructor(ISwapRouter _swapRouter) {
        swapRouter = _swapRouter;
    }

    // amount here refers to how much of the token shorted is passed back into the swapRouter
    // used for both opening and closing positions
    function _swapShort(
        address user,
        address tokenToShort, //what token is shorted //opposite on close
        address tokenSupplied, //what token is supplied //opposite on close
        uint24 poolFee,
        uint amount,
        uint amountOutMin) external returns(uint amountOut) {

        TransferHelper.safeTransferFrom(tokenSupplied, user, address(this), amount);
        TransferHelper.safeApprove(tokenSupplied, address(swapRouter), amount);

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

    //PLACEHOLDER ---> TODO
    function _supplyShort(
        address user,
        address tokenSupplied,
        address associatedPool,
        uint amount) external {

        //transfer tokens to pool
        TransferHelper.safeTransferFrom(tokenSupplied, user, address(associatedPool), amount);
        TransferHelper.safeApprove(tokenSupplied, address(associatedPool), amount);

    }

}
