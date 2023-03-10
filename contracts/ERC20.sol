
// SPDX-License-Identifier: MIT


pragma solidity  ^0.8.11; 

contract ERC20 {


    uint256 public totalSupply;
    string public name;
    string public symbol;


event Transfer(address indexed from , address indexed to , uint256 value);
event Approval(address indexed owner , address indexed spender , uint256 value);  


   
   
    mapping (address => uint256) public balanceOf;


//to implement transferfrom we acutally need a second mapping this is the allowance mapping which maps from the owner address to the spender address to the allowance value this will autmatically create view function we don't need to make a view function public will make it view 
mapping(address => mapping (address => uint256))public allowance; //which map from owner address to the spender address to the allowance value 
//we need this mapping to store which owner address have approved how many funds for which spender address 

//     constructor(string memory _name, string memory _symbol) {
//         name = _name;
//         symbol =  _symbol;
        
// //internal function so we have to use on the contract so we just now do so we mint some token to the person who is deploying the contract
//         _mint(msg.sender, 100e18);       //if you remmber contract have 18 decimal so 100e18 is acutally this number //100 , 000 , 000 , 000 , 000 , 000 , 000       // so if we pass this number this would be just 100 token minted to the deployer //i know when i will deploy the contract here the person have 100 token automatically 

//     }
    

 constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol =  _symbol;
        
//we have mint call in the contructor we don't need any more as minting and buring is directly there in stable coin
    }


    function decimals() external pure returns (uint8){
    return 18;
    }




    function transfer(address recipient , uint256 amount) external returns (bool){    
    return _transfer(msg.sender , recipient , amount);        
    }


    function transferFrom( address sender  ,address recipient , uint256 amount) external returns (bool){    
    //before the transfer we have to make sure function call acutally allowed to make  transfer while  we don't want anyone to just else transfer someone token  
    uint256 currentAllowance = allowance[sender][msg.sender];//sender is sender but the spender is msg.sender from allowance mapping to get the amount of value that is approve by the owner to the spender to get the amount okay
    //revering  if the current allowance amount is <= amount if >= amount keep going
    require(currentAllowance >= amount , "ERC20: transfer amount exceeds allowance");
    //if the amount doesn't exceed from the actual approved amount then we updated the allowance mapping
    allowance[sender][msg.sender] =  currentAllowance - amount;      //so we update the allowance amount from the amount that is transfered 
    
emit Approval(sender , msg.sender , allowance[sender][msg.sender]);

    return _transfer(sender , recipient , amount);        
    }


//last thing missing is offcourse owner allow someone addres to spend the token on their behalf and that is appove function that in last we are implementing
    function approve(address spender , uint256 amount) external returns(bool){
    require(spender != address(0), "ERC20: approve to the zero address");
    allowance[msg.sender][spender] = amount;
    
    emit Approval(msg.sender , spender , amount);

    return true;
    }


// >> and that erc20 token was all function eplemented we have a contract now that implements all that required erc 20 function people can transfer the token     approve the tokens to other address and other address can tranfer approved tokens


    function _transfer(address sender , address recipient , uint256 amount) private returns (bool){    //private function is only able to access from this contract not from inherit or other external contract   
    require(recipient != address(0), "ERC20: transfer to the zero address");
    uint256 senderBalance = balanceOf[sender]; 
    require(senderBalance >= amount, "Not enough tokens"); 
    balanceOf[sender] = senderBalance - amount; 
    balanceOf[recipient] += amount;   
       
       emit Transfer(sender , recipient , amount);
       
        return true;     

    }


// >>>>>>> how we done almost one small aspect is still missing to call it a full erc20 token  functionally the contract is already finished you could deploy this to etherum main net and would  have a functioning erc20 token  contract but what still missing here is event 

function _mint(address to , uint256 amount) internal {         // the function mint tokens to an address and the amount
require(to != address(0), "ERC20: mint to the zero address"); 
totalSupply += amount;      //increase the total supply
balanceOf[to] += amount;     // change the balance on the balance of mapping //so off course this is an internal function we are not able to access outside and we have to use on the contract
       emit Transfer(address(0) , to , amount);
}


function _burn(address from , uint256 amount) internal {         // the function mint tokens to an address and the amount
require(from != address(0), "ERC20: burn from  the zero address"); 
totalSupply -= amount;      //increase the total supply
balanceOf[from] -= amount;     // change the balance on the balance of mapping //so off course this is an internal function we are not able to access outside and we have to use on the contract
       emit Transfer(from , address(0) , amount);
}





}

























