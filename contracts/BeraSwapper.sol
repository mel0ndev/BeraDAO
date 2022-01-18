// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; //solhint-disable compiler-fixed
pragma abicoder v2;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "./ancillary/IOracle.sol";
import "./ancillary/SwapOracle.sol";
import "./ancillary/Constants.sol";


contract BeraSwapper {

    IUniswapV2Router02 public immutable swapRouter;
    IOracle private immutable oracle;
    SwapOracle private immutable swapOracle;
    uint24 private constant DAI_FEE = 3000;
    address public immutable WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    ufixed8x2 private constant MAX_SLIPPAGE = 5 / 100; //max slippage for pool is 5%  

    constructor(IUniswapV2Router02 _swapRouter, IOracle _oracle, SwapOracle _swapOracle) {
        swapRouter = _swapRouter;
        oracle = _oracle;
        swapOracle = _swapOracle;
    }

    // amount here refers to how much of the token shorted is passed back into the swapRouter
    // used for both opening and closing positions
    function _swapShort(
        address user,
        address tokenIn,
        address tokenOut, //what token is shorted //opposite on close
        uint amount,
        uint amountOutMin) external {

        IERC20(tokenIn).transferFrom(user, address(this), amount);
        IERC20(tokenIn).approve(tokenIn, amount);

        if (tokenOut == swapRouter.WETH()) {
            address[] memory path = new address[](2);
            path[0] = tokenIn;
            path[1] = swapRouter.WETH();

        } else {
            address[] memory path = new address[](3);
            path[0] = tokenIn;
            path[1] = swapRouter.WETH();
            path[2] = tokenOut;

            //check for protocol max slippage tolerance
            (, uint amount2) = swapRouter.getAmountsOut(amount, path);
            require(amount2 >= amount * MAX_SLIPPAGE, "Exceeds max slippage");

            swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amount, amountOutMin, path, msg.sender, block.timestamp
            );

        }
    }

    //PLACEHOLDER ---> TODO
    function _supplyShort(
        address user,
        address tokenSupplied,
        uint24 fee,
        uint amount,
        address associatedPool) external returns (uint amountOut) {
        //transfer tokens to pool
        TransferHelper.safeTransferFrom(tokenSupplied, user, address(associatedPool), amount);

        uint tokenPrice = swapOracle.getSwapPrice(tokenSupplied, fee);
        amountOut = tokenPrice * amount;
    }

}
