
// SPDX-License-Identifier: MIT

//quickly implement oracle there we can use for our stable coin but off course we will using centralized oracle which is pretty easy to implement
pragma solidity  ^0.8.11; 

contract Oracle {
    address public owner;
    uint256 private price;

    constructor(){               //set the owner who is deploying a contract
        owner = msg.sender;
    }


function getPrice()external view returns (uint256){ //read the price function
    return price;
}


function setPrice(uint256 newPrice) external { //update the price function
    require(msg.sender == owner, "Oracle: only owner"); //only owner can update the price so checking 
    price  = newPrice;
}


//this is already a simple oracle function that we can use in our stablecoin

}