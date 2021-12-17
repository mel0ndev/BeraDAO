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

    struct Account {
        uint userDepositBalance;
        uint lastClaimedRewards;
        bool hasCollateral;
        uint userShortID;
        mapping(uint => uint) userShortBalanceByID;
        mapping(uint => uint) entryPrices;
        mapping(uint => bool) isPositionInShort;
    }

    mapping(address => Account) public users;
    
    uint public globalRewards;

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

        //used for withdrawl later
        users[msg.sender].userDepositBalance += amount;

        //transfer DAI to this contract
        IERC20(collateral).transferFrom(msg.sender, address(this), amount);
    }

    function withdrawFromPool(uint amount, uint _userShortID) external {
        require(amount <= users[msg.sender].userDepositBalance,
            "COLLATERAL: trying to withdraw more collateral than deposited");

        //checking if the funds locked in the position have been released before allowing them to be withdrawn
        require(users[msg.sender].isPositionInShort[_userShortID] == false,
            "COLLATERAL: close your current position before trying to withdraw");

        //reset balance of user on withdraw
        users[msg.sender].userDepositBalance -= amount;
        //
        // if (userDepositBalance[msg.sender] == 0) {
        //     hasCollateral[msg.sender] = false;
        // }

        IERC20(DAI_ADDRESS).transfer(msg.sender, amount);
    }

    //used to claim the profit rewards from being in the pool
    function claimRewards() external {
        sendOwedProfits(msg.sender);
    }

    // deposit collateral into user account before being allowed to short
    function swapAndShortStandard(
            uint amount,
            address tokenToShort,
            uint24 poolFee, //needed for uniswap pool
            uint amountOutMin)
            external returns(uint amountOut) { //solhint-disable function-max-lines
                require(amount <= users[msg.sender].userDepositBalance, "SWAP: not enough collateral");

                //TODO
                //update userDepositBalance -= amount;

                //by default uints are initialized at 0 so this should work???
                users[msg.sender].userShortID += 1;

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
                //this stores the entry price of msg.sender for this specific shortID of msg.sender
                //nested mappings look cringe but are efficient
                users[msg.sender].entryPrices[users[msg.sender].userShortID] = priceAtWrap;

                //update userPositionNumber current short status
                // inShort[msg.sender][userShortID[msg.sender]] = true;
                users[msg.sender].isPositionInShort[users[msg.sender].userShortID] = true;

            }

    //TODO
    //contract already has the DAI needed to close the trade, can just check the price and
    //calculate the difference between the opening and closing prices, no need for expensive swaps
    //in the standardPool contract
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
            PnLCalculator.calculatePNL(users[msg.sender].entryPrices[_userShortID], priceAtClose);

            // //check if user has enough collateral and does not carry a negative balance
            // if (amountToSend <= userDepositBalance[msg.sender] && returnValue == 1) {
            //     //TODO
            //     //liquidateUser();
            //     //include distribution of funds
            // }

            //if user has made money, we update their balance directly
            if (returnValue == 0) {
                users[msg.sender].userDepositBalance += amountPNL;
            } else if (returnValue == 1) {
                //distribute user loss amongst pool if losing short
                users[msg.sender].userDepositBalance -= amountPNL;
                globalRewards += amountPNL;
            }

            //update current userPositionNumber to free withdraws of these specific funds
            // inShort[msg.sender][_userShortID] = false;
            users[msg.sender].isPositionInShort[_userShortID] = false;

        }

    function checkRewards() external view returns (uint profits) {
        return profits = checkOwedProfits(msg.sender);
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
        //this is used to keep track of how much of the users deposit is currently being used
        //userShortBalance[msg.sender][userShortID[msg.sender]] = amountOut;
        users[msg.sender].userShortBalanceByID[users[msg.sender].userShortID] = amountOut;

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
