// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; //solhint-disable compiler-fixed

import "./GoblinTownToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract BeraPool {

    GoblinTownToken public goblinTownToken;

    mapping(address => uint) public userPercentOfGTTPool;
    mapping(address => bool) internal hasDeposited;


    address[] public gttPoolList;

    address private constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    constructor(GoblinTownToken _goblinTownToken) { //solhint-disable func-visibility
        goblinTownToken = _goblinTownToken;
    }

    function depositGTT(uint amount) external {
        IERC20(goblinTownToken).transferFrom(msg.sender, address(this), amount);
        userPercentOfGTTPool[msg.sender] += amount;

        if (hasDeposited[msg.sender] == false) {
            gttPoolList.push(msg.sender);
            hasDeposited[msg.sender] = true;
        }
    }

    function withdawGTT(uint amount) external {
        require(amount <= userPercentOfGTTPool[msg.sender],
        "GTT: you cannot withdraw more tokens than you have deposited!");

        userPercentOfGTTPool[msg.sender] -= amount;

        if (userPercentOfGTTPool[msg.sender] <= 0) {
            hasDeposited[msg.sender] = false;
        }

        IERC20(goblinTownToken).transfer(msg.sender, amount);
    }

    function getUserPercentage(address user) external view returns(uint) {
        //get the individual percentage of the pool owned by a holder
        return userPercentOfGTTPool[user] / IERC20(goblinTownToken).balanceOf(address(this));
    }


}
