// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; //solhint-disable compiler-fixed
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./BeraWrapper.sol";


contract BeraPoolStandardRisk is ERC1155Holder {

    address public owner;

    mapping(address => uint) public userShortBalance;
    mapping(address => uint) public userRemainingBalance;

    address private constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    ISwapRouter public immutable swapRouter;
    BeraWrapper public beraWrapper;

    constructor(ISwapRouter _swapRouter,
        BeraWrapper _beraWrapper) { //solhint-disable func-visibility
        owner = msg.sender;
        swapRouter = _swapRouter;
        beraWrapper = _beraWrapper;
    }

    function shortForUser(
        address user,
        address tokenToShort,
        uint priceAtWrap,
        uint24 poolFee,
        uint amount,
        uint amountOutMin) external returns(uint amountOut) {
        //require(msg.sender == beraRouter, "not in ecosystem");


        TransferHelper.safeTransferFrom(tokenToShort, user, address(this), amount);
        TransferHelper.safeApprove(tokenToShort, address(swapRouter), amount);

        //keep 5% of weth in pool contract for holders to profit/ reduce losses
        //amountToShort is amount of weth to short
        //TOKEN IN IN THIS CASE IS ALREADY TOKEN TO BE SHORTED, SO POOL IS KEEPING 5% OF TRADE
        //KEEP IN FOR NOW TO TEST HIGH RISK POOL
        //WILL HAVE TO CHANGE TO SWAP AND THEN KEEP 5% FOR STANDARD RISK POOL
        uint amountToShort = (amount * 95) / 100;
        uint remaining = amount - amountToShort;

        //now that contract has the desired token to short, we sell @ market back for DAI
        ISwapRouter.ExactInputSingleParams memory tokenParams =
        ISwapRouter.ExactInputSingleParams({
            tokenIn: tokenToShort,
            tokenOut: DAI_ADDRESS,
            fee: poolFee,
            recipient: address(this),
            deadline: block.timestamp, //solhint-disable not-rely-on-time
            amountIn: amountToShort,
            amountOutMinimum: amountOutMin,
            sqrtPriceLimitX96: 0
        });

        // execute the short, amountOut is DAI in this case
        amountOut = swapRouter.exactInputSingle(tokenParams);

        //update user balances
        userShortBalance[msg.sender] = amountOut;
        userRemainingBalance[msg.sender] = remaining;

        //wrap position in ERC1155
        //use amountToShort to reference how much is being shorted in this position
        beraWrapper.wrapPosition(user, address(this), amountToShort, tokenToShort, priceAtWrap);

    }

    function closeShortForUser(
        address pool,
        address tokenToClose,
        uint amount,
      //  uint priceAtClose,
        uint24 poolFee,
        uint amountOutMin)
        external returns(uint amountOut) {

            //transfer weth to contract to sell back to dai and send profits to user
            TransferHelper.safeTransferFrom(tokenToClose, user, address(this), amount);
            TransferHelper.safeApprove(tokenToClose, address(swapRouter), amount);

            ISwapRouter.ExactInputSingleParams memory tokenParams =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: tokenToClose,
                tokenOut: DAI_ADDRESS,
                fee: poolFee,
                recipient: pool, //refers to pool that will hold tokens on behalf of the user before disribution 
                deadline: block.timestamp, //solhint-disable not-rely-on-time
                amountIn: amount,
                amountOutMinimum: amountOutMin,
                sqrtPriceLimitX96: 0
            });

            //execute the sell order
            amountOut = swapRouter.exactInputSingle(tokenParams);

            //calculate and transfer profits
            //IERC20(tokenToClose).transfer(user, profits);
        }
}

//needs:
//
//total borrowed from pool/ token0
//total supplied to pool as collateral/ token1(USDC)
//total available to borrow for shorting
//how much it will cost to borrow/ how much to be paid to supplier
//when does the borrower threaten to be liquited?
    //(when losses are equal to 90% of supplied collateral)
    //thus, we need a way to measure the current borrowers PnL or loan health (maybe look at AAVE or COMP)
//need interface when done with all functions

//ON HOLD
