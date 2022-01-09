// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";


interface IOracle {

    //returns address of pool && 1 if no dai pool and 0 if dai pool
    function getPoolForTWAP(address tokenA, uint24 fee) external view returns (address, uint8);

    //returns latest price in 18 decimals
    function latestPrice(address pool) external view returns (uint price);

}
