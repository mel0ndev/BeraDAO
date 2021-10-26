// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; //solhint-disable compiler-fixed

import "./GoblinTownToken.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract GoblinVotingRights is ERC20 {

    mapping(address => bool) public canVote;
    mapping(address => uint) public gttBalance;
    mapping(address => uint) public votingBalance;
    mapping(address => uint) public balances;

    uint public minimumVotingBalance;
    address[] public voters;

    address public owner;

    GoblinTownToken public goblinTownToken;

    constructor(GoblinTownToken _goblinTownToken)
    ERC20("Goblin Voting Rights Token", "GVRT") {  //solhint-disable func-visibility
        goblinTownToken = _goblinTownToken;
        owner = msg.sender;
        minimumVotingBalance = 1000;
    }

    function changeMinimumVotingBalance(uint newBalanceNeeded) external {
        require(msg.sender == owner, "not owner");
        minimumVotingBalance = newBalanceNeeded;
    }

    //will be called externally via script
    function distributeVotingRightsTokens() external {
        require(msg.sender == owner, "not owner");
        _distributeVotingRightsTokens;
    }

    function checkVotingStatus(address voter) internal {
        if (votingBalance[voter] > minimumVotingBalance) {
            canVote[voter] = true;
        }
    }

    function _distributeVotingRightsTokens() internal {
        for (uint i = 0; i <= voters.length; i++) {
            checkVotingStatus(voters[i]);
            if (canVote[voters[i]] == true) {
                //get user balance
                uint votingTokens = goblinTownToken.balanceOf(voters[i]);
                _mint(voters[i], votingTokens);
            }
        }
    }

}
