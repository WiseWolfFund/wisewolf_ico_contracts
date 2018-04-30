/*
Copyright (c) 2018 WiseWolf Ltd
Developed by https://adoriasoft.com
*/

pragma solidity ^0.4.23;


import "./oraclizeAPI.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./RefundVault.sol";
import "./WOLF.sol";


contract WolfSale is usingOraclize, Ownable, RefundVault
{
    uint8 public constant decimals = 18;
    uint public constant DECIMALS_MULTIPLIER = 10**uint(decimals);

    WOLF public token;
    address tokensSaleHolder;

    uint public  ICOstarttime;
    uint public  ICOendtime;
    
    uint public  minimumInvestmentInWei;
    uint public  maximumInvestmentInWei;
    address saleMainAddress;
    address saleSecondAddress;



    uint256 public  softcapInTokens;
    uint256 public  hardcapInTokens;
    
    uint256 public totaltokensold = 0;
    
    uint public USDETH = 683;
    uint public PriceOf1000TokensInUSD;
    
    //RefundVault public vault;
    bool public isFinalized = false;
    event Finalized();
    
    event newOraclizeQuery(string description);
    event newETHUSDPrice(string price);
    
    function finalize() public {
        require(!isFinalized);
        require(ICOendtime < now);
        finalization();
        emit Finalized();
        isFinalized = true;
    }
  
    function depositFunds() internal {
        vault_deposit(msg.sender, msg.value * 70 / 100);
    }
    
    // if crowdsale is unsuccessful, investors can claim refunds here
    function claimRefund() public {
        require(isFinalized);
        require(!goalReached());
        
        uint256 refundedTokens = token.balanceOf(msg.sender);
        require(token.transferFrom(msg.sender, tokensSaleHolder, refundedTokens));
        totaltokensold = totaltokensold.sub(refundedTokens);

        vault_refund(msg.sender);
    }
    
    // vault finalization task, called when owner calls finalize()
    function finalization() internal {
        if (goalReached()) {
            vault_releaseDeposit();
        } else {
            vault_enableRefunds();
            
        }
    }
    
    function releaseUnclaimedFunds() onlyOwner public {
        require(vault_state == State.Refunding && now >= refundDeadline);
        vault_releaseDeposit();
    }

    function goalReached() public view returns (bool) {
        return totaltokensold >= softcapInTokens;
    }    
    
    function __callback(bytes32 /* myid */, string result) public {
        require (msg.sender == oraclize_cbAddress());

        emit newETHUSDPrice(result);

        USDETH = parseInt(result, 0);
        if ((now < ICOendtime) && (totaltokensold < hardcapInTokens))
        {
            UpdateUSDETHPriceAfter(day); //update every 24 hours
        }
        
    }
    

  function UpdateUSDETHPriceAfter (uint delay) private {
      
    emit newOraclizeQuery("Update of USD/ETH price requested");
    oraclize_query(delay, "URL", "json(https://api.etherscan.io/api?module=stats&action=ethprice&apikey=YourApiKeyToken).result.ethusd");
       
  }


  

  constructor (address _tokenContract, address _tokensSaleHolder,
                address _saleMainAddress, address _saleSecondAddress,
                uint _ICOstarttime, uint _ICOendtime,
                uint _minimumInvestment, uint _maximumInvestment, uint _PriceOf1000TokensInUSD,
                uint256 _softcapInTokens, uint256 _hardcapInTokens) public payable {
                    
    token = WOLF(_tokenContract);
    tokensSaleHolder = _tokensSaleHolder;

    saleMainAddress = _saleMainAddress; /* 0x7CC8DD8F0E62Bb793D072D291134d2cC164AaBb6 */
    saleSecondAddress = _saleSecondAddress; /* 0x3597a7FacD5061F903309E911f2a6E534460b281 */
    vault_wallet = saleMainAddress;
    
    ICOstarttime = _ICOstarttime;
    ICOendtime = _ICOendtime;

    minimumInvestmentInWei = _minimumInvestment;
    maximumInvestmentInWei = _maximumInvestment;
    PriceOf1000TokensInUSD = _PriceOf1000TokensInUSD;

    softcapInTokens = _softcapInTokens;
    hardcapInTokens = _hardcapInTokens;
    
    UpdateUSDETHPriceAfter(0);
  }
  
  function RefillOraclize() public payable onlyOwner {
      UpdateUSDETHPriceAfter(0);
  }

  function  RedeemOraclize ( uint _amount) public onlyOwner {
      require(address(this).balance > _amount);
      owner.transfer(_amount);
  } 

  

  function () public payable {
       if (msg.sender != owner) {
          buy();
       }
  }
  
  function ICOactive() public view returns (bool success) {
      if (ICOstarttime < now && now < ICOendtime && totaltokensold < hardcapInTokens) {
          return true;
      }
      
      return false;
  }
  
  function buy() internal {
      
      require (msg.value >= minimumInvestmentInWei && msg.value <= maximumInvestmentInWei);
      require (ICOactive());
      
      uint256 NumberOfTokensToGive = msg.value.mul(USDETH).mul(1000).div(PriceOf1000TokensInUSD);
     
      if(now <= ICOstarttime + week) {

          NumberOfTokensToGive = NumberOfTokensToGive.mul(120).div(100);

      } else if(now <= ICOstarttime + 2*week){
          
          NumberOfTokensToGive = NumberOfTokensToGive.mul(115).div(100);
      
      } else if(now <= ICOstarttime + 3*week){
          
          NumberOfTokensToGive = NumberOfTokensToGive.mul(110).div(100);
          
      } else if(now <= ICOstarttime + 4*week){

          NumberOfTokensToGive = NumberOfTokensToGive.mul(105).div(100);
      }
      
      uint256 localTotaltokensold = totaltokensold;
      require(localTotaltokensold + NumberOfTokensToGive <= hardcapInTokens);
      totaltokensold = localTotaltokensold.add(NumberOfTokensToGive);
      
      require(token.transferFrom(tokensSaleHolder, msg.sender, NumberOfTokensToGive));

      saleSecondAddress.transfer(msg.value * 30 / 100);
      
      if(!goalReached() && (RefundVault.State.Active == vault_state)) {
          depositFunds();
      } else {
          if(RefundVault.State.Active == vault_state) { vault_releaseDeposit(); }
          saleMainAddress.transfer(msg.value * 70 / 100);
      }
  }
}
