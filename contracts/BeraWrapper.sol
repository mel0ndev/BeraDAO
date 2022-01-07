// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; //solhint-disable compiler-fixed

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";


contract BeraWrapper is ERC1155 {

    address public owner;

    uint public positionIDTotal;

    mapping(uint => Position) public positionData;

    struct Position {
        address associatedPool; //standard or high risk pool
        uint shortAmount;
        address tokenShorted;
        uint priceAtWrap;
    }

    constructor() ERC1155("") { //solhint-disable func-visibility
        owner = msg.sender;
    }

    function wrapPosition(address associatedPool,
                uint shortAmount,
                address tokenShorted,
                uint priceAtWrap)
                external {
                    //increase global position counter
                    positionIDTotal++;

                    positionData[positionIDTotal] = Position({
                        associatedPool: associatedPool,
                        shortAmount: shortAmount,
                        tokenShorted: tokenShorted,
                        priceAtWrap: priceAtWrap
                    });

                    _mint(msg.sender, positionIDTotal, 1, "");
                }

    function unwrapPosition(uint positionID) external {
        // require(msg.sender == address(beraPoolStandardRisk),
        //     "Wrapper: only the owner can unwrap the position");

        //we burn the token to release the funds
        //broken rn
        _burn(msg.sender, positionID, 1);
    }

    //SHOULD BE USED TO TRANSFER POSITIONS
    function transferPosition(address to, uint _positionID, uint amount) external {
        //require(msg.sender == positionData[_positionID].positionOwner,
            //"Wrapper: only the owner can transfer a position");
            //check that msg.sender has the token in their balance
        require(balanceOf(msg.sender, _positionID) == amount,
            "Wrapper: not correct position or position size");

        //update new owner
        //positionData[_positionID].positionOwner = to;

        //send position
        safeTransferFrom(to, msg.sender, _positionID, amount, "");
    }

    //if position happens to get sent without the transferPosition() func being called then
    //users can update it manually with this func
    function updatePosition(address newPositionOwner, uint _positionID) external {
        if (balanceOf(newPositionOwner, _positionID) > 0) {
            //update new owner
            //positionData[_positionID].positionOwner = newPositionOwner;
        }
    }
}
