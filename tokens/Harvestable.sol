pragma solidity ^0.4.11;

/**
@dev Interface describing an "Harvestable" tokens. It's the same as classic Mintable token.
 */
contract Harvestable {

    event Harvest(address indexed to, uint256 amount);

    modifier onlyHarvestAgent() {
        require(isAgent(msg.sender));
        _;
    }

    function isAgent(address addr) public constant returns (bool);
    function harvest(address to, uint256 value) onlyHarvestAgent public returns (bool);
    function setAgent(address addr, bool value) public;
}