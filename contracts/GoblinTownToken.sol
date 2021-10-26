// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; //solhint-disable compiler-fixed

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract GoblinTownToken is ERC20 {

    uint public circulatingSupply;
    uint public constant MAX_SUPPLY = 100000000;
    address private owner;
    mapping(address => uint) public balances;

    constructor(uint initialSupply) ERC20("Goblin Town Token", "GTT") { //solhint-disable func-visibility
        owner = msg.sender;
        circulatingSupply = initialSupply;
        _mint(msg.sender, initialSupply);
    }

    function mint(uint amount) external {
        require(msg.sender == owner, "GTT: only the owner can mint tokens");
        require((amount + circulatingSupply) <= MAX_SUPPLY, "GTT: cannot mint more than max supply");

        _mint(msg.sender, amount);
        circulatingSupply += amount;
    }

    function changeOwners(address newOwner) external {
        require(msg.sender == owner, "GTT: only the owner can mint tokens");

        owner = newOwner;
    }

}
