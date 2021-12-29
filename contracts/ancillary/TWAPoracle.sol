// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; //solhint-disable compiler-fixed

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "../uniswapv08/v3-periphery/OracleLibrary.sol";
import "../uniswapv08/v3-periphery/PoolAddress.sol";
import "./IOracle.sol";


//TODO
//reworking contract now, is kinda fucked in the current state did not finish
contract TWAPOracle is IOracle {

    uint32 public constant TWAP_PERIOD = 3 minutes;

    //TODO: fix this
    function getPoolAddress(address token0, address token1, uint24 fee) external returns(address) {
        PoolAddress.getPoolKey(token0, token1, fee);
        return PoolAddress.computeAddress(factoryAddress, PoolKey);
    }

    //fix return values, do I need to account for anything other than dai as a base?
    // I don't think so...
    function latestPrice(IUniswapV3Pool pool, uint128 amountInToken) //where amountInToken == shortAmount
        external virtual override view returns (uint price) {

            int24 twapTick = OracleLibrary.consult(address(pool), TWAP_PERIOD);
            price =
            OracleLibrary.getQuoteAtTick(twapTick, amountInToken, pool.token1(), pool.token0());

        }
}
