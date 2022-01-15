//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; //solhint-disable compiler-fixed

import "../BeraWrapper.sol";
import "../BeraSwapper.sol";
import "../BeraPoolStandardRisk.sol";


contract Constants {

    address public immutable DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public immutable WETH_DAI_POOL = 0xC2e9F25Be6257c210d7Adf0D4Cd6E3E881ba25f8;
    address public immutable WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint24 private constant DAI_FEE = 3000;

    function getDaiAddress() public view returns(address) {
        return DAI_ADDRESS;
    }

    function getWethDaiPool() public view returns(address) {
        return WETH_DAI_POOL;
    }

    function getWethAddress() public view returns(address) {
        return WETH_ADDRESS;
    }

    function getDaiFee() public pure returns(uint24) {
        return DAI_FEE;
    }

}
