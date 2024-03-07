// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

/// @title Un contrat intelligent pour un processus de vote simple dans le cadre de la formation Alyra
/// @notice Ce contrat permet d'enregistrer des votants, de proposer des choix, de voter et de comptabiliser les votes
/// @dev Le contrat est Ownable, ce qui signifie que le propriétaire du contrat peut ajouter des votants et changer le statut du processus de vote
contract Voting is Ownable {
    uint public winningProposalID;

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

    WorkflowStatus public workflowStatus;
    Proposal[] public proposalsArray;
    mapping(address => Voter) public voters;

    /// @notice Emit lorsqu'un votant est enregistré
    /// @param voterAddress L'adresse du votant
    event VoterRegistered(address voterAddress);

    /// @notice Emit lorsqu'un changement de statut du processus de vote est effectué
    /// @param previousStatus WorkflowStatus précédent
    /// @param newStatus Nouveau WorkflowStatus
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);

    /// @notice Emit lorsqu'une proposition est enregistrée
    /// @param proposalId L'ID de la proposition
    event ProposalRegistered(uint proposalId);

    /// @notice Emit lorsqu'un votant a séléctionné une proposition
    /// @param voter L'adresse du votant
    /// @param proposalId L'ID de la proposition choisie par le votant
    event Voted(address voter, uint proposalId);

    /// @dev Définit l'adresse qui déploie comme proporiétaire du contract
    constructor() Ownable(msg.sender) {}

    /// @dev S'assure que l'appelant d'une fonction est un votant
    modifier onlyVoters() {
        require(voters[msg.sender].isRegistered, "You're not a voter");
        _;
    }

    /// @notice Récupère les informations d'un votant
    /// @param _addr L'adresse du votant
    /// @return Voter Toutes les informations de la structure Voter en fonction de l'adresse
    function getVoter(address _addr) external view onlyVoters returns (Voter memory) {
        return voters[_addr];
    }

    /// @notice Récupère la description et le voteCount d'une proposition
    /// @param _id ID de la proposition
    /// @return Proposal Chaque ID de proposalsArray est associé à une structure Proposal
    function getOneProposal(uint _id) external view onlyVoters returns (Proposal memory) {
        return proposalsArray[_id];
    }

    /// @notice Enregistre un votant
    /// @dev Ne peut être exécuté que par le propriétaire du contrat
    /// @param _addr L'adresse du votant à enregistrer
    function addVoter(address _addr) external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, "Voters registration is not open yet");
        require(!voters[_addr].isRegistered, "Already registered");

        voters[_addr].isRegistered = true;
        emit VoterRegistered(_addr);
    }

    /// @notice Enregistre une proposition
    /// @param _desc String correspondant à la description de la proposition
    function addProposal(string calldata _desc) external onlyVoters {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, "Proposals are not allowed yet");
        require(bytes(_desc).length > 0, "Proposal description cannot be empty");

        proposalsArray.push(Proposal({description: _desc, voteCount: 0}));
        emit ProposalRegistered(proposalsArray.length - 1);
    }

    /// @notice Permet à un votant de voter pour une proposition
    /// @param _id L'ID de la proposition pour laquelle le votant souhaite voter
    function setVote(uint _id) external onlyVoters {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, "Voting session hasn't started yet");
        require(!voters[msg.sender].hasVoted, "You have already voted");
        require(_id < proposalsArray.length, "Proposal not found");

        voters[msg.sender].votedProposalId = _id;
        voters[msg.sender].hasVoted = true;
        proposalsArray[_id].voteCount++;
        emit Voted(msg.sender, _id);
    }

    // Les fonctions suivantes permettent au propriétaire du contrat de changer le statut du processus de vote

    function startProposalsRegistering() external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, "Registering proposals can't be started now");
        workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
    }

    function endProposalsRegistering() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, "Registering proposals haven't started yet");
        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
    }

    function startVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationEnded, "Proposal registration phase is not finished");
        workflowStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }

    function endVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, "Voting session hasn't started yet");
        workflowStatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
    }

    /// @notice Compte les votes et détermine la proposition gagnante
    /// @dev Ne peut être exécuté que par le propriétaire du contrat et seulement après la fin de la session de vote
    function tallyVotes() external onlyOwner {
        require(workflowStatus == WorkflowStatus.VotingSessionEnded, "Current status is not voting session ended");
        uint _winningProposalId;

        for (uint256 p = 0; p < proposalsArray.length; ++p) {
            if (proposalsArray[p].voteCount > proposalsArray[_winningProposalId].voteCount) {
                _winningProposalId = p;
            }
        }

        winningProposalID = _winningProposalId;
        workflowStatus = WorkflowStatus.VotesTallied;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied);
    }
}
