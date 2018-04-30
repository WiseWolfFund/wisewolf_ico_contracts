pragma solidity ^0.4.23;

 /* ERC223 additions to ERC20 */

import "./ERC223.sol";
import "./ERC223Receiver.sol";

//import "github.com/OpenZeppelin/zeppelin-solidity/contracts/token/StandardToken.sol";
import "./PausableToken.sol";

contract Pausable223Token is ERC223, PausableToken {
  //function that is called when a user or another contract wants to transfer funds
  function transfer(address _to, uint _value, bytes _data) public returns (bool success) {
    //filtering if the target is a contract with bytecode inside it
    if (!super.transfer(_to, _value)) revert(); // do a normal token transfer
    if (isContract(_to)) contractFallback(msg.sender, _to, _value, _data);
    emit Transfer(msg.sender, _to, _value, _data);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value, bytes _data) public returns (bool success) {
    if (!super.transferFrom(_from, _to, _value)) revert(); // do a normal token transfer
    if (isContract(_to)) contractFallback(_from, _to, _value, _data);
    emit Transfer(_from, _to, _value, _data);
    return true;
  }

  function transfer(address _to, uint _value) public returns (bool success) {
    return transfer(_to, _value, new bytes(0));
  }

  function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
    return transferFrom(_from, _to, _value, new bytes(0));
  }

  //function that is called when transaction target is a contract
  function contractFallback(address _origin, address _to, uint _value, bytes _data) private {
    ERC223Receiver reciever = ERC223Receiver(_to);
    reciever.tokenFallback(_origin, _value, _data);
  }

  //assemble the given address bytecode. If bytecode exists then the _addr is a contract.
  function isContract(address _addr) private view returns (bool is_contract) {
    // retrieve the size of the code on target address, this needs assembly
    uint length;
    assembly { length := extcodesize(_addr) }
    return length > 0;
  }
}
