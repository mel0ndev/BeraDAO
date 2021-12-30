// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; //solhint-disable compiler-fixed

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "../uniswapv08/v3-periphery/OracleLibrary.sol";
import "../uniswapv08/v3-periphery/PoolAddress.sol";
import "./IOracle.sol";


//TODO
//reworking contract now, is kinda fucked in the current state did not finish
contract TWAPOracle is IOracle {

    uint32 public constant TWAP_PERIOD = 3 minutes;
    address private constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    IUniswapV3Factory public immutable uniswapFactory;
    IUniswapV3Pool private uniswapv3Pool;

    constructor(IUniswapV3Factory factory) {
        uniswapFactory = factory;
    }

    //TODO: fix this
    function getPoolForTWAP(address tokenA, uint24 fee) external view returns (address) {
        return uniswapFactory.getPool(tokenA, DAI_ADDRESS, fee);
    }

    //fix return values, do I need to account for anything other than dai as a base?
    // I don't think so...
    function latestPrice(IUniswapV3Pool pool, uint128 amountInToken) //where amountInToken == shortAmount
        external virtual override view returns (uint price) {
            int24 twapTick = OracleLibrary.consult(address(pool), TWAP_PERIOD);
            price =
            OracleLibrary.getQuoteAtTick(
                twapTick,
                amountInToken,
                uniswapv3Pool.token1(),
                uniswapv3Pool.token0()
            );

        }
}
