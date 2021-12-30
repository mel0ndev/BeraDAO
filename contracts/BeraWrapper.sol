// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; //solhint-disable compiler-fixed

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";


contract BeraWrapper is ERC1155 {

    address public owner;

    uint public positionIDTotal;

    mapping(uint => Position) public positionData;

    struct Position {
        address positionOwner; //address of user that shorted
        address associatedPool; //standard or high risk pool
        uint shortAmount;
        address tokenShorted;
        uint priceAtWrap;
    }

    constructor() ERC1155("") { //solhint-disable func-visibility
        owner = msg.sender;
    }

    function wrapPosition(address positionOwner,
                address associatedPool,
                uint shortAmount,
                address tokenShorted,
                uint priceAtWrap)
                external {
                    //increase global position counter
                    positionIDTotal++;

                    positionData[positionIDTotal] = Position({
                        positionOwner: positionOwner,
                        associatedPool: associatedPool,
                        shortAmount: shortAmount,
                        tokenShorted: tokenShorted,
                        priceAtWrap: priceAtWrap
                    });

                    _mint(positionOwner, positionIDTotal, 1, "");
                }

    function unwrapPosition(address positionOwner, uint positionID) external {
        require(positionOwner == positionData[positionID].positionOwner,
            "Wrapper: only the owner can unwrap the position");

        //we burn the token to release the funds
        _burn(positionOwner, positionID, 1);
    }

    //SHOULD BE USED TO TRANSFER POSITIONS
    //should be called from associated pool contract only (will have to add this later)
    function transferPosition(address to, address from, uint _positionID, uint amount) external {
        require(msg.sender == positionData[_positionID].positionOwner,
            "Wrapper: only the owner can transfer a position");
        require(from == positionData[_positionID].positionOwner,
            "Wrapper: only the owner can transfer a position");

        //send position
        safeTransferFrom(to, from, _positionID, amount, "");

        //update new owner
        //might have some security issues with this, come back and recheck this later
		positionData[_positionID].positionOwner = to; 
    }

    //if position happens to get sent without the transferPosition() func being called then
    //users can update it manually with this func
    function updatePosition(address newPositionOwner, uint _positionID) external {
        if (ERC1155.balanceOf(newPositionOwner, _positionID) > 0) {
            //update new owner
            positionData[_positionID].positionOwner = newPositionOwner;
        }
    }
}
