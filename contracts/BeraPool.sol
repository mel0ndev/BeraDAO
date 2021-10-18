// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; //solhint-disable compiler-fixed

import "./GoblinTownToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract BeraPool {

    IERC20 public goblinTownToken;

    mapping(address => uint) public userPercentOfPool;
    uint public totalPoolSize;

    address[] public poolList;

    address private constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    constructor(IERC20 _goblinTownToken) { //solhint-disable func-visibility
        goblinTownToken = _goblinTownToken;
    }

    function depositGTT(uint amount) external returns(bool) {
        IERC20(goblinTownToken).transferFrom(msg.sender, address(this), amount);
        userPercentOfPool[msg.sender] += amount;

        poolList.push(msg.sender);

        return true;
    }

    function withdawGTT(uint amount) external returns(bool) {
        require(amount <= userPercentOfPool[msg.sender],
        "GTT: you cannot withdraw more tokens than you have deposited!");

        IERC20(goblinTownToken).transfer(msg.sender, amount);

        return true;
    }

    //TODO 
    //could be very costly, use a uint instead and just allow users to withdaw that amount later?
    function distributeProfits(uint percentToSendToUser) external {
        for (uint i = 0; i < poolList.length; i++) {
            percentToSendToUser = userPercentOfPool[poolList[i]] / totalPoolSize;
            IERC20(DAI_ADDRESS).transfer(poolList[i], percentToSendToUser);
        }
    }

    function getUserPercentage(address user) external view returns(uint) {
        return userPercentOfPool[user] / totalPoolSize;
    }


}
