pragma solidity ^0.4.17;

import '../utils/SafeMath.sol';

import './ERC20.sol';

/**
@title SeedToken
@dev Standard ERC20 token used as example seed to generate other tokens.
 */
contract SeedToken is ERC20 {
using SafeMath for uint256;

    string public name = "Seed";
    string public symbol = "SEED";

    uint256 public decimals = 0;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    /**
    @dev Constructor sets the token totalSupply.
    @param _totalSupply The total supply with decimals included.
     */
    function SeedToken(uint256 _totalSupply) public {
        totalSupply = _totalSupply;
        balances[msg.sender] = totalSupply;
    }

    /**
    @dev Gets the balance of the specified address.
    @param _owner The address to query the the balance of.
    @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    /**
    @dev transfer token for a specified address
    @param _to The address to transfer to.
    @param _amount The amount to be transferred.
    */
    function transfer(address _to, uint256 _amount) public returns (bool) {
        return _transfer(msg.sender, _to, _amount);
    }

    /**
    @dev Transfer tokens from one address to another
    @param _from address The address which you want to send tokens from
    @param _to address The address which you want to transfer to
    @param _amount uint256 the amount of tokens to be transferred
    */
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool) {
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        return _transfer(_from, _to, _amount);
    }

    /**
    @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    @param _spender The address which will spend the funds.
    @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
    @dev Function to check the amount of tokens that an owner allowed to a spender.
    @param _owner address The address which owns the funds.
    @param _spender address The address which will spend the funds.
    @return A uint256 specifying the amount of tokens still available for the spender.
    */
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /**
    @dev approve should be called when allowed[_spender] == 0.
    @dev To increment allowed value is better to use this function to avoid 2 calls (and wait until the first transaction is mined)
    */
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
    @dev approve should be called when allowed[_spender] == 0.
    @dev To decrement allowed value is better to use this function to avoid 2 calls (and wait until the first transaction is mined)
    */
    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
        allowed[msg.sender][_spender] = 0;
        } else {
        allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
    Shared logic for transfer functions.
     */
    function _transfer(address _from, address _to, uint256 _amount) private returns (bool) {
        require(_to != 0x0);
        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(_from, _to, _amount);
        return true;
    }
}