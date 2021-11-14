// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0; //solhint-disable compiler-fixed
// //import "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";s
// import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
//
//
// //this bullshit contract doesn't work, need to find a way to get oracle to work properly
// contract TWAPOracle {
//
//     address public _pool;
//     uint32 public _period = 1;
//
//     function getPrice() external returns(int24 ass) {
//         return ass = consult(_pool, _period);
//     }
//
//     function consult(address pool, uint32 period) internal view returns (int24 timeWeightedAverageTick) {
//         require(period != 0, "BP");
//
//         uint32[] memory secondAgos = new uint32[](2);
//         secondAgos[0] = period;
//         secondAgos[1] = 0;
//
//         (int56[] memory tickCumulatives, ) = IUniswapV3Pool(pool).observe(secondAgos);
//         int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];
//
//         timeWeightedAverageTick = int24(tickCumulativesDelta / period);
//
//         // Always round to negative infinity
//         if (tickCumulativesDelta < 0 && (int24(tickCumulativesDelta) % period != 0)) timeWeightedAverageTick--;
//     }
//
// }
