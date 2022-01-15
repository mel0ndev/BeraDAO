// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; //solhint-disable compiler-fixed


import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "./TWAPoracle.sol";
import "./Constants.sol";


contract SwapOracle {

    TWAPOracle public immutable twapOracle;
    address public immutable WETH_DAI_POOL = 0xC2e9F25Be6257c210d7Adf0D4Cd6E3E881ba25f8;

    constructor(TWAPOracle _twapOracle) { //solhint-disable func-visibility
        twapOracle = _twapOracle;
    }

    //keep in mind that these values are twapped prior to return, and in the case of swapping
    //check for dai path, otherwise get price in weth
    function getSwapPrice(address token0, uint24 fee) external view
        returns(uint quote) {
            (address pool, uint8 returnCode) = twapOracle.getPoolForTWAP(token0, fee);
            if (returnCode == 1) { //if return is 1 then pool == weth pool
                //first we get the price of weth in dai for the most popular fee pool -- 0.3%
                uint wethPrice = twapOracle.latestPrice(WETH_DAI_POOL);

                uint tokenPriceInWeth = twapOracle.latestPrice(pool);
                return quote = tokenPriceInWeth * wethPrice;
            } //else we return quote == dai pool price
            return quote = twapOracle.latestPrice(pool);
        }
}
