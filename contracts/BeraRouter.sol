// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; //solhint-disable compiler-fixed
pragma abicoder v2;

//who would have guessed these github imports don't actually compile
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "./BeraPoolStandardRisk.sol";
import "./BeraWrapper.sol";
import "./BeraPool.sol";


//the public interface for the protocol
contract BeraRouter {

    mapping(address => uint) public userCollateralBalance;
    mapping(address => address) public nftPositionToken;
    mapping(address => bool) public inShort;
    uint public poolTokenBalance;

    mapping(address => uint) public entryPrice;

    address private constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    //fees idk about yet we gonna see
    uint public constant OPEN_FEE = 5;
    uint public constant CLOSING_FEE = 5;

    //uniswapV3 address router
    //might have to change if implement 1inch api
    ISwapRouter public  swapRouter;
    BeraPoolStandardRisk public beraPoolStandardRisk;
    IERC20 public token;
    BeraWrapper public beraWrapper;
    BeraPool public beraPool;

    ////
    address public owner;

    constructor(ISwapRouter _swapRouter,
        BeraPoolStandardRisk _beraPoolStandardRisk,
        BeraWrapper _beraWrapper,
        BeraPool _beraPool) { //solhint-disable func-visibility
        owner = msg.sender;
        swapRouter = _swapRouter;
        beraPoolStandardRisk = _beraPoolStandardRisk;
        beraWrapper = _beraWrapper;
        beraPool = _beraPool;
    }

//
// deposit collateral into user account
    function depositCollateral(uint amount, address collateral) external {
        require(IERC20(collateral) == IERC20(DAI_ADDRESS), "Not DAI");

        IERC20(collateral).transferFrom(msg.sender, address(this), amount);

        //testing purposes only for now
        poolTokenBalance += amount;
        userCollateralBalance[msg.sender] += amount;

    }

    function withdrawCollateral(uint amount, address collateral) external {
        require(amount >= userCollateralBalance[msg.sender], "user balance too low!");
        require(inShort[msg.sender] == false, "not in a position");

        IERC20(collateral).transfer(msg.sender, amount);

        //reset balance of user and pool on withdraw
        poolTokenBalance -= amount;
        userCollateralBalance[msg.sender] -= amount;
    }

    function swapAndShortStandard(
            uint amount,
            address tokenToShort,
            uint24 poolFee,
            uint amountOutMin,
            uint collateralPercentageOfAccount,
            uint priceAtWrap)
            external returns(uint amountOut) { //solhint-disable function-max-lines
                require(collateralPercentageOfAccount <= 100, "cannot use more than 100% of account to short");
                require(amount <= userCollateralBalance[msg.sender], "not enough collateral");

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

                // execute the frist swap & sends to beraPool based on params
                amountOut = swapRouter.exactInputSingle(params);

                //execute the second swap and transfer funds to pool for holding
                //have to update priceAtWrap, users can set this amount manually and drain funds lmfao
                beraPoolStandardRisk.shortForUser(
                    msg.sender,
                    tokenToShort,
                    priceAtWrap,
                    poolFee,
                    amountOut,
                    amountOutMin
                );

                //update entry price mapping
                entryPrice[msg.sender] = priceAtWrap;

                //update whether address is in a position or not
                inShort[msg.sender] = true;

                //send remaining funds back to user
                IERC20(DAI_ADDRESS).transfer(msg.sender, leftover);
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
        beraPoolStandardRisk.closeShortForUser(
            address(this),
            tokenToClose,
            amountOut, //how much tokenOut is being sent to swap back into dai (in this case weth)
            priceAtClose,
            poolFee,
            amountOutMin
        );

        //calculate if the user made or lost money on the position
        //also tranfers the profits to the user and distributes user losses amongst the pool
        calculatePNL(msg.sender, priceAtClose);

        //reset user short status
        inShort[msg.sender] = false; //solhint-disable reentrancy
    }

    function calculatePNL(address user, uint priceAtClose) internal {
        int remaining = int(entryPrice[user]) - int(priceAtClose);
        if (remaining > 0) {
            uint profits = entryPrice[user] - priceAtClose;
            IERC20(DAI_ADDRESS).transfer(user, profits); //case where user makes money
        } else {
            int loss = int(entryPrice[user]) - int(priceAtClose); //case where user loses money
            //make negative num postive
            int userLoss = (loss * (-1));
            require(uint(userLoss) <= userCollateralBalance[user],
                "PNL: loss exceeds user balance, liquidation function will be called");
            uint profits = uint(userLoss) - userCollateralBalance[user];

            //distribute remaining amongst pool holders
            beraPool.distributeProfits(profits);

            //update user collateral balance to reflect loss
            userCollateralBalance[user] -= uint(userLoss);
        }



    }

}
