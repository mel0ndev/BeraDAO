// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";


interface IOracle {
    /**
     * @return price WAD-scaled - 18 dec places
     */
    function latestPrice(address pool, address token0, uint tokenToPri) external view returns (uint price);
}
