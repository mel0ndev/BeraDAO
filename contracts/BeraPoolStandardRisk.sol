// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; //solhint-disable compiler-fixed
pragma abicoder v2;


import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "./BeraWrapper.sol";
import "./ancillary/PnLCalculator.sol";
import "./ancillary/TWAPoracle.sol";
import "./ancillary/SwapOracle.sol";


contract BeraPoolStandardRisk is ERC1155Holder {

    address public owner;

    mapping(address => Account) public users;

    struct Liquidation {
        bool wasLiquidated;
        address liquidator;
    }

    struct Account {
        uint userDepositBalance;
        uint lastClaimedRewards;
        uint userShortID;
        mapping(uint => uint) entryPrice;
        mapping(uint => uint) userShortBalanceByID;
        mapping(uint => address) tokenShortedByPositionID;
        mapping(uint => uint24) poolFeeByPositionID;
        mapping(uint => bool) isPositionInShort;
        mapping(uint => Liquidation) liqData;
    }

    uint public globalRewards;

    address private constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    ISwapRouter public immutable swapRouter;
    BeraWrapper public beraWrapper;
    TWAPOracle public twapOracle;
    SwapOracle public swapOracle;

    constructor(ISwapRouter _swapRouter,
        BeraWrapper _beraWrapper,
        TWAPOracle _twapOracle,
        SwapOracle _swapOracle) { //solhint-disable func-visibility
        owner = msg.sender;
        swapRouter = _swapRouter;
        beraWrapper = _beraWrapper;
        twapOracle = _twapOracle;
        swapOracle = _swapOracle;
    }

    function depositCollateral(uint amount, address collateral) external {
        require(IERC20(collateral) == IERC20(DAI_ADDRESS), "STANDARD POOL: Not DAI");

        //used for withdrawl later
        users[msg.sender].userDepositBalance += amount;

        //transfer DAI to this contract
        IERC20(collateral).transferFrom(msg.sender, address(this), amount);
    }

    function withdrawFromPool(uint amount, uint userShortID) external {
        require(amount <= users[msg.sender].userDepositBalance,
            "COLLATERAL: trying to withdraw more collateral than deposited");

        //checking if the funds locked in the position have been released before allowing them to be withdrawn
        require(getUserShortBool(msg.sender, userShortID) == false,
            "COLLATERAL: close your current position before trying to withdraw");

        //reset balance of user on withdraw
        users[msg.sender].userDepositBalance -= amount;

        IERC20(DAI_ADDRESS).transfer(msg.sender, amount);
    }

    //used to claim the profit rewards from collecting trader losses in this pool
    function claimRewards() external {
        sendOwedProfits(msg.sender);
    }

    // deposit collateral into user account before being allowed to short
    // amount refers to how much dai to swap for amountOut of the token the user
    // wants to short
    //
    // will likely have to split the logic for the function up, she's getting pretty chonky
    function swapAndShortStandard(
            uint amount,
            address tokenToShort,
            uint24 poolFee, //needed for uniswap pool
            uint amountOutMin)
            external returns(uint amountOut) { //solhint-disable function-max-lines
                require(amount <= users[msg.sender].userDepositBalance, "SWAP: not enough collateral");

                //by default uints are initialized at 0 so this should work???
                users[msg.sender].userShortID += 1;

                //get total amount of collateral in shorts if user has opened a position before
                if (getTotalCollateral(msg.sender) > 0) {
                    require(getTotalCollateral(msg.sender) <= users[msg.sender].userDepositBalance,
                        "SWAP: not enough collateral");
                }

                //5% is kept as fee to protocol to assist in paying out users
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

                //get TWAP price (3 min)
                //destructure pool request
                uint priceAtWrap =
                    swapOracle.getSwapPrice(
                        tokenToShort,
                        poolFee
                    );

                //execute the second swap and transfer funds to pool for holding
                //this is the swap that creates the actual 'short' position for the user on-chain
                _shortForUser(
                    msg.sender,
                    tokenToShort,
                    priceAtWrap,
                    poolFee,
                    amountOut,
                    amountOutMin
                );

                //TODO REFACTOR: can update user data in one internal function // maybe //

                //update entry price mapping
                //this stores the entry price of msg.sender for this specific shortID of the sender
                //nested mappings look cringe but are efficient
                users[msg.sender].entryPrice[users[msg.sender].userShortID] = priceAtWrap;

                //update user balance of the user current positionID
                //this is used to keep track of how much of the users deposit is currently being used
                users[msg.sender].userShortBalanceByID[users[msg.sender].userShortID] = amountOut;

                //update userPositionNumber current short status
                // inShort[msg.sender][userShortID[msg.sender]] = true;
                users[msg.sender].isPositionInShort[users[msg.sender].userShortID] = true;

                users[msg.sender].tokenShortedByPositionID[users[msg.sender].userShortID] = tokenToShort;
            }

    // if you are reading this comment, this is a way for you to make some money
    // and keep the protocol alive and kicking
    // keep in mind that you need to have deposited collateral to receive rewards
    function liquidateUser(address userUnderwater, address liquidator, uint shortID) external {
        //get entry price by shortID and subtract by current price
        (address token, uint24 fee) = getTokenAndFeeShortedByUser(userUnderwater, shortID);
        uint currentPrice = swapOracle.getSwapPrice(
                token,
                fee
            );
        uint drawdown = getUserEntryPrice(userUnderwater, shortID) - currentPrice;
        //give the users a 5% buffer on their deposit amount before they can be liquidated
        uint buffer = users[userUnderwater].userDepositBalance * 5 / 100;
        require(drawdown + buffer > users[userUnderwater].userDepositBalance, "LIQ: Account not in drawdown");
        require(getUserShortBool(userUnderwater, shortID) == true, "LIQ: Position not active");

        users[userUnderwater].liqData[shortID].wasLiquidated = true;
        users[userUnderwater].liqData[shortID].liquidator = liquidator;

        closeShortStandardPool(userUnderwater, shortID);
    }

    function getLiquidator(address user, uint shortID) public view returns(address liquidator) {
        return users[user].liqData[shortID].liquidator;
    }

    function getTotalCollateral(address user) public view returns(uint totalCollateral) {
        for (uint i = 0; i <= users[user].userShortID; i++) {
            totalCollateral += users[user].userShortBalanceByID[i];
        }
        return (totalCollateral);
    }

    function checkRewards(address user) public view returns(uint profits) {
        return profits = checkOwedProfits(user);
    }

    function getGlobalRewards() public view returns(uint globals) {
        return globals = globalRewards;
    }

    function getUserShortBalance(address user, uint shortID) public view returns(uint bal) {
        return bal = users[user].userShortBalanceByID[shortID];
    }

    function getUserEntryPrice(address user, uint shortID) public view returns(uint entry) {
        return entry = users[user].entryPrice[shortID];
    }

    function getUserShortBool(address user, uint shortID) public view returns(bool isShort) {
        return isShort = users[user].isPositionInShort[shortID];
    }

    function getTokenAndFeeShortedByUser(address user, uint shortID) public view returns(address token, uint24 fee) {
        token = users[user].tokenShortedByPositionID[shortID];
        fee = uint24(users[user].poolFeeByPositionID[shortID]);
        return (token, fee);
    }

    //TODO
    //contract already has the DAI needed to close the trade, can just check the price and
    //calculate the difference between the opening and closing prices, no need for expensive swaps
    //in the standardPool contract
    function closeShortStandardPool(
        address user,
        uint userShortID)
        public {
            require(user == msg.sender, "CLOSE: Not your position");

            //get price at pool for shortBal of positionID
            (address token, uint24 fee) = getTokenAndFeeShortedByUser(user, userShortID);
            uint priceAtClose = swapOracle.getSwapPrice(
                    token,
                    fee
                );

            beraWrapper.unwrapPosition(user, userShortID);

            //calculate position balance using entryPrice - current price * tradeSize
            //returnValue of 0 indicates a winning trade, while 1 indicates a loss
            (uint amountPNL, uint returnValue) =
            PnLCalculator.calculatePNL(users[msg.sender].entryPrice[userShortID],
                priceAtClose,
                int(users[user].userShortBalanceByID[userShortID]));

            //if user has made money, we update their balance directly
            //keeping in mind that dai is always stored in this contract and will only be transfered
            //out on withdrawl
            if (returnValue == 0) {
                users[msg.sender].userDepositBalance += amountPNL;
            } else if (returnValue == 1) {
                users[msg.sender].userDepositBalance -= amountPNL;
                //experimental liquidation logic //kinda dogshit ngl
                if (users[user].liqData[userShortID].wasLiquidated == true) {
                    uint newPNL = amountPNL * 50 / 100;
                    uint toLiquidator = amountPNL - newPNL;
                    address liquidator = getLiquidator(user, userShortID);
                    users[liquidator].userDepositBalance += toLiquidator;
                    globalRewards += newPNL;
                } else {
                    //distribute loss amongst users in pool
                    globalRewards += amountPNL;
                }
            }

            //update current userPositionNumber to free withdraws of these specific funds
            //v0.5 does not support anything other than full position closing
            users[msg.sender].isPositionInShort[userShortID] = false;
            users[msg.sender].userShortBalanceByID[userShortID] = 0;
        }

    // amount here refers to how much of the token shorted is passed back into the swapRouter
    function _shortForUser(
        address user,
        address tokenToShort,
        uint priceAtWrap,
        uint24 poolFee,
        uint amount,
        uint amountOutMin) internal returns(uint amountOut) {

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

        // execute the short, amountOut is now back to dai
        amountOut = swapRouter.exactInputSingle(tokenParams);

        //wrap position in ERC1155
        beraWrapper.wrapPosition(user, address(this), amount, tokenToShort, priceAtWrap);
    }

    //the percentage reward is based on the last time they claimed vs the total reward calculated
    //this will allow us to avoid using a loop for reward distribution
    //and allow users to pull their own rewards when they want
    function checkOwedProfits(address user) internal view returns (uint) {
        uint percentageReward = globalRewards - users[user].lastClaimedRewards;
        return users[user].userDepositBalance * percentageReward / IERC20(DAI_ADDRESS).balanceOf(address(this));
    }

    function sendOwedProfits(address user) internal {
        uint owed = checkOwedProfits(user);
        if (owed > 0) {
            users[user].userDepositBalance += owed;
            users[user].lastClaimedRewards = globalRewards;
        }
    }

    receive() external payable { //solhint-disable state-visibility

}

    fallback() external payable { //solhint-disable

}

}
