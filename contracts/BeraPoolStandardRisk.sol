// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; //solhint-disable compiler-fixed
pragma abicoder v2;


import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./BeraWrapper.sol";
import "./ancillary/PnLCalculator.sol";


contract BeraPoolStandardRisk is ERC1155Holder {

    address public owner;

    uint public testNumber;
    uint public testPNL;

    mapping(address => uint) public userDepositBalance;
    mapping(address => mapping(uint => uint)) public userShortBalance;
    mapping(address => uint) internal userShortID;
    mapping(address => bool) internal hasCollateral;
    //nested mapping so multiple positions can be opened by the same user
    mapping(address => mapping(uint => uint)) public entryPrices;
    //stores which position is in a short for withdraw purposes later
    mapping(address => mapping(uint => bool)) internal inShort; //stores whether user is currently in a position
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

        //we use the hasCollateral mapping to avoid having to loop through the array when removing
        //the user from the users who receive the distribution of funds for yield
        if (userDepositBalance[msg.sender] > 0) {
            standardPoolList.push(msg.sender);
            hasCollateral[msg.sender] = true;
        }

        //used for withdrawl later
        userDepositBalance[msg.sender] += amount;

        //transfer DAI to this contract
        IERC20(collateral).transferFrom(msg.sender, address(this), amount);
    }

    function withdrawFromPool(uint amount, uint _userShortID) external {
        require(amount <= userDepositBalance[msg.sender],
            "COLLATERAL: trying to withdraw more collateral than deposited");

        //checking if the funds locked in the position have been released before allowing them to be withdrawn
        require(inShort[msg.sender][_userShortID] == false,
            "COLLATERAL: close your current position before trying to withdraw");

        //reset balance of user on withdraw
        userDepositBalance[msg.sender] -= amount;

        if (userDepositBalance[msg.sender] == 0) {
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

                //TODO
                //update userDepositBalance -= amount;

                //by default uints are initialized at 0 so this should work???
                userShortID[msg.sender] += 1;

                //keeping 5% of dai in contract to be distributed to liq providers on loss of pool
                uint amountToSend = amount * 95 / 100;

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

                //update userPositionNumber current short status
                inShort[msg.sender][userShortID[msg.sender]] = true;
            }

    //TODO
    //contract already has the DAI needed to close the trade, can just check the price and
    //calculate the difference between the opening and closing prices, no need for expensive swaps
    //in the standardPool contract anyways
    function closeShortStandardPool(
        address user,
        uint _userShortID,
        uint priceAtClose)
        external {
            require(user == msg.sender, "CLOSE: Not your position");

            //TODO
            //require priceAtClose == twapPriceOracle();

            //calculate position balance using entryPrices vs current price
            //returnValue of 0 indicates a winning trade, while 1 indicates a loss
            (uint amountPNL, uint returnValue) =
            PnLCalculator.calculatePNL(entryPrices[msg.sender][_userShortID], priceAtClose);

            // //check if user has enough collateral and does not carry a negative balance
            // if (amountToSend <= userDepositBalance[msg.sender] && returnValue == 1) {
            //     //TODO
            //     //liquidateUser();
            //     //include distribution of funds
            // }

            //if user has made money, we update their balance directly
            if (returnValue == 0) {
                userDepositBalance[msg.sender] += amountPNL;
            } else if (returnValue == 1) {
                //distribute user loss amongst pool if losing short
                userDepositBalance[msg.sender] -= amountPNL;
                distributeProfits(amountPNL);
            }

            //update current userPositionNumber to free withdraws
            inShort[msg.sender][_userShortID] = false;

        }

    function _shortForUser(
        address user,
        address tokenToShort,
        uint priceAtWrap,
        uint24 poolFee,
        uint amount,
        uint amountOutMin) internal returns(uint amountOut) {
        //funds are currently in the contract, so no need to swap back and forth anymore
        //should just be able to call the second swap

        TransferHelper.safeApprove(tokenToShort, address(swapRouter), amount);

        //now that this contract has the desired token to short, we sell @ market back for DAI
        ISwapRouter.ExactInputSingleParams memory tokenParams =
        ISwapRouter.ExactInputSingleParams({
            tokenIn: tokenToShort,
            tokenOut: DAI_ADDRESS,
            fee: poolFee,
            recipient: address(this), //the pool contract will store both DAI from deposits and tokenOut
            deadline: block.timestamp, //solhint-disable not-rely-on-time
            amountIn: amount,
            amountOutMinimum: amountOutMin,
            sqrtPriceLimitX96: 0
        });

        // execute the short, amountOut is wETH in this test case
        amountOut = swapRouter.exactInputSingle(tokenParams);

        //update user balance of the user current positionID
        userShortBalance[msg.sender][userShortID[msg.sender]] = amountOut;

        //wrap position in ERC1155
        //use amountToShort to reference position size being wrapped
        beraWrapper.wrapPosition(user, address(this), amount, tokenToShort, priceAtWrap);
    }

    function distributeProfits(uint amountToDistribute) internal {
        for (uint i = 0; i < standardPoolList.length; i++) {
            //get each user's percentage of the pool they own
            //dai related to current positions are not counted*******
            uint userPercent =
                userDepositBalance[standardPoolList[i]] * 1e18 / IERC20(DAI_ADDRESS).balanceOf(address(this));
            uint percentToSendToUsers = userPercent * amountToDistribute;
            //update each users deposit balance to increase the amount they can withdraw
            //(rather than sending funds directly which would be quite expensive)
            //balances are stored
            userDepositBalance[standardPoolList[i]] += percentToSendToUsers;
        }
    }

    receive() external payable { //solhint-disable state-visibility

}

    fallback() external payable { //solhint-disable

}

}
