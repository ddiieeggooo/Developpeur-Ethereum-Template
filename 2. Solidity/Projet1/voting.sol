// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract Voting is Ownable {

    mapping (address => bool)whitelistElecteurs;
    mapping (uint => Proposal)proposalId;

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    struct Proposal {
        string description;
        uint voteCount;
    }

    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }
    WorkflowStatus public currentWorkflowStatus;


    event VoterRegistered(address voterAddress);
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);

    Proposal[] public proposals;
    Voter[] public arrayDesElecteurs;

    function addAddrToWhitelist(address _whitelistedAddress) external onlyOwner {
        require(!whitelistElecteurs[_whitelistedAddress], "This address is already whitelisted !");
        whitelistElecteurs[_whitelistedAddress] = true;
        Voter[_whitelistedAddress].isRegistered = true;
        emit VoterRegistered(_whitelistedAddress);
    }

    function removeAddrFromWhitelist(address _addressToRmove) external OnlyOwner {
        require(whitelistElecteurs[_addressToRemove], "This address is not whitelisted !");
        whitelistElecteurs[_addressToRemove] = false;
        Voter[_addressToRemove].isRegistered = false;
        arrayDesElecteurs(whitelistElecteurs[_addressToRemove]).pop;
    }

    function changeWorkflowStatus(string calldata previousStatus, string calldata _newStatus) external onlyOwner {
        require(_newStatus == currentWorkflowStatus, "This is not a valid Worflow status");
        require(_newStatus != currentWorkflowStatus, "This is already the current Workflow status");
        WorkflowStatus = previousStatus;
        currentWorkflowStatus = WorkflowStatus._newStatus;
        emit WorkflowStatusChange(previousStatus, _newStatus);
    }

    function submitProposal(string calldata _newProposal, uint voteCount) external {
        require(whitelistElecteurs[msg.sender] ==  true, "You can't make a proposal since you're not whitelisted");
        require(currentWorkflowStatus = WorkflowStatus.ProposalsRegistrationStarted, "Sorry. It's not the time for a proposal");
        Proposal memory newProposal = Proposal(_newProposal, voteCount);
        proposals.push(newProposal);
        if (proposals.length != 0) {
            emit ProposalRegistered(proposals.lenght ++);
        } else emit ProposalRegistered(1);
    }

    function vote(uint _proposalId) external {
        require(currentWorkflowStatus == WorkflowStatus.VotingSessionStarted, "Sorry. It's not the time for voting");
        proposals[_proposalId].voteCount++;
        Voter[msg.sender].hasVoted = true;
        Voter[msg.sender].votedProposalId = _proposalId;
        proposalId = _proposalId;
        emit Voted(msg.sender, proposalId);
    }

    function getWinner() external view onlyOwner returns(uint _winningProposalId) {
        require(currentWorkflowStatus == WorkflowStatus.VotingSessionEnded, "You can't count votes for now");
        uint winnerTotalVotes;
        uint winningProposalId;
        for (uint i = 0; i < proposals.lenght; i++) {
            if (Proposal[i].voteCount > winnerTotalVotes) {
                winnerTotalVotes = Proposal[i].voteCount;
                _winningProposalId = i;
            }
        }
        _winningProposalId = winningProposalId;
        return winningProposalId;
    }

    function getVoteOf(address addr) external view returns(uint) {
        require(whitelistElecteurs[msg.sender] ==  true, "You can't access this information");
        return Voter[addr].votedProposalId;
    }


    function detailsOfWinnerProposal(uint winningProposalId) external view returns(string calldata description, uint voteCount, address _addr0fPropositon) {
        require(currentWorkflowStatus == WorkflowStatus.VotesTallied, "There is no winner yet");
        return arrayDesElecteurs[proposals[winningProposalId]].description;
        return arrayDesElecteurs[proposals[winningProposalId]].voteCount;
        return winningProposalId(msg.sender);
    }

}
