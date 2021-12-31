// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; //solhint-disable compiler-fixed

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "../uniswapv08/v3-periphery/OracleLibrary.sol";
import "../uniswapv08/v3-periphery/PoolAddress.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./IOracle.sol";


//TODO
//reworking contract now, is kinda fucked in the current state did not finish
contract TWAPOracle is IOracle {

    uint32 public constant TWAP_PERIOD = 3 minutes;
    address private constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address private constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IUniswapV3Factory public immutable uniswapFactory;
    uint private constant WAD = 1e18;
    uint public immutable uniswapTokenToPrice;      // See constructor comment below.

    /**
     * @notice Example pools to pass in:
     * USDC/ETH (0.05%): 0x88e6a0c2ddd26feeb64f039a2c41296fcb3f5640, 1, -12
     * ETH/USDT (0.05%): 0x11b815efb8f581194ae79006d24e0d814b7697f6, 0, -12
     * @param tokenToPrice Which token we're pricing (0 or 1) relative to the other.
     Eg, for the USDC/ETH pool (token0 = USDC,
     * token1 = ETH), we want the price of ETH in terms of USDC, not vice versa:
     so we should pass in `tokenToPrice == 1'.
     */
    constructor(IUniswapV3Factory factory, uint tokenToPrice) { //solhint-disable func-visibility
        uniswapFactory = factory;
        require(tokenToPrice == 0 || tokenToPrice == 1, "tokenToPrice not 0 or 1");
        uniswapTokenToPrice = tokenToPrice;

    }

    function getPoolForTWAP(address tokenA, uint24 fee) external view returns (address, uint8) {
        address pool = uniswapFactory.getPool(tokenA, DAI_ADDRESS, fee);
        //if there isn't a dai pool, we check for a weth pool
        if (pool == address(0)) {
            return (pool, 1) = uniswapFactory.getPool(tokenA, WETH_ADDRESS, fee);
        }
        //else, if there is a dai pool we return it here
        return (pool, 0);
    }

    // We want latestPrice() to return WAD-fixed-point (18-decimal-place) numbers.
    // So, eg, if Uniswap's output numbers
    // include 3 decimal places (ie, are already scaled by 10**3), we need to scale them by another 10**15:
    /** decimalPlaces How many decimal places are already included in the numbers Uniswap returns.  So,
    * `decimalPlaces = 3` means when Uniswap returns 12345,
    it actually represents 12.345 (ie, the last three digits were the
    * decimal part). `decimalPlaces = -3` means when Uniswap returns 12345, it actually represents 12,345,000.
    */
    function latestPrice(address pool, address token0)
        public virtual override view returns (uint price) {
            int decimalPlaces = int8(ERC20(token0).decimals());
            uint128 uniswapScaleFactor = uint128(decimalPlaces >= 0 ?
                WAD / 10 ** uint(decimalPlaces) :
                WAD * 10 ** uint(-decimalPlaces));

            int24 twapTick = OracleLibrary.consult(pool, TWAP_PERIOD);
                price = uniswapTokenToPrice == 1 ? //solhint-disable
            OracleLibrary.getQuoteAtTick(twapTick, uniswapScaleFactor, IUniswapV3Pool(pool).token1(), IUniswapV3Pool(pool).token0()) :
            OracleLibrary.getQuoteAtTick(twapTick, uniswapScaleFactor, IUniswapV3Pool(pool).token0(), IUniswapV3Pool(pool).token1());
    }
}
