// SPDX-Licence-Identifier: MIT

pragma solidity ^0.8.0;

contract crowdFunding{

    address public manager;
    uint public minContribution;
    uint public noOfContributers;
    uint public target;
    uint public raisedAmount;
    uint public deadline;
    bool public contributeCompleted;
    mapping(address => uint) public contributers;

    struct Request{
        address payable recipient;
        string description;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping(address => bool) voters;
    }
    
    mapping(uint => Request) public requests;
    uint public requestId;
    
    constructor(uint _target, uint _deadline){
        manager = msg.sender;
        target = _target;
        deadline = block.timestamp + _deadline;
        minContribution = 1000 wei;
    }

    modifier isManager(){
        require(msg.sender == manager, "You can not access!");
        _;
    }

    function contribute() public payable{
        require(deadline > block.timestamp, "Deadline is passed!");
        require(minContribution <= msg.value, "Minimum contribution is not met!");
        require(target >= msg.value);
        require(contributeCompleted == false, "Target is Completed!");
        if(contributers[msg.sender] == 0) {
            noOfContributers++;
        }
        contributers[msg.sender] += msg.value;
        raisedAmount += msg.value;
        if(target <= raisedAmount){
            contributeCompleted = true;
        }
    }

    function refund() public payable{
        require(deadline < block.timestamp && contributeCompleted == false, "You are not eligiable for refund!");
        require(contributers[msg.sender] > 0);
        payable(msg.sender).transfer(contributers[msg.sender]);
        contributers[msg.sender] = 0;
    }

    function createRequest(address payable _recipient, string memory _description, uint _value) public isManager(){
        Request storage request = requests[requestId];
        request.recipient = _recipient;
        request.description = _description;
        request.value = _value;
        request.completed = false;
        requestId++;
    }

    function voteRequest(uint _requestId) public{
        Request storage request = requests[_requestId];
        require(contributers[msg.sender] > 0, "You must be a contributer");
        require(request.voters[msg.sender] == false, "You already voted!");
        require(request.completed == false, "Request is completed!");
        request.voters[msg.sender] = true;
        request.noOfVoters++;
    }

    function makePayment(uint _requestId) public payable isManager(){
        Request storage request = requests[_requestId];
        require(request.completed == false, "Request has been completed!");
        require(contributeCompleted == true, "You don't have enough fund!");
        require(request.noOfVoters > noOfContributers / 2, "Majority does not support!");
        request.recipient.transfer(request.value);
        raisedAmount -= request.value;
        request.completed = true;
    }

}