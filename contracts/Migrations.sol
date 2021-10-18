// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; //solhint-disable


contract Migrations {
    address public owner;
    uint public last_completed_migration; //solhint-disable var-name-mixedcase

    constructor() public {
        owner = msg.sender;
    }

    modifier restricted() {
        if (msg.sender == owner) _;
    }

    function setCompleted(uint completed) public restricted {
        last_completed_migration = completed;
    }
}
