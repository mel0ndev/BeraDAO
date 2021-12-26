// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; //solhint-disable compiler-fixed

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";


//this bullshit contract doesn't work, need to find a way to get oracle to work properly
contract TWAPOracle {

    function getPrice(address pool) public view returns(int24) {
        uint32[] memory secondsAgo = new uint32[](2);
        secondsAgo[0] = 900;
        secondsAgo[1] = 0;

        (int56[] memory tickCumulatives, ) = IUniswapV3Pool(pool).observe(secondsAgo);
        return int24(tickCumulatives[1] - tickCumulatives[0] / 900);

    }

}
