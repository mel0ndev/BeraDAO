// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; //solhint-disable compiler-fixed

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "../uniswapv08/v3-periphery/OracleLibrary.sol";
import "../uniswapv08/v3-periphery/PoolAddress.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./IOracle.sol";


contract TWAPOracle is IOracle {

    uint32 public constant TWAP_PERIOD = 2 minutes;
    address private constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address private constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IUniswapV3Factory public immutable uniswapFactory;
    uint128 private constant WAD = 1e18;

    /**
     * @notice Example pools to pass in:
     * USDC/ETH (0.05%): 0x88e6a0c2ddd26feeb64f039a2c41296fcb3f5640, 1, -12
     * ETH/USDT (0.05%): 0x11b815efb8f581194ae79006d24e0d814b7697f6, 0, -12
  */
    constructor(IUniswapV3Factory factory) { //solhint-disable func-visibility
        uniswapFactory = factory;
    }

    function getPoolForTWAP(address tokenA, uint24 fee) external override view returns (address, uint8) {
        address pool = uniswapFactory.getPool(tokenA, DAI_ADDRESS, fee);
        //if there isn't a dai pool, we check for a weth pool
        if (pool == address(0)) {
            pool = uniswapFactory.getPool(tokenA, WETH_ADDRESS, fee);
            return (pool, 1);
        } //else, if there is a dai pool we just return that
        return (pool, 0);
    }

    function latestPrice(address pool)
        public virtual override view returns (uint price) {
            int24 twapTick = OracleLibrary.consult(pool, TWAP_PERIOD);

            //if the pool has dai or weth as token0 ie. DAI/USDC or WETH/USDC
            if (DAI_ADDRESS == IUniswapV3Pool(pool).token0() ||
                WETH_ADDRESS == IUniswapV3Pool(pool).token0()) {
                //keeping this here for now in case a special case token appears with less than 18 decimals
                uint128 scaleFactor = uint128(1 ** ERC20(IUniswapV3Pool(pool).token1()).decimals());

                if (scaleFactor == 0) {
                    scaleFactor = WAD;
                }

                return price = OracleLibrary.getQuoteAtTick(
                    twapTick,
                    scaleFactor, //decimals of token or 18 by default 
                    IUniswapV3Pool(pool).token1(), //price token1 in terms of token0 (get token price in eth)
                    IUniswapV3Pool(pool).token0()
                );

            }
            //else we return dai or weth as token1 ie FTT/WETH or RAI/DAI
            return price = OracleLibrary.getQuoteAtTick(
                twapTick,
                WAD,
                IUniswapV3Pool(pool).token0(), //price token0 in terms of token1
                IUniswapV3Pool(pool).token1()
            );
        }
}
