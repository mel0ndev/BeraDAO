// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; //solhint-disable compiler-fixed

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "../uniswapv08/v3-periphery/OracleLibrary.sol";
import "./uniswapv08/v3-periphery/PoolAddress.sol";
import "./Oracle.sol";


//TODO
//reworking contract now, is kinda fucked in the current state did not finish
contract TWAPOracle is Oracle {

    uint32 public constant UNISWAP_TWAP_PERIOD = 1 minutes;

    uint private constant WAD = 1e18;

    IUniswapV3Pool public immutable uniswapV3Pool;
    uint public immutable uniswapTokenToPrice;      // See constructor comment below.
    uint128 public immutable uniswapScaleFactor;

    function getPoolAddress(address token0, address token1, uint24 fee) external returns(address) {
        PoolKey = PoolAddress.getPoolKey(token0, token1, fee);
        return PoolAddress.computeAddress(factoryAddress, PoolKey);
    }

    //maybe include something to fetch token deciamls automatically?
    function latestPrice(IUniswapV3Pool pool, uint tokenToPrice, int decimalPlaces)
        public virtual override view returns (uint price) {
            uniswapV3Pool = pool;
            require(tokenToPrice == 0 || tokenToPrice == 1, "tokenToPrice not 0 or 1");
            uniswapTokenToPrice = tokenToPrice;

            uniswapScaleFactor = uint128(decimalPlaces >= 0 ?
            WAD / 10 ** uint(decimalPlaces) :
            WAD * 10 ** uint(-decimalPlaces));

            int24 twapTick = OracleLibrary.consult(address(uniswapV3Pool), UNISWAP_TWAP_PERIOD);
            price = uniswapTokenToPrice == 1 ?
            OracleLibrary.getQuoteAtTick(twapTick, uniswapScaleFactor, uniswapV3Pool.token1(), uniswapV3Pool.token0()) :
            OracleLibrary.getQuoteAtTick(twapTick, uniswapScaleFactor, uniswapV3Pool.token0(), uniswapV3Pool.token1());
        }
}
