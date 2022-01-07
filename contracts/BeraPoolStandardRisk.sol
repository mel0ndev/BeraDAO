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
import "./BeraSwapper.sol";
import "./ancillary/PnLCalculator.sol";
import "./ancillary/SwapOracle.sol";


contract BeraPoolStandardRisk is ERC1155Holder {

    address public owner;
    uint public protocolOwnedLiquidity;

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
        mapping(uint => uint) tokenAmountByPositionID;
        mapping(uint => uint24) poolFeeByPositionID;
        mapping(uint => bool) isPositionInShort;
        mapping(uint => Liquidation) liqData;
    }

    uint public globalRewards;

    address private constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    ISwapRouter public immutable swapRouter;
    BeraWrapper public beraWrapper;
    BeraSwapper public beraSwapper;
    SwapOracle public swapOracle;

    constructor(ISwapRouter _swapRouter,
        BeraWrapper _beraWrapper,
        TWAPOracle _twapOracle,
        SwapOracle _swapOracle,
        BeraSwapper _beraSwapper) { //solhint-disable func-visibility
        owner = msg.sender;
        swapRouter = _swapRouter;
        beraWrapper = _beraWrapper;
        beraSwapper = _beraSwapper;
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
    function swapShort(
            uint amount,
            address tokenToShort,
            uint24 poolFee, //needed for uniswap pool
            uint amountOutMin)
            external { //solhint-disable function-max-lines
                require(amount <= users[msg.sender].userDepositBalance, "SWAP: not enough collateral");
                require(poolFee == 3000 || poolFee == 500, "SWAP: Not high risk pool");

                users[msg.sender].userShortID += 1;
                //get total amount of collateral in shorts if user has opened a position before
                if (getTotalCollateral(msg.sender) > 0) {
                    require(getTotalCollateral(msg.sender) <= users[msg.sender].userDepositBalance,
                        "SWAP: not enough collateral");
                }

                //1% is kept as fee to protocol to assist in paying out users
                uint amountToSend = amount * 99 / 100;
                //update global so we know how much of deposited amount belongs to users vs protocol
                protocolOwnedLiquidity += amount - amountToSend;

                //execute swapShort via swapper contract
                uint amountOut = beraSwapper._swapShort(
                    msg.sender,
                    tokenToShort,
                    DAI_ADDRESS,
                    poolFee,
                    amountToSend,
                    amountOutMin
                );

                //get TWAP price (3 min) to wrap position
                uint priceAtWrap = swapOracle.getSwapPrice(tokenToShort, poolFee);
                beraWrapper.wrapPosition(
                    address(this), // the associated pool
                    amountOut,  // the amount of token shorted
                    tokenToShort, // what token was shorted
                    priceAtWrap // the price of 1 token0 in dai
                );

                //update Account details
                updateUserMappings(
                    msg.sender, // the user
                    users[msg.sender].userShortID, //the position ID
                    priceAtWrap, // the entry price
                    amountToSend, // how much of the users collateral has been used in this position
                    tokenToShort,
                    amountOut, // amount of token the contract is storing for the user AKA size of short denom in token
                    poolFee
                );

                //now we transfer dai to user and hold their tokens for them
                uint amountToReturn = amountOut * priceAtWrap;
                IERC20(DAI_ADDRESS).transfer(msg.sender, amountToReturn);
            }

    // if you are reading this comment, this is a way for you to make some money
    // and keep the protocol alive and kicking
    // keep in mind that you need to have deposited collateral to receive rewards
    function liquidateUser(address userUnderwater, address liquidator, uint shortID) external {
        //get entry price by shortID and subtract by current price
        (address token, uint24 fee) = getTokenAndFeeShortedByUser(userUnderwater, shortID);
        //REDO
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
    function closeSwapShort(
        address user, //we pass in a user instead of msg.sender in the case of liquidation
        uint userShortID,
        uint amountOutMin)
        public {
            //check again how ERC1155 do balances
            require(beraWrapper.balanceOf(msg.sender, userShortID) > 0, "CLOSE: Not your position");
            require(users[msg.sender].isPositionInShort[userShortID] == true, "CLOSE: Positon inactive");
            //get price at pool for shortBal of positionID
            (address token, uint24 fee) = getTokenAndFeeShortedByUser(user, userShortID);
            uint priceAtClose = swapOracle.getSwapPrice(
                    token,
                    fee
                );
            //unwrwap and free funds
            beraWrapper.unwrapPosition(userShortID);
            users[msg.sender].isPositionInShort[userShortID] = false;
            users[msg.sender].userShortBalanceByID[userShortID] = 0;
            require(users[msg.sender].isPositionInShort[userShortID] == false,
                "CLOSE: Position still active");

            //swap back to DAI
            uint amountOut = beraSwapper._swapShort(
                user,
                DAI_ADDRESS, //
                token,
                fee,
                users[user].tokenAmountByPositionID[userShortID],
                amountOutMin
            );

            // where returnValue of 0 = profit
            (uint amountPNL, uint8 returnValue) = PnLCalculator.calculatePNL(
                getUserEntryPrice(user, userShortID), //entry
                priceAtClose, //closing price
                int(amountOut) //trade size
            );
            if (returnValue == 0) {
            //transfer funds back from user -- they are keeping the difference
                IERC20(DAI_ADDRESS).transferFrom(user, address(this), amountOut);
            }
            //if the trade is a loss we take from their deposited amount and increase global rewards
            users[user].userDepositBalance -= amountPNL;
            globalRewards += amountPNL;
        }

    function updateUserMappings(
        address user,
        uint shortID,
        uint entryPrice,
        uint shortBalanceByID,
        address tokenToShort,
        uint tokenTradeSize,
        uint24 poolFee
    ) internal {
        users[user].entryPrice[shortID] = entryPrice;
        //update user balance of the user current positionID
        //this is used to keep track of how much of the users deposit is currently being used
        users[user].userShortBalanceByID[shortID] = shortBalanceByID;
        //update userPositionNumber current short status
        users[user].isPositionInShort[shortID] = true;
        //update token and fee by ID
        users[user].tokenShortedByPositionID[shortID] = tokenToShort;
        users[user].tokenAmountByPositionID[shortID] = tokenTradeSize;
        users[user].poolFeeByPositionID[shortID] = poolFee;
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
