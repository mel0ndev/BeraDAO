// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; //solhint-disable compiler-fixed
pragma abicoder v2;


library PnLCalculator {

    //lots of recasting as ints because positions can be negative
    //liquidation is checked for prior to calling
    //returnValue is used to check if the position was a win or loss in the contract that
    //actually handles the user funds
    function calculatePNL(uint entryPrice, uint priceAtClose)
        external pure returns(uint amountPNL, uint8 returnValue) {
            int difference = (int(entryPrice) * 1e18) - (int(priceAtClose) * 1e18);
            if (entryPrice > priceAtClose) { //case where user makes money
                amountPNL = uint(difference);
                returnValue = 0;
                return (amountPNL, returnValue);
            } else { //case where user loses money
              //make negative num postive
                int userLoss = (difference * (-1));
                amountPNL = uint(userLoss);
                returnValue = 1;
                return (amountPNL, returnValue);
            }
        }



}
