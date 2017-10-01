pragma solidity ^0.4.17;

import '../utils/SafeMath.sol';
import '../ownership/Ownable.sol';

/**
@title Deed
@dev This Deed contract keeps trace of the amount of seeds locked by a user, and the block where tokens will be generated.
@dev A Deed contract can be destroyed after it's expiration, or renewed by the farm.
@dev If harvesting is skipped for 2 cycles, generated tokens are lost and seeds are expropriated.
 */
contract Deed is Ownable {
using SafeMath for uint256;

    address public user; // owner of seeds

    uint256 public seeds; // number of seeds
    uint256 public lockExpirationBlock; // harvesting is possible from this block
    uint256 public expropriationBlock; // expropriation is possible from this block
    uint256 public renewalCount; // counter of consecutive renewals

    /**
    @dev Throws if the contract is still locked
     */
    modifier onlyAfterLockExpiration() {
        require(block.number >= lockExpirationBlock);
        _;
    }

    /**
    @dev Deed constructor sets the harvesting user, the amount of seeds locked, the blocks needed to harvest tokens and the expropriation block limit.
    @dev _user The user address
    @dev _seeds The seeds locked
    @dev _growthBlocks The blocks needed to harvest tokens
    @dev _expropriationDelay The number of cycles to wait for expropriation
     */
    function Deed(address _user, uint256 _seeds, uint256 _growthBlocks, uint256 _expropriationDelay) public {
        seeds = _seeds;
        user = _user;
        renewalCount = 0;
        _update(_growthBlocks, _expropriationDelay);
    }

    /**
    @dev Farm contract can renew a deed, updating growth blocks and expropriation limit.
    @param _growthBlocks The blocks needed to harvest tokens
    @dev _expropriationDelay The number of cycles to wait for expropriation
     */
    function renew(uint256 _growthBlocks, uint256 _expropriationDelay) onlyOwner onlyAfterLockExpiration public {
        _update(_growthBlocks, _expropriationDelay);
        renewalCount = renewalCount.add(1);
    }

    /**
    @dev Farm contract can close a deed, destroying the contract, now useless.
    @dev Any funds are sent to owner, there should be none anyway.
     */
    function close() onlyOwner onlyAfterLockExpiration public {
        selfdestruct(owner);
    }

    /**
    @dev Shared logic to update deed blocks info.
    @param _growthBlocks The blocks needed to harvest tokens
    @dev _expropriationDelay The number of cycles to wait for expropriation
     */
    function _update(uint256 _growthBlocks, uint256 _expropriationDelay) private {
        lockExpirationBlock = block.number.add(_growthBlocks);
        expropriationBlock = lockExpirationBlock.add(_growthBlocks.mul(_expropriationDelay));
    }
}