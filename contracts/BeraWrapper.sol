// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; //solhint-disable compiler-fixed

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";


contract BeraWrapper is ERC1155 {

    address public owner;
    uint public positionIDTotal;
    mapping(uint => WrappedPosition) public positionData;

    struct WrappedPosition {
        address associatedPool; //standard or high risk pool
        uint shortAmount;
        address tokenShorted;
        uint priceAtWrap;
        uint publicPositionID;
    }

    constructor() ERC1155("BeraWrapped Position V1") { //solhint-disable func-visibility
        owner = msg.sender;
    }

    function wrapPosition(
        address associatedPool,
        uint shortAmount,
        address tokenShorted,
        uint priceAtWrap)
        external {
            //increase global position counter
            positionIDTotal++;

            positionData[positionIDTotal] = WrappedPosition({
                associatedPool: associatedPool,
                shortAmount: shortAmount,
                tokenShorted: tokenShorted,
                priceAtWrap: priceAtWrap,
                publicPositionID: positionIDTotal
            });

            //to, id, number of tokens per id, uri data
            //using erc1155 because it might be useful to use later
            _mint(msg.sender, positionIDTotal, 1, "");
        }

    function unwrapPosition(uint positionID) external {
        require(ERC1155.balanceOf(msg.sender, positionID) > 0, "UNWRAP: Position not yours or not found");
        //we burn the token to release the funds
        _burn(msg.sender, positionID, 1);
        delete positionData[positionID];
    }

    //SHOULD BE USED TO TRANSFER POSITIONS
    function transferPosition(address to, uint positionID) external {
        //check that receiver has a high enough balance
        // require(getTotalCollateral(to) <=
        //     positionData[positionID].shortAmount * positionData[positionID].priceAtWrap,
        //     "RECEIVER: Not enough collateral");

        //to, from, globalID, number of tokens, metadata
        ERC1155.safeTransferFrom(to, msg.sender, positionID, 1, "");
    }

}
