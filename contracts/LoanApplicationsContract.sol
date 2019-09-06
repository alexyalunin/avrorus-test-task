pragma solidity ^0.5.0;

import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';
import "openzeppelin-solidity/contracts/cryptography/ECDSA.sol";
import "./CreditorRole.sol";
import "./Utils.sol";


contract LoanApplicationContract is Ownable, CreditorRole {
    
    using ECDSA for bytes32;
    using Utils for uint;
    
    struct Application {
        address payable borrower;
        address payable creditor;
        bool completedByBorrower;
        bool completedByCreditor;
        uint amountRequested;
        uint amountApproved;
    }
    
    mapping (address => mapping (uint => bool)) public borrowerToNonce; // to handle delegate calls
    Application[] public applications;
    
    event ApplicationCreated(uint indexed id, address indexed borrower, uint requested);
    event ApplicationApproved(uint indexed id, address indexed creditor, uint requested, uint approved);
    event ApplicationRejected(uint indexed id);
    event ApplicationAccepted(uint indexed id);
    event ApplicationCancelled(uint indexed id);
   
    
    modifier applicationIsNotCompletedByCreditor(uint _id) {
        require(_id < applications.length, "LoanApplicationContract: application _id is out of bounds");
        Application memory app = applications[_id];
        require(!app.completedByCreditor, "LoanApplicationContract: application is already completed by creditor");
        _;
    }
    
    modifier applicationIsReadyForBorrower(uint _id, address _borrower) {
        require(_id < applications.length, "LoanApplicationContract: application _id is out of bounds");
        Application memory app = applications[_id];
        require(app.borrower == _borrower, "LoanApplicationContract: borrower is not correct");
        require(app.completedByCreditor, "LoanApplicationContract: application is not yet completed by creditor");
        require(app.amountApproved > 0, "LoanApplicationContract: application is rejected by creditor");
        require(!app.completedByBorrower, "LoanApplicationContract: application is already completed be borrower");
        _;
    }


    constructor () public { 
        
    }
    
    // Заемщик может подать заявку на кредит на любую сумму
    function createApplication(uint _amount) external returns(uint) {
        return _createApplication(msg.sender, _amount);
    }
    
    function _createApplication(address payable _borrower, uint _amount) internal returns(uint) {
        require(_amount != 0, "LoanApplicationContract: amount should be more than zero");
        
        Application memory app = Application({
            borrower: _borrower,
            creditor: address(0),
            completedByCreditor: false,
            completedByBorrower: false,
            amountRequested: _amount,
            amountApproved: 0
        });
        uint newAppId = applications.push(app) - 1;
        
        emit ApplicationCreated(newAppId, msg.sender, _amount);
        
        return newAppId;
    }
    
    // Кредитор может одобрить запрос на запрашиваемую или меньшую сумму
    function approveApplication(uint _id) 
        payable 
        external 
        onlyCreditor 
        applicationIsNotCompletedByCreditor(_id)
    {
        require(msg.value > 0);
        Application storage app = applications[_id];
        require(msg.value <= app.amountRequested, "LoanApplicationContract: amount to be approved is more than requested");
        app.creditor = msg.sender;
        app.completedByCreditor = true;
        app.amountApproved = msg.value;
        
        emit ApplicationApproved(_id, msg.sender, app.amountRequested, msg.value);
    }
    
    // Кредитор может отклонить запрос
    function rejectApplication(uint _id) 
        external 
        onlyCreditor 
        applicationIsNotCompletedByCreditor(_id) 
    {
        Application storage app = applications[_id];
        app.completedByCreditor = true;
        
        emit ApplicationRejected(_id);
    }
    
    // Заемщик может принять одобренную заявку (Ether отправляется ему)
    function acceptApplication(uint _id) external {
        _acceptApplication(_id, msg.sender);
    } 
    
    function _acceptApplication(uint _id, address _borrower) internal applicationIsReadyForBorrower(_id, _borrower) {
        Application storage app = applications[_id];
        app.completedByBorrower = true;
        app.borrower.transfer(app.amountApproved);
        
        emit ApplicationAccepted(_id);
    } 
    
    
    // Заемщик может отклонить заявку (Ether возвращается Кредитору)
    function cancelApplication(uint _id) external applicationIsReadyForBorrower(_id, msg.sender) {
        Application storage app = applications[_id];
        app.completedByBorrower = true;
        app.creditor.transfer(app.amountApproved);
        
        emit ApplicationCancelled(_id);
    } 


    // Заемщик может оффчейн делегировать запрос на создание и принятие заявки другому пользователю, но заявка в контракте должна принадлежать заемщику
    function delegatedCreateApplication(
        address payable _signer, 
        uint _nonce, 
        uint _amount, 
        bytes32 _hash, 
        bytes calldata _signature
    ) external returns(uint) {
        require(_signer != address(0), "LoanApplicationContract: signer can not be zero address");
        require(_amount > 0, "LoanApplicationContract: amount has to be grater than zero");
        require(!borrowerToNonce[_signer][_nonce], "LoanApplicationContract: nonce is already used");
        borrowerToNonce[_signer][_nonce] = true; // stack is too deep error fix
        
        string memory nonceStr;
        string memory amountStr;
        uint nonceStrLen;
        uint amountStrLen;
        
        (nonceStr, nonceStrLen) = _nonce.uint2str();
        (amountStr, amountStrLen) = _amount.uint2str();
        uint totalLen = nonceStrLen + amountStrLen + 37;
        string memory lenStr;
        (lenStr, ) = totalLen.uint2str();
        
        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", 
                                                lenStr, 
                                                'Create Application, Nonce: ', 
                                                nonceStr, 
                                                ', Amount: ', 
                                                amountStr));
        require(hash == _hash, "LoanApplicationContract: hash is not correct");
        address signer = _hash.recover(_signature);
        require(signer == _signer, "LoanApplicationContract: signature is not correct");
        
        return _createApplication(_signer, _amount);
    }
    
    function delegatedAcceptApplication(
        address payable _signer, 
        uint _id, 
        bytes32 _hash, 
        bytes calldata _signature
    ) external {
        require(_signer != address(0), "LoanApplicationContract: signer can not be zero address");
        
        string memory idStr;
        uint idStrLen;
        
        (idStr, idStrLen) = _id.uint2str();
        uint totalLen = idStrLen + 24;
        string memory lenStr;
        (lenStr, ) = totalLen.uint2str();
        
        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", 
                                                lenStr, 
                                                'Accept Application, Id: ', 
                                                idStr));
        require(hash == _hash, "LoanApplicationContract: hash is not correct");
        address signer = _hash.recover(_signature);
        require(signer == _signer, "LoanApplicationContract: signature is not correct");
        
        _acceptApplication(_id, _signer);
    }
    
}