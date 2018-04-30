pragma solidity ^0.4.23;

import './SafeMath.sol';
import './Ownable.sol';

/**
 * @title RefundVault
 * @dev This contract is used for storing funds while a crowdsale
 * is in progress. Supports refunding the money if crowdsale fails,
 * and forwarding it if crowdsale is successful.
 */
contract RefundVault {
  using SafeMath for uint256;

  enum State { Active, Refunding, Released}

  mapping (address => uint256) public vault_deposited;
  address public vault_wallet;
  State public vault_state;
  uint256 totalDeposited = 0;
  uint256 public refundDeadline;

  event DepositReleased();
  event RefundsEnabled();
  event RefundsDisabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);

  constructor() public {
    vault_state = State.Active;
  }

  function vault_deposit(address investor, uint256 _value) internal {
    require(vault_state == State.Active);
    vault_deposited[investor] = vault_deposited[investor].add(_value);
    totalDeposited = totalDeposited.add(_value);
  }

  function vault_releaseDeposit() internal {
    vault_state = State.Released;
    emit DepositReleased();
    if (totalDeposited > 0) {
        uint256 localTotalDeposited = totalDeposited;
        totalDeposited = 0;
        vault_wallet.transfer(localTotalDeposited);
    }
  }

  function vault_enableRefunds() internal {
    require(vault_state == State.Active);
    refundDeadline = now + 90 days;
    vault_state = State.Refunding;
    emit RefundsEnabled();
  }

  function vault_refund(address investor) internal {
    require(vault_state == State.Refunding);
    uint256 depositedValue = vault_deposited[investor];
    require(depositedValue > 0);
    
    vault_deposited[investor] = 0;
    emit Refunded(investor, depositedValue);
    totalDeposited = totalDeposited.sub(depositedValue);
    if(depositedValue != 0) {
        investor.transfer(depositedValue);
    }
  }
}
