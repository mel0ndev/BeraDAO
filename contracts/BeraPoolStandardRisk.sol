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
    mapping(address => uint) public userDepositBalance;
    mapping(address => uint) internal userShortID;
    //nested mapping so multiple positions can be opened by the same user
    mapping(address => mapping(uint => uint)) public entryPrices;
    //stores which position is in a short for withdraw purposes later
    mapping(address => (mapping(uint => bool) internal inShort; //stores whether user is currently in a position
    address[] public standardPoolList;

    address private constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    ISwapRouter public immutable swapRouter;
    BeraWrapper public beraWrapper;

    constructor(ISwapRouter _swapRouter,
        BeraWrapper _beraWrapper) { //solhint-disable func-visibility
        owner = msg.sender;
        swapRouter = _swapRouter;
        beraWrapper = _beraWrapper;
    }

    function depositCollateral(uint amount, address collateral) external {
        require(IERC20(collateral) == IERC20(DAI_ADDRESS), "STANDARD POOL: Not DAI");

        //used for withdrawl later
        userDepositBalance[msg.sender] += amount;

        if (hasCollateral[msg.sender] == false) {
            standardPoolList.push(msg.sender);
            hasCollateral[msg.sender] = true;
        }

        //transfer to seperate pools based on user defined risk
        //high risk pool will keep 5% of the native token to try and maximize returns
        IERC20(collateral).transferFrom(msg.sender, address(this), amount);

    }

    function withdrawFromPool(uint amount) external {
        require(amount <= userDepositBalance[msg.sender],
            "COLLATERAL: trying to withdraw more collateral than deposited");
        require(inShort[msg.sender] == false,
            "COLLATERAL: close your current position before trying to withdraw");

        //reset balance of user on withdraw
        userDepositBalance[msg.sender] -= amount;

        if (userDepositBalance[msg.sender] <= 0) {
            hasCollateral[msg.sender] = false;
        }
        IERC20(DAI_ADDRESS).transfer(msg.sender, amount);
    }

    // deposit collateral into user account before being allowed to short
    function swapAndShortStandard(
            uint amount,
            address tokenToShort,
            uint24 poolFee, //needed for uniswap pool
            uint amountOutMin)
            external returns(uint amountOut) { //solhint-disable function-max-lines
                require(amount <= userDepositBalance[msg.sender], "SWAP: not enough collateral");

                //by default uints are initialized as 0 so this should work???
                userShortID[msg.sender] += 1;

                //keeping 5% of dai in contract to be distributed to liq providers on loss of pool
                uint amountToSend = amount * (95 / 100);

                TransferHelper.safeTransferFrom(DAI_ADDRESS, msg.sender, address(this), amount);
                TransferHelper.safeApprove(DAI_ADDRESS, address(swapRouter), amount);

                ISwapRouter.ExactInputSingleParams memory params =
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: DAI_ADDRESS,
                    tokenOut: tokenToShort,
                    fee: poolFee,
                    recipient: address(this),
                    deadline: block.timestamp, //solhint-disable not-rely-on-time
                    amountIn: amountToSend,
                    amountOutMinimum: amountOutMin,
                    sqrtPriceLimitX96: 0
                });

                //execute the frist swap
                amountOut = swapRouter.exactInputSingle(params);

                //Call twapPriceOracle here or find a better way to capture price
                //TODO: Price wrapping
                //TEST ONLY
                uint priceAtWrap = 3000;

                //execute the second swap and transfer funds to pool for holding
                //have to update priceAtWrap, users can set this amount manually and drain funds lmfao
                //will likely use TWAPOracle feature of uniV3 pools
                _shortForUser(
                    msg.sender,
                    tokenToShort,
                    priceAtWrap,
                    poolFee,
                    amountOut,
                    amountOutMin
                );

                //update entry price mapping
                //this refers to the entry price of msg.sender for the current shortID of msg.sender
                //nested mappings look cringe but are efficient
                entryPrices[msg.sender][userShortID[msg.sender]] = priceAtWrap;

                //update whether address is in a position or not
                inShort[msg.sender][userShortID[msg.sender]] = true;
            }

    function closeShortForUser(
        address user,
        address tokenToClose,
        uint amount,
        uint priceAtClose,
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
                recipient: msg.sender, //refers to router in this case
                deadline: block.timestamp, //solhint-disable not-rely-on-time
                amountIn: amount,
                amountOutMinimum: amountOutMin,
                sqrtPriceLimitX96: 0
            });

            //execute the sell order
            amountOut = swapRouter.exactInputSingle(tokenParams);

        }

    //TODO
    function _shortForUser(
        address user,
        address tokenToShort,
        uint priceAtWrap,
        uint24 poolFee,
        uint amount,
        uint amountOutMin) internal returns(uint amountOut) {

        //now that this contract has the desired token to short, we sell @ market back for DAI
        ISwapRouter.ExactInputSingleParams memory tokenParams =
        ISwapRouter.ExactInputSingleParams({
            tokenIn: tokenToShort,
            tokenOut: DAI_ADDRESS,
            fee: poolFee,
            recipient: address(this), //the pool contract will store both DAI from users and
            deadline: block.timestamp, //solhint-disable not-rely-on-time
            amountIn: amountToShort,
            amountOutMinimum: amountOutMin,
            sqrtPriceLimitX96: 0
        });

        // execute the short, amountOut is DAI in this case
        amountOut = swapRouter.exactInputSingle(tokenParams);

        //update user balances
        userShortBalance[msg.sender] = amountOut;

        //wrap position in ERC1155
        //use amountToShort to reference position size being wrapped
        beraWrapper.wrapPosition(user, address(this), amountToShort, tokenToShort, priceAtWrap);
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
