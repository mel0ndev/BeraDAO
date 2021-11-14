// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; //solhint-disable compiler-fixed

import "./GoblinTownToken.sol";
import "./BeraPool.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract GoblinVotingRights is ERC20 {

    mapping(address => uint) public balances;

    uint public minimumVotingBalance;
    address[] public voters;


    //GVR specific mappings
    mapping(address => bool) public canVote;
    mapping(address => uint) public gttBalance;
    mapping(address => uint) public votingBalance;

    address public owner;

    BeraPool private beraPool;
    GoblinTownToken private goblinTownToken;

    constructor(GoblinTownToken _goblinTownToken,
        BeraPool _beraPool)
        ERC20("Goblin Voting Rights Token", "GVR") {  //solhint-disable func-visibility
            goblinTownToken = _goblinTownToken;
            beraPool = _beraPool;
            owner = msg.sender;
            minimumVotingBalance = 1000;
        }

    function changeMinimumVotingBalance(uint newBalanceNeeded) external {
        require(msg.sender == owner, "not owner");
        minimumVotingBalance = newBalanceNeeded;
    }

    //will be called externally via script on timer
    function distributeVotingRightsTokens() external {
        require(msg.sender == owner, "not owner");
        _distributeVotingRightsTokens();
        _bonusTokens();
    }

    function checkVotingStatus(address voter) internal {
        if (votingBalance[voter] > minimumVotingBalance) {
            canVote[voter] = true;
            voters.push(voter);
        }
    }

    //tokens are distributed to holders that are eligible to vote
    //aim is to keep the voting populus small and engaged with a high buy in
    function _distributeVotingRightsTokens() internal {
        for (uint i = 0; i <= voters.length; i++) {
            checkVotingStatus(voters[i]);
            if (canVote[voters[i]] == true) {
                //get user balance and distribute 1:1
                uint votingTokens = goblinTownToken.balanceOf(voters[i]);
                _mint(voters[i], votingTokens);
            }
        }
    }

    function _bonusTokens() internal {
        //if user is top 25% of holders, then they are awarded bonus tokens
        for (uint i = 0; i < voters.length; i++) {
            if (beraPool.getUserPercentage(voters[i]) >
            (goblinTownToken.balanceOf(address(goblinTownToken)) * 25 / 100)) {
                uint bonusAmount = goblinTownToken.balanceOf(voters[i]) * 10 / 100;
                _mint(voters[i], bonusAmount);
            }
        }
    }
}
