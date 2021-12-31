// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; //solhint-disable compiler-fixed


import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import ".TWAPoracle.sol";

contract SwapOracle {

    TWAPoracle public immutable twapOracle;
    address private constant WETH_DAI_POOL = 0xC2e9F25Be6257c210d7Adf0D4Cd6E3E881ba25f8;


    constructor(TWAPoracle _twapOracle) {
        twapOracle = _twapOracle;
    }

    //keep in mind that these values are twapped prior to return, and in the case of swapping
    //to eth first they are twapped twice, so prices are not *completely* accurate, but should be
    //fine for the initial purposes
    function getQuotedPrice(address token0, uint24 fee) external
        returns(uint quote) {
            //first we get the price of weth in dai for the most popular fee pool 0.3%
            uint wethPrice = twapOracle.latestPrice(WETH_DAI_POOL, 3000);
            //compute a path between pools, usually erc20 -> eth -> dai
            (address pool, uint8 returnCode) = twapOracle.getPoolForTWAP(token0, fee);
            if (returnCode == 0) {
              //return token0 price in eth
                uint tokenPriceInWeth = twapOracle.latestPrice(pool, fee);
                //now we have to get price in dai
                return quote = tokenPriceInWeth * wethPrice;
            }
            return quote = twapOracle.latestPrice(pool, fee);
        }
}
