//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract main {

    address public owner;
    mapping (address => uint) public funders;
    uint public goal;
    uint public minAmount;
    uint public noOfFounders;
    uint public fundsRaised;
    uint public timePeriod; //timestamp

    constructor(uint _goal, uint _timePeriod){
        goal = _goal;
        timePeriod = block.timestamp + _timePeriod;
        owner = msg.sender;
        minAmount = 1000 wei;
    }

    receive () payable external{}

    modifier isOwner(){
        require(owner == msg.sender, "You are not owner");
        _;
    }

    function contribution() public payable{
        require(block.timestamp < timePeriod, "Funding is over!");
        require(msg.value >= minAmount, "Minimum amount criteria not satisfy");

        if(funders[msg.sender] == 0){
            noOfFounders++;
        }
        
        funders[msg.sender] += msg.value;
        fundsRaised += msg.value;
    }

    function getRefund() public {
        require(block.timestamp > timePeriod, "Funding is still on!");
        require(fundsRaised < goal, "Funding was successful");
        require(funders[msg.sender] > 0, "Not a funder");

        payable(msg.sender).transfer(funders[msg.sender]);
        fundsRaised -= funders[msg.sender];
        funders[msg.sender] = 0;
    }

    struct Requests{
        string description;
        uint amount;
        address payable receiver;
        uint noOfVotes;
        mapping(address => bool) votes;
        bool completed;
    }

    mapping (uint => Requests) public AllRequests;
    uint public numReq;

    function createRequests(string memory _description, uint _amount, address payable _receiver) public isOwner{
        Requests storage newRequest = AllRequests[numReq];
        numReq++;

        newRequest.description = _description;
        newRequest.amount = _amount;
        newRequest.completed = false;
        newRequest.noOfVotes = 0;
        newRequest.receiver = _receiver;
    }

    function votingForRequest(uint _reqNum) public{
        require(funders[msg.sender] > 0, "Not a funder");
        Requests storage thisRequest = AllRequests[_reqNum];
        require(thisRequest.votes[msg.sender] == false, "Already voted");
        thisRequest.votes[msg.sender] = true;
        thisRequest.noOfVotes++;
    }

    function makePayment(uint _reqNum) public {
        Requests storage thisRequest = AllRequests[_reqNum];
        require(thisRequest.completed == false, "Completed Already");
        require(thisRequest.noOfVotes >= noOfFounders / 2, "Voting not in favor!");
        thisRequest.receiver.transfer(thisRequest.amount);
        thisRequest.completed = true;
    }

}