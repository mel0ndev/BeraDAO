// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; //solhint-disable compiler-fixed

import "../BeraWrapper.sol";
import "../BeraSwapper.sol";
import "../BeraPoolStandardRisk.sol";


contract Constants {

    address public immutable DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public immutable WETH_DAI_POOL = 0xC2e9F25Be6257c210d7Adf0D4Cd6E3E881ba25f8;
    address public immutable WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    //core contracts
    BeraWrapper public immutable beraWrapper;
    BeraSwapper public immutable beraSwapper;
    BeraPoolStandardRisk public immutable beraPoolStandardRisk;

    constructor(BeraWrapper _beraWrapper, BeraSwapper _beraSwapper, BeraPoolStandardRisk _standardRiskPool) {
        beraWrapper = _beraWrapper;
        beraSwapper = _beraSwapper;
        beraPoolStandardRisk = _standardRiskPool;
    }

}
