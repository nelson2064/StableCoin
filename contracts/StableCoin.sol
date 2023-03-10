
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;
import {ERC20} from "./ERC20.sol";
import {DepositorCoin} from "./DepositorCoin.sol";
import {Oracle} from "./Oracle.sol"; //and now we pass the address of the oracle up on deploymnet so basically if some ones wants to deploy first has to deploy the oracle and then pass the address of the oracle to the stable coin when he deploys the stable coin
import {WadLib} from "./WadLib.sol";
contract StableCoin is ERC20{
using WadLib for uint256 ; //this library now avalilable for uint256



DepositorCoin public depositorCoin;
Oracle public oracle;



//defining a custom error 
error InitialCollateralRatioError(string message , uint256 minimumDepositAmount);

// uint256 private constant ETH_IN_USD_PRICE = 2000;
uint256 public feeRatePercentage;

uint256 public constant INITIAL_COLLATERAL_RATIO_PERCENTAGE = 10;

    constructor(uint256 _feeRatePercentage , Oracle _oracle) ERC20("Stablecoin", "STC"){
        feeRatePercentage = _feeRatePercentage;
        oracle = _oracle;
    }

//lets implment this mint function people are using deposti ether into the contract and getting stable coin
function mint() external payable{
    uint256 fee = _getFee(msg.value); //fee for minting we wil use the private function that implement in a second so to figure out what the actual fee the mintor or depositor here is paying
uint256 remainingEth = msg.value - fee; //the remaining eth after subtracting with the fee
    // uint256 mintStableCoinAmount = msg.value *  ETH_IN_USD_PRICE;         //amount of ether send msg.value * price of ether in us dollar as our stable coin is pecked to the us dollar
    //    uint256 mintStableCoinAmount = remainingEth *  ETH_IN_USD_PRICE;  
          uint256 mintStableCoinAmount = remainingEth *  oracle.getPrice();  
    _mint(msg.sender , mintStableCoinAmount);
}



function burn(uint256 burnStableCoinAmount) external {//not payable because we are doing opposite burning the stable coin
    
    //d s end
    int256 deficitOrSurplusInUsd = _getDefictOrSurplusInContractInUsd();
    require(deficitOrSurplusInUsd >= 0 , "STC: Cannot burn while in deficit");
    
    _burn(msg.sender, burnStableCoinAmount); 
    //now we have to calculate how much eth  he is getting 
    // uint256 refundingEth = burnStableCoinAmount / ETH_IN_USD_PRICE; //   we have to calculate how much eth he is getting so refunding him now his eth there would be 
    uint256 refundingEth = burnStableCoinAmount / oracle.getPrice();
    uint256 fee = _getFee(refundingEth);
    uint256 remainingRefundingEth = refundingEth - fee;

    (bool success,) = msg.sender.call{value: remainingRefundingEth}("");//call functionality using           we will send him eth and empty data because we are sending only eth to his address
    require(success , "STC: Burn refund transaction failed"); //lets check the transfer is successfull if not then revert the transaction with message 
}


function _getFee(uint256 ethAmount) private view returns(uint256){
    bool hasDepostiors = address(depositorCoin) != address(0) && depositorCoin.totalSupply() > 0    ;     // add little functionality here to check if there are already any depositors for depositor coin and those will be  the ones actually receiving the fee  so will convert the  contract depositor coin to an address and we will chek if it is a 0 address because if it a 0 address it means it is not deployed yet and there are not any depostiors yet and also  we make sure deppostiorcoin.totalsupply() should be more then 0
   if(!hasDepostiors){ //if there is not depositors you don't have to pay any fee because there is not depostiors so the first people calling mint don't have to pay actually any fee
    return 0;

   }
    return(feeRatePercentage * ethAmount) / 100     ;    //fee rate the person who is deploying the stable coin contract can define the rate so will pass in the contructor  
}
    








function depostiCoilateralBuffer() external payable{              //obiously someone is doing this they are sending ethere so paybale external function and eventually  he will  receive  the depositor coin token in return 
    int256 deficitOrSurplusInUsd = _getDefictOrSurplusInContractInUsd();

if(deficitOrSurplusInUsd <= 0 ){         ////this is the normal case when depositor coin already exist now we have to implement other case when deficitorsurplus <= 0 so in the case when first person calling this deposit or even if the contract actually negative in deflicit we have to figure out how much now mint to this person  
    uint256 deficitInUsd = uint256(deficitOrSurplusInUsd * -1); //int 256 into uint256 becuase we know this is now negative num;ber it represent deficit in usd so we can do is convert in uint256 and multiply with negative one   because now we know this is  positve number but represnt deficit   
    uint256 usdInEthPrice = oracle.getPrice(); //we need orcale price also 
    uint256 deficitInEth = deficitInUsd / usdInEthPrice; 

//safety cheque

uint256 requiredInitialSurplusInUsd = (INITIAL_COLLATERAL_RATIO_PERCENTAGE * totalSupply) / 100;
uint256 requiredInitialSurplusInEth = requiredInitialSurplusInUsd / usdInEthPrice;


//to change to use our custom error 
// require(
//     msg.value >= deficitInEth + requiredInitialSurplusInEth,
//     "STC: Inital collateral ratio not met"
// );

if(msg.value < deficitInEth + requiredInitialSurplusInEth){
    uint256 minimumDepositAmount = deficitInEth + requiredInitialSurplusInEth;
    revert InitialCollateralRatioError("STC: Initial collateral ratio not met, minimum is" , minimumDepositAmount); // so now we can revert with the custom  error first take the message and minimum amount
}
//the advantage of custom error is someone actually now know how much  amount alt least  they should deposit 


//we can calculate new inital surplus in eth first which is basically
                                         // so the value msg.value so the amount of the ether the person was sending is lower then deficit there will be underflow and transaction will revert so to make it safer lets add little bit ratio for first depositor so he doens'nt deposit just deposit enough and would be basically  lequidate potentially  immediately afterwards for that we add little safety cheque 
    uint256 newInitialSurplusInEth = msg.value - deficitInEth;    //at first deficit is <=0  but if its negative then deficit here would be postive value not zero 
  uint256 newInitialSurplusInUsd = newInitialSurplusInEth * usdInEthPrice;//converting into usd

//we can deploy the depositor coin so this is the first time depositorCollateralBuffer call or when the contract is in negative deficit we destory the previous depostiro coin we do by basciall deploying a new contract 
    depositorCoin = new DepositorCoin();
   uint256 mintDepostorCoinAmount = newInitialSurplusInUsd;//we calculate the amount that we want to mint 

    depositorCoin.mint(msg.sender, mintDepostorCoinAmount);

    return;
}

uint256 surplusInUsd = uint256(deficitOrSurplusInUsd);

// uint256 dpcInUsdPrice = _getDPCinUsdPrice(surplusInUsd); //we have to figure out what is the price of depositor coin before we can acutally minted for the user so lets calculated depositorcoininusd(dpcInUsdPrice)
// uint256 mintDepositorCoinAmount = ((msg.value * dpcInUsdPrice)  / oracle.getPrice()); //calculating the amount of token we want to mint for the depositors that will be                          so this will basically give us how many tokens we have to mint for new depositor coin        >> gives us total amount we have to mint


WadLib.Wad dpcInUsdPrice = _getDPCinUsdPrice(surplusInUsd); //we have to figure out what is the price of depositor coin before we can acutally minted for the user so lets calculated depositorcoininusd(dpcInUsdPrice)
uint256 mintDepositorCoinAmount = ((  msg.value.mulWad(dpcInUsdPrice) )  / oracle.getPrice()); //calculating the amount of token we want to mint for the depositors that will be                          so this will basically give us how many tokens we have to mint for new depositor coin        >> gives us total amount we have to mint


depositorCoin.mint(msg.sender , mintDepositorCoinAmount); // this is the normal case where depositor coin already exist  now we have to implement other case when deficitorsurplus is 0 or negative <=0

//this is the normal case when depositor coin already exist now we have to implement other case when deficitorsurplus <= 0 so in the case when first person calling this deposit or even if the contract actually negative in deflicit we have to figure out how much now mint to this person
}


 


//2nd withdraw function  

function withdrawCollateralBuffer(uint256 burnDeposiotrCoinAmount) external{
    require(depositorCoin.balanceOf(msg.sender) >= burnDeposiotrCoinAmount, "STC: Sender has insuffient DPC funds");
    depositorCoin.burn(msg.sender , burnDeposiotrCoinAmount);
//now we have to figure out how much eth should send him for his burn transaction remeber we have the function to calculate the price and off course depositor coins here  only worth something if the contract is not in a deficit so we know how to check  for deficit or surplus
int256 deficitOrSurplusInUsd = _getDefictOrSurplusInContractInUsd(); //

require(deficitOrSurplusInUsd > 0 , "STC: NO funds to withdraw"); //if positive we let take to other move other wise revert
// ok if surpllus then 
uint256 surplusInUsd = uint256(deficitOrSurplusInUsd); // so now we know ther is surplus now convert surplus in usd 

// uint256 dpcInUsdPrice = _getDPCinUsdPrice(surplusInUsd); // we pass the surplus in usd
// uint256 refundingUsd = burnDeposiotrCoinAmount * dpcInUsdPrice; //the amount refunding him in usd is 

WadLib.Wad dpcInUsdPrice = _getDPCinUsdPrice(surplusInUsd); // we pass the surplus in usd
uint256 refundingUsd = burnDeposiotrCoinAmount.mulWad(dpcInUsdPrice); //the amount refunding him in usd is 


uint256 refundingEth = refundingUsd / oracle.getPrice();   //now lets quickly convert in eth 
//send back to him 
(bool success , ) = msg.sender.call{ value: refundingEth}("");    //sending back to him 
require(success , "STC: Withdraw refund transaction failed");    //checking if it succesfull or not otherwaise show this message


}










//  >>>>>>>>> //we have implmented the minting and burining of our stable coin  token so people can deposit eth and they get stable coin in return and they can use and burn stable coin to  return eth back but we don't have this function for depositors to put extra eth in so now we will implement function for depositor which will use the depositor contract that we implemented   for that first implement private view function

    function _getDefictOrSurplusInContractInUsd() private view returns (int256){          //lets implement the private view function we will need this private function several time to basically figure out what is the current amount of surplus for the depositors remeber depostiors will be the ones  who own the surplus and we also need to figure out should the contract ever have not enough fund backing all the stabele coin 
        // uint256 ethContractBalanceInUsd = (address(this).balance - msg.value) //so what is the depecit or surplus in the contract in us dollar well its                  so first we check the current balance of the contract by address this.balance and we will subract msg.value this here basically tell us  what is the amount of ether in the contract before someone is calling function here and we subtract msg.value because someone is currently adding to the contract so we want to know what was the balance before  that so we subtract msg.value      so this is the amount of ether and now we want to have it in us dollar 
         uint256 ethContractBalanceInUsd = (address(this).balance - msg.value) * oracle.getPrice();//his gives us the balance before the current transaction was executed.
   uint256 totalStableCoinBalanceInUsd = totalSupply;  //remeber the contract here self is a erc20 so  we can use totalsupply state variable to check how many stable coin are in existence right now  
   int256 deficitOrSurplus = int256(ethContractBalanceInUsd) - int256(totalStableCoinBalanceInUsd) ;                       //it can be postitve or negative so int
   
   return deficitOrSurplus;
    }
//so this is the private function that we can use for our deposit functionn so lets implement depositCollateralBuffer function 
    

    // function _getDPCinUsdPrice(uint256 surplusInUsd) private view returns (uint256){
    //     return depositorCoin.totalSupply() / surplusInUsd;              //we are dividng here so there can be fixed point number so we are loosing some if we do in this way one solution will be  
    // }




   function _getDPCinUsdPrice(uint256 surplusInUsd) private view returns (WadLib.Wad){
        return  WadLib.fromFraction(depositorCoin.totalSupply() , surplusInUsd);              //we are dividng here so there can be fixed point number so we are loosing some if we do in this way one solution will be  
    }
}

