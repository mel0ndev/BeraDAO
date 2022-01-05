// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; //solhint-disable compiler-fixed


import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "./TWAPoracle.sol";


contract SwapOracle {

    TWAPOracle public immutable twapOracle;
    address private constant WETH_DAI_POOL = 0xC2e9F25Be6257c210d7Adf0D4Cd6E3E881ba25f8;
    address private constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    constructor(TWAPOracle _twapOracle) { //solhint-disable func-visibility
        twapOracle = _twapOracle;
    }

    //keep in mind that these values are twapped prior to return, and in the case of swapping
    //to eth first they are twapped twice, so prices are not *completely* accurate, but should be
    //fine for the initial testing purposes
    function getSwapPrice(address token0, uint24 fee) external view
        returns(uint quote) {
            //first we get the price of weth in dai for the most popular fee pool -- 0.3%
            uint wethPrice = twapOracle.latestPrice(WETH_DAI_POOL);
            //check for dai path, otherwise get price in weth
            (address pool, uint8 returnCode) = twapOracle.getPoolForTWAP(token0, fee);
            if (returnCode == 1) { //if return is 1 then pool == weth pool
                //worked for FTT/WETH but not for WETH/WRLD
                uint tokenPriceInWeth = twapOracle.latestPrice(pool);
                return quote = tokenPriceInWeth * wethPrice;
            } //else we return quote == dai pool price
            return quote = twapOracle.latestPrice(pool);
        }
}
