
// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.11; 

//solidity have integer type no fixed or floating type floating type came with unexpected behaviour due to rounding issues  so we shouldn't use somehting like that in security relavant things like smart contracts but fixed point number are potenital solution
//153.17238  we define a number which have integer part and fractional part and then behaviour is never unexpected solidity itself doesn't have direct support to fixed point number but its fairly simple to implement somehting like that


//how to use library and sturct then we can easily fixed point math library
// library  WadLib  {
//     uint256 public constant MULTIPLIER =  10**18; // 10 to the power 18 this indicated us how many digit we want to use for the  fractional part of the number wad=when you have 18 decimal and you don't have to use 18 decimal you can use any amount of decimal here but we are going to use 18  

//     struct Wad{
//         uint256 value;
//     } //represent when we use fixed point number 

//     function mulWad(uint256 number , Wad memory wad) internal pure returns(uint256){
//         return (number * wad.value) / MULTIPLIER;
//     }
// function divWad(uint256 number , Wad memory wad) internal pure returns(uint256){
//         return (number * MULTIPLIER) / wad.value;
//     }

 
// function fromFraction(uint256 numberator , uint256 denominator) internal pure returns(Wad memory){
//     if(numberator == 0){
//         return Wad(0);
//     }
//     return Wad(numberator * MULTIPLIER/ denominator);
// }

// }


// >> solidity also has additional  function soldity actually has a new feature for this use case i just want you to show all the way to use the struct there is the better way for exactly implementing  this here you don't need struct it little most gas efficent and nicer to read  and there is a custom type solidity  has insted defining as a struct we can just said type Wad is uint256;



library  WadLib  {
    uint256 public constant MULTIPLIER =  10**18; // 10 to the power 18 this indicated us how many digit we want to use for the  fractional part of the number wad=when you have 18 decimal and you don't have to use 18 decimal you can use any amount of decimal here but we are going to use 18  

type Wad is uint256;

    function mulWad(uint256 number , Wad  wad) internal pure returns(uint256){
        return (number * Wad.unwrap(wad)) / MULTIPLIER;         //unrap will just use this value here not changing it but it will make the compile not to complain anymore
    }
function divWad(uint256 number , Wad  wad) internal pure returns(uint256){
        return (number * MULTIPLIER) / Wad.unwrap(wad);
    }

 
function fromFraction(uint256 numberator , uint256 denominator) internal pure returns(Wad ){
    if(numberator == 0){
        return Wad.wrap(0);              //if you want to create a new Wad you say wrap thats it now we can use in stable coin 
    }
    return Wad.wrap(numberator * MULTIPLIER / denominator);
}

}
