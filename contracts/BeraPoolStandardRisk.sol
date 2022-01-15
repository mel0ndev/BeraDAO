// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; //solhint-disable compiler-fixed
pragma abicoder v2;


import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./BeraWrapper.sol";
import "./BeraSwapper.sol";
import "./ancillary/PnLCalculator.sol";
import "./ancillary/SwapOracle.sol";


contract BeraPoolStandardRisk is ERC1155Holder {

    struct Liquidation {
        bool isUnderwater;
        bool wasLiquidated;
        address liquidator;
    }

    struct UserPositionData {
        uint256 entryPrice; //32 bytes
        uint128 userShortBalanceByID; //16 bytes
        uint128 tokenAmountByPositionID; //16 bytes
        uint64 globalPositionID; //8 bytes
        uint24 poolFeeByPositionID; //4 bytes
        address tokenShortedByPositionID; //20 bytes
    }

    //removed position bool >> if the position is active there will be a token
    //if it has been closed the token is burned
    struct Account {
        uint lastClaimedRewards;
        uint128 userDepositBalance;
        uint128 userShortID; //maps to positionDetails and liqData
        mapping(uint128 => UserPositionData) userPositionData;
        mapping(uint128 => Liquidation) liqData;
    }

    mapping(address => Account) public users;
    address public owner;

    uint public protocolOwnedLiquidity;
    uint public globalRewards;
    address private constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    BeraWrapper private beraWrapper;
    BeraSwapper private beraSwapper;
    SwapOracle private swapOracle;

    constructor(BeraWrapper _beraWrapper,
        SwapOracle _swapOracle,
        BeraSwapper _beraSwapper) { //solhint-disable func-visibility
        owner = msg.sender;
        beraWrapper = _beraWrapper;
        swapOracle = _swapOracle;
        beraSwapper = _beraSwapper;
    }

    function depositCollateral(uint amount) external {
        //used for withdrawl later
        users[msg.sender].userDepositBalance += amount;
        //transfer DAI to this contract
        TransferHelper.safeTransferFrom(DAI_ADDRESS, msg.sender, address(this), amount);
        IERC20(DAI_ADDRESS).transferFrom(msg.sender, address(this), amount);
    }

    function withdrawFromPool(uint amount, uint userShortID) external {
        require(amount <= users[msg.sender].userDepositBalance,
            "COLLATERAL: trying to withdraw more collateral than deposited");
        //checking if the funds locked in the position have been released before allowing them to be withdrawn
        require(getUserShortBool(msg.sender, userShortID) == false,
            "COLLATERAL: close your current position before trying to withdraw");
        require(IERC20(DAI_ADDRESS).balanceOf(msg.sender) == users[msg.sender].userDepositBalance,
            "COLLATERAL: balance mismatch");
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
                //gets TWAP price, updates globals and user short ID) &&
                //reverts here if total collateral is > total deposit amount
                (uint priceAtWrap, uint amountToSend) =
                    updateGlobalsAndCheckCollateral(msg.sender, amount, tokenToShort, poolFee);

                //execute swapShort via swapper contract
                uint amountOut = beraSwapper._swapShort(
                    msg.sender,
                    tokenToShort,
                    DAI_ADDRESS, //this contract receives dai back
                    poolFee,
                    amountToSend, //amount being sent to swapper
                    amountOutMin
                );

                beraWrapper.wrapPosition(
                    address(this), // the associated pool
                    amountOut,  // the amount of token shorted
                    tokenToShort, // what token was shorted
                    priceAtWrap // the price of 1 tokenToShort in dai
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

                // now we transfer dai to user and hold their tokens for them
                uint amountToReturn = amountOut * priceAtWrap / 1e18;
                IERC20(DAI_ADDRESS).transfer(msg.sender, amountToReturn);
            }

    function supplyShort(
        address tokenToShort,
        uint24 poolFee,
        uint amount) external returns(uint amountOut) {
        require(poolFee == 3000 || poolFee == 500, "SWAP: Not high risk pool");

        amountOut = beraSwapper._supplyShort(
            msg.sender, //transfer token from msg.sender
            tokenToShort, // what token the user wants us to hold -- must be in their wallet
            poolFee, //used to get price
            amount, //how much they are sending
            address(this) // sends tokent to this contract
        );

        //check that dai amount is lte deposit balance &&
        //update globals with dai value && update user position ID
        (uint priceAtWrap, uint amountToSend) =
            updateGlobalsAndCheckCollateral(msg.sender, amountOut, tokenToShort, poolFee);

        beraWrapper.wrapPosition(
            address(this), //the associated pool
            amount,  //the amount of token shorted
            tokenToShort, //what token was shorted
            priceAtWrap //the price of 1 tokenToShort in dai
        );

        //send dai back at market price minus fee
        IERC20(DAI_ADDRESS).transfer(msg.sender, amountToSend);
    }

    // if you are reading this comment, this is a way for you to make some money
    // and keep the protocol alive and kicking
    // keep in mind that you need to have deposited collateral to receive rewards
    function liquidateUser(address userUnderwater, address liquidator, uint shortID) external {
        //get entry price by shortID and subtract by current price
        (address token, uint24 fee) = getTokenAndFeeShortedByUser(userUnderwater, shortID);

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

    function getTokenAndFeeShortedByUser(address user, uint shortID) public view returns(address token, uint24 fee) {
        token = users[user].tokenShortedByPositionID[shortID];
        fee = uint24(users[user].poolFeeByPositionID[shortID]);
        return (token, fee);
    }

    //TODO
    // if you are liquidating an underwater position make sure to first update the user's liqData
    function closeShort(
        address user, //we pass in a user instead of msg.sender to accounts for liquidations
        uint userShortID,
        uint publicPositionID,
        uint amountOutMin)
        public {
            require(beraWrapper.balanceOf(user, publicPositionID) > 0 ||
                users[user].liqData[userShortID].isUnderwater == true,
                    "CLOSE: Not your position OR not underwater OR inactive");

            //get price at pool for shortBal of positionID
            (address token, uint24 fee) = getTokenAndFeeShortedByUser(user, userShortID);
            uint priceAtClose = swapOracle.getSwapPrice(token, fee);

            //unwrwap and free funds
            //delegatecall so msg.sender is user and not contract
            beraWrapper.delegatecall( //solhint-disable avoid-low-level-calls
                abi.encodeWithSelector(BeraWrapper.unwrapPosition.selector, userShortID));

            users[user].userShortBalanceByID[userShortID] = 0;

            require(beraWrapper.balanceOf(user, globalPositionID) == 0, "CLOSE: Position Active");
            //swap back to DAI
            uint amountOut = beraSwapper._swapShort(
                msg.sender,
                DAI_ADDRESS, //in token
                token, // out token
                fee,
                users[user].tokenAmountByPositionID[userShortID], //amount to send
                amountOutMin
            );

            // where returnValue of 0 = profit
            (uint amountPNL, uint8 returnValue) = PnLCalculator.calculatePNL(
                getUserEntryPrice(user, userShortID), //entry
                priceAtClose, //closing price
                int(amountOut) //trade size
            );
            // if the trade is a loss we update the rewards by the difference
            if (returnValue == 1) {
                globalRewards += amountPNL;
            }
            // transfer funds back from user, they are keeping the difference on a win and paying more for a loss
            // amountOut will be used for the current market rate
            // regardless of win/loss so we can use it in both situations
            IERC20(DAI_ADDRESS).transferFrom(user, address(this), amountOut);
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
        //this is used to keep track of how much of the users deposit is currently being used by which positionID
        users[user].userShortBalanceByID[shortID] = shortBalanceByID;
        //update token and fee by ID
        users[user].tokenShortedByPositionID[shortID] = tokenToShort;
        users[user].tokenAmountByPositionID[shortID] = tokenTradeSize;
        users[user].poolFeeByPositionID[shortID] = poolFee;
    }

    function updateGlobalsAndCheckCollateral(
        address user,
        uint amount,
        address tokenToShort,
        uint24 poolFee)
        internal returns(uint priceAtWrap, uint amountToSend) {
            priceAtWrap = swapOracle.getSwapPrice(tokenToShort, poolFee);

            users[user].userShortID += 1;
            //get total amount of collateral in shorts if user has opened a position before
            //also check that current amount + total < deposit balance
            if (getTotalCollateral(user) > 0) {
                require(getTotalCollateral(user) <= users[user].userDepositBalance,
                    "SWAP: not enough collateral");
                require(amount + getTotalCollateral(user) <= users[user].userDepositBalance,
                    "SWAP: not enough collateral");
            }

            //1% is kept as fee to protocol to assist in paying out users
            amountToSend = amount * 99 / 100;
            //update global so we know how much of deposited amount belongs to users vs protocol
            protocolOwnedLiquidity += amount - amountToSend;
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

}
