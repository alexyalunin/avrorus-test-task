pragma solidity ^0.5.0;

import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';

contract CreditorRole is Ownable {
    address public creditor;
    
    event CreditorSet(address indexed previousCreditor, address indexed newCreditor);
    
    constructor () internal {
        creditor = owner();
        emit CreditorSet(address(0), owner());
    }
    
    modifier onlyCreditor() {
        require(msg.sender == creditor, "CreditorRole: caller is not the creditor");
        _;
    }
    
    function setCreditor(address _newCreditor) public onlyOwner() {
        require(_newCreditor != address(0), "CreditorRole: new creditor is the zero address");
        emit CreditorSet(creditor, _newCreditor);
        creditor = _newCreditor;
    }
}