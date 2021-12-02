// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; //solhint-disable compiler-fixed
pragma abicoder v2;


//THIS CONTRACT IS GOING TO GET NUKED. MOVE LOGIC TO POOL CONTRACTS
//USING INTERNAL FUNCTIONS FOR CHECKS

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "./BeraPoolStandardRisk.sol";
import "./BeraWrapper.sol";


//the public interface for the protocol
contract BeraRouter {

    mapping(address => uint) public userCollateralBalance;
    mapping(address => bool) internal hasCollateral;
    mapping(address => uint) public entryPrice;
    mapping(address => bool) public inShort;
    address[] public poolList;

    address private constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    //uniswapV3 address router
    //might have to change if implement 1inch api
    ISwapRouter public  swapRouter;
    BeraPoolStandardRisk public beraPoolStandardRisk;
    BeraWrapper public beraWrapper;

    address public owner;

    constructor(ISwapRouter _swapRouter,
        BeraPoolStandardRisk _beraPoolStandardRisk,
        BeraWrapper _beraWrapper) { //solhint-disable func-visibility
        owner = msg.sender;
        swapRouter = _swapRouter;
        beraPoolStandardRisk = _beraPoolStandardRisk;
        beraWrapper = _beraWrapper;
    }

    function withdrawCollateral(uint amount) external {
        require(amount <= userCollateralBalance[msg.sender],
            "COLLATERAL: trying to withdraw more collateral than deposited");
        require(inShort[msg.sender] == false,
            "COLLATERAL: close your current position before trying to withdraw");

        //reset balance of user on withdraw
        userCollateralBalance[msg.sender] -= amount;

        if (userCollateralBalance[msg.sender] <= 0) {
            hasCollateral[msg.sender] = false;
        }

    }

    // deposit collateral into user account before being allowed to short
    function swapAndShortStandard(
            uint amount,
            address tokenToShort,
            uint24 poolFee, //needed for uniswap pool
            uint amountOutMin,
            uint collateralPercentageOfAccount,
            uint priceAtWrap)
            external returns(uint amountOut) { //solhint-disable function-max-lines
                require(amount <= userCollateralBalance[msg.sender], "SWAP: not enough collateral");
                require(collateralPercentageOfAccount <= 100, "SWAP: cannot use more than 100% of account to short");

                //TODO for refactor
                //could reuse this code to get rid of collat percentage idea and instead use it to keep 5% of dai
                uint amountOfCollateral = amount * collateralPercentageOfAccount / 100;
                uint leftover = amount - amountOfCollateral;

                TransferHelper.safeTransferFrom(DAI_ADDRESS, msg.sender, address(this), amount);
                TransferHelper.safeApprove(DAI_ADDRESS, address(swapRouter), amount);

                ISwapRouter.ExactInputSingleParams memory params =
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: DAI_ADDRESS,
                    tokenOut: tokenToShort,
                    fee: poolFee,
                    recipient: msg.sender, //send back to user to execute next leg
                    deadline: block.timestamp, //solhint-disable not-rely-on-time
                    amountIn: amountOfCollateral,
                    amountOutMinimum: amountOutMin,
                    sqrtPriceLimitX96: 0
                });

                // execute the frist swap & sends to beraPoolSR based on params
                amountOut = swapRouter.exactInputSingle(params);

                //execute the second swap and transfer funds to pool for holding
                //have to update priceAtWrap, users can set this amount manually and drain funds lmfao
                //will likely use TWAPOracle feature of uniV3 pools
                // beraPoolStandardRisk.shortForUser(
                //     msg.sender,
                //     tokenToShort,
                //     priceAtWrap,
                //     poolFee,
                //     amountOut,
                //     amountOutMin
                // );

                //update entry price mapping
                entryPrice[msg.sender] = priceAtWrap;

                //update whether address is in a position or not
                inShort[msg.sender] = true;

                //send remaining funds back to user
                if (leftover > 0) {
                    IERC20(DAI_ADDRESS).transfer(msg.sender, leftover);
                }
            }

    function swapAndCloseShort(
        address user,
        address tokenToClose,
        uint amount,
        uint priceAtClose,
        uint24 poolFee,
        uint amountOutMin,
        uint _positionID) external returns(uint amountOut) {
        //unwrap and unlock position
        beraWrapper.unwrapPosition(user, _positionID);

        //send dai back to user
        //needs check for amount
        IERC20(DAI_ADDRESS).transfer(msg.sender, amount);

        //we swap dai back to weth to close the trade
        TransferHelper.safeTransferFrom(DAI_ADDRESS, msg.sender, address(this), amount);
        TransferHelper.safeApprove(DAI_ADDRESS, address(swapRouter), amount);

        ISwapRouter.ExactInputSingleParams memory params =
        ISwapRouter.ExactInputSingleParams({
            tokenIn: DAI_ADDRESS,
            tokenOut: tokenToClose,
            fee: poolFee,
            recipient: msg.sender, //send tokens to user to execute next leg of trade
            deadline: block.timestamp, //solhint-disable not-rely-on-time
            amountIn: amount,
            amountOutMinimum: amountOutMin,
            sqrtPriceLimitX96: 0
        });

        //execute swap
        amountOut = swapRouter.exactInputSingle(params);

        //sell tokens back for DAI
        // beraPoolStandardRisk.closeShortForUser(
        //     msg.sender,
        //     tokenToClose,
        //     amountOut, //how much tokenOut is being sent to swap back into dai (in this case weth)
        //     priceAtClose,
        //     poolFee,
        //     amountOutMin
        // );

        //calculate if the user made or lost money on the position
        //also tranfers the profits to the user and distributes user losses amongst the pool
        calculatePNL(msg.sender, priceAtClose);

        //reset user short status
        inShort[msg.sender] = false; //solhint-disable reentrancy
    }

    function distributeProfits(uint amountToDistribute) internal {
        for (uint i = 0; i < poolList.length; i++) {
            //update user collateral instead?
            uint userPercent = (userCollateralBalance[poolList[i]] / IERC20(DAI_ADDRESS).balanceOf(address(this)));
            //percentage will be out of 100 i.e 0.3% = 30 or < 30/100 >
            uint percentToSendToUsers = userPercent * amountToDistribute;
            userCollateralBalance[poolList[i]] += percentToSendToUsers;
        }
    }

    function calculatePNL(address user, uint priceAtClose) internal {
        int difference = int(entryPrice[user]) - int(priceAtClose);
        if (difference > 0) {
            //IERC20(DAI_ADDRESS).transfer(user, uint(difference)); //case where user makes money
            userCollateralBalance[user] += (uint(difference) * 1e18);
        } else {
            int loss = int(entryPrice[user]) - int(priceAtClose); //case where user loses money
            //make negative num postive
            int userLoss = (loss * (-1));
            require(uint(userLoss) <= userCollateralBalance[user],
                "PNL: loss exceeds user balance, liquidation function will be called");
            uint amountToDistribute = uint(userLoss) - userCollateralBalance[user];

            //distribute remaining amongst pool holders
            distributeProfits(amountToDistribute);

            //update user collateral balance to reflect loss
            //in this case it would be whoever is closing their short position
            userCollateralBalance[user] -= uint(userLoss);
        }
    }






}
