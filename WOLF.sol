/*
Copyright (c) 2018 WiseWolf Ltd
Developed by https://adoriasoft.com
*/

pragma solidity ^0.4.23;




import "./SafeMath.sol";
import "./Ownable.sol";
import "./BurnableToken.sol";
import "./Pausable223Token.sol";


contract WOLF is BurnableToken, Pausable223Token
{
    string public constant name = "WiseWolf";
    string public constant symbol = "WOLF";
    uint8 public constant decimals = 18;
    uint public constant DECIMALS_MULTIPLIER = 10**uint(decimals);
    
    function increaseSupply(uint value, address to) public onlyOwner returns (bool) {
        totalSupply_ = totalSupply_.add(value);
        balances[to] = balances[to].add(value);
        emit Transfer(address(0), to, value);
        return true;
    }

    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        uint256 localOwnerBalance = balances[owner];
        balances[newOwner] = balances[newOwner].add(localOwnerBalance);
        balances[owner] = 0;
        emit Transfer(owner, newOwner, localOwnerBalance);
        super.transferOwnership(newOwner);
    }
    
    constructor () public payable {
      totalSupply_ = 1300000000 * DECIMALS_MULTIPLIER; //1000000000 + 20% bounty + 5% referal bonus + 5% team motivation
      balances[owner] = totalSupply_;
      emit Transfer(0x0, owner, totalSupply_);
    }
}