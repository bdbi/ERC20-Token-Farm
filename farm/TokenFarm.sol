pragma solidity ^0.4.17;

import '../utils/SafeERC20.sol';
import '../utils/SafeMath.sol';

import '../ownership/Ownable.sol';

import '../tokens/SeedToken.sol';
import '../tokens/Token.sol';
import './Deed.sol';

/**
@title SimpleFarm
 */
contract TokenFarm is Ownable {
using SafeMath for uint256;
using SafeERC20 for SeedToken;
using SafeERC20 for Token;

    // tokens
    SeedToken seedToken;
    Token harvestableToken;

    // mappings
    mapping(address => address) deedOwners; // deed => user
    mapping(address => uint256) balances; // user => balance
    mapping(address => bool) automaticRenewal; // user => opt
    mapping(address => bool) automaticWithdrawal; // user => opt

    uint256 public expropriatedSeeds;

    // settings
    uint256 public growthRate = 100; // number of tokens produced per seed (in this case with 2 decimals the rate is 1 token per seed)
    uint256 public growthBlocks = 350000; // blocks needed to grow
    uint256 public expropriationDelay = 2; // cycle of growth

    // events
    event DeedCreated(address indexed who, uint256 seeds, address indexed addr);
    event DeedRenewed(address indexed deed);
    event DeedClosed(address indexed deed);
    event Withdrawal(address indexed who, uint256 tokens);
    event Expropriation(address indexed deed, uint256 seeds);

    /**
    @dev TokenFarm constructor sets the seed token and the harvestable token.
    @param _seed Seed token address
    @param _harvestable Harvestable token address
     */
    function TokenFarm(address _seed, address _harvestable) public {
        seedToken = SeedToken(_seed);
        harvestableToken = Token(_harvestable);
    }

    /**
    @dev User can lock seeds and set renewal and withdrawal options.
    @dev This operation spawns a new contract which describes the amount of seeds locked and the minimum harvesting block.
    @param _amount The amount of seeds to lock
    @param _automaticRenewal A bool set true to enable the automatic seed lock after harvesting, false otherwise
    @param _automaticWithdrawal A bool set true to enable the automatic withdrawal of harvested tokens, false otherwise
    @return The address of the harvesting contract
     */
    function plant(uint256 _amount, bool _automaticRenewal, bool _automaticWithdrawal) public returns (address deed) {
        setAutomaticRenewal(_automaticRenewal);
        setAutomaticWithdrawal(_automaticWithdrawal);
        return plant(_amount);
    }

    /**
    @dev User can lock seeds, renewal and withdrawal options are left unmodified.
    @dev This operation spawns a new contract which describes the amount of seeds locked and the minimum harvesting block.
    @param _amount The amount of seeds to lock
    @return The address of the harvesting contract
     */
    function plant(uint256 _amount) public returns (address deed) {
        require(_amount > 0);
        seedToken.safeTransferFrom(msg.sender, this, _amount);
        deed = new Deed(msg.sender, _amount, growthBlocks, expropriationDelay);
        deedOwners[deed] = msg.sender;
        DeedCreated(msg.sender, _amount, deed);
    }

    /**
    @dev User can harvest his seeds.
    @dev If 'automaticRenewal' is true the deed is updated with current growthBlocks and expropriationDelay, it is destroyed otherwise.
    @dev If 'automaticWithdrawal' is true tokens are sent to user address, otherwise are ready for manual withdrawal.
    @param _deed The harvesting contract address
     */
    function harvest(address _deed) public {
        require(msg.sender == deedOwners[_deed]);

        Deed deed = Deed(_deed);
        uint256 tokens = deed.seeds().mul(growthRate);

        if (automaticRenewal[msg.sender]) {
            DeedRenewed(_deed);
            deed.renew(growthBlocks, expropriationDelay);
        } else {
            DeedClosed(_deed);
            deed.close();
            delete deedOwners[_deed];
            seedToken.safeTransfer(msg.sender, deed.seeds());
        }

        if (automaticWithdrawal[msg.sender]) {
            _withdraw(msg.sender, tokens);
        } else {
            balances[msg.sender] = balances[msg.sender].add(tokens);
        }
    }

    /**
    @dev Checks the tokens balance of the passed account.
    @param _owner The account's address
    @return The account0s balance
     */
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    /**
    @dev Withdraws the passed amount of tokens from balance.
    @param _amount The amount of token to withdraw
     */
    function withdraw(uint256 _amount) public {
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        _withdraw(msg.sender, _amount);
    }

    /**
    @dev Sets the automatic renewal option.
    @param _value True to enable, false otherwise
     */
    function setAutomaticRenewal(bool _value) public {
        automaticRenewal[msg.sender] = _value;
    }

    /**
    @dev Sets the automatic withdrawal option.
    @param _value True to enable, false otherwise
     */
    function setAutomaticWithdrawal(bool _value) public {
        automaticWithdrawal[msg.sender] = _value;
    }

    /**
    @dev Farm owner can expropriate seeds left unclaimed in some harvesting contract.
    @dev Expropriation can happen only if current block is >= expropriationBlock found in deed contract.
    @dev Potentially harvested tokens are lost, only seeds are recovered to be reassigned (by airdrop or auction).
    @param _deed Harvesting contract address
     */
    function expropriate(address _deed) onlyOwner public {
        Deed deed = Deed(_deed);

        require(deed.user() == deedOwners[_deed]);
        require(deed.expropriationBlock() >= block.number);

        uint256 seeds = deed.seeds();
        deed.close();
        delete deedOwners[_deed];

        expropriatedSeeds = expropriatedSeeds.add(seeds);

        DeedClosed(_deed);
        Expropriation(_deed, seeds);
    }

    /**
    @dev Sets the seeds growth rate, it is not retroactive.
    @param _value Tokens produced from 1 seed
     */
    function setGrowthRate(uint256 _value) onlyOwner public {
        require(_value > 0);
        growthRate = _value;
    }

    /**
    @dev Sets the blocks needed to harvest tokens, it is not retroactive.
    @param _value Number of blocks needed to harvest tokens.
     */
    function setGrowthBlocks(uint256 _value) onlyOwner public {
        require(_value > 0);
        growthBlocks = _value;
    }

    /**
    @dev Shared logic for withdraw functions, sends tokens to the receiver address and fires related event.
    @param _address The address withdrawing tokens
    @param _amount The amount of tokens being withdrawn
     */
    function _withdraw(address _address, uint256 _amount) private {
        harvestableToken.harvest(_address, _amount);
        Withdrawal(_address, _amount);
    }

}