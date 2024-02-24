// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../src/Voting.sol";
import "forge-std/console.sol";

contract VotingTest is Test {

    event VoterRegistered(address voterAddress);
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);

    address owner = makeAddr('User0');
    address addr1 = makeAddr('User1');
    address addr2 = makeAddr('User2');

    Voting public _Voting;
    mapping (address => Voter) public voters;
    Proposal[] public proposalsArray;


    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    struct Proposal {
        string description;
        uint voteCount;
    }

    enum  WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    function setUp() public {
        vm.prank(owner);
        _Voting = new Voting();
    }

    function test_VoterHasBeenGotten() public {
        vm.startPrank(owner);
        _Voting.addVoter(addr1);
        emit VoterRegistered(addr1);
        vm.stopPrank();
        vm.startPrank(addr1);
        assertTrue(_Voting.getVoter(addr1).isRegistered);
    }

    function test_ProposalHasBeenGotten() public {
        vm.startPrank(owner);
        _Voting.addVoter(addr1);
        _Voting.startProposalsRegistering();
        vm.stopPrank();
        vm.startPrank(addr1);
        _Voting.addProposal("Proposal 1");
        emit ProposalRegistered(0);
        vm.stopPrank();
        vm.startPrank(addr1);
        assertTrue(_Voting.getOneProposal(0).voteCount == 0);
    }

    function test_ExpectEmit_VoterRegistered() public {
        vm.prank(owner);
        vm.expectEmit(true, false, false, true);
        emit VoterRegistered(addr1);
        _Voting.addVoter(addr1);
    }

    function testFail_AddVoterAlreadyRegistered() public {
        vm.prank(owner);
        _Voting.addVoter(addr1);
        vm.expectRevert("Already registered");
        _Voting.addVoter(addr1);
    }

    function test_ProposalIsAdded() public {
        Proposal memory proposal1;
        proposal1.description = "Proposal 1";
        vm.startPrank(owner);
        _Voting.addVoter(addr1);
        _Voting.startProposalsRegistering();
        vm.stopPrank();
        vm.prank(addr1);
        _Voting.addProposal("Proposal 1");
        proposalsArray.push(proposal1);
        assertEq(proposal1.description, "Proposal 1");

    }

    function testFail_AddProposalWhenNotAllowed() public {
        vm.prank(owner);
        _Voting.addVoter(addr1);
        vm.startPrank(addr1);
        vm.expectRevert("Proposals are not allowed yet");
        _Voting.addProposal("Proposal X"); // Should fail because registration hasn't started
        vm.stopPrank();
        vm.prank(owner);
        _Voting.startProposalsRegistering();
        _Voting.endProposalsRegistering();
        vm.prank(addr1);
        vm.expectRevert("Proposals are not allowed yet");
        _Voting.addProposal("Proposal Y"); // Should fail because registration has ended
    }

    function test_ExpectEmit_Voted() public {
        vm.startPrank(owner);
        _Voting.addVoter(addr1);
        _Voting.startProposalsRegistering();
        vm.stopPrank();
        vm.startPrank(addr1);
        _Voting.addProposal("Proposal 1");
        vm.stopPrank();
        vm.startPrank(owner);
        _Voting.endProposalsRegistering();
        _Voting.startVotingSession();
        vm.stopPrank();
        vm.startPrank(addr1);
        vm.expectEmit(true, false, false, true);
        emit Voted(addr1, 0);
        _Voting.setVote(0);
    }

    function test_RevertWhen_VoteInvalidProposalId() public {
        vm.startPrank(owner);
        _Voting.addVoter(addr1);
        _Voting.startProposalsRegistering();
        vm.stopPrank();
        vm.prank(addr1);
        _Voting.addProposal("Proposal 1");
        vm.startPrank(owner);
        _Voting.endProposalsRegistering();
        _Voting.startVotingSession();
        vm.stopPrank();
        vm.prank(addr1);
        vm.expectRevert("Proposal not found");
        _Voting.setVote(4000); // Should fail because this proposal ID does not exist
    }

    function test_RevertWhen_VoteWhenNotAllowed() public {
        vm.startPrank(owner);
        _Voting.addVoter(addr1);
        _Voting.startProposalsRegistering();
        vm.stopPrank();
        vm.prank(addr1);
        _Voting.addProposal("Proposal 1");
        vm.prank(owner);
        _Voting.endProposalsRegistering();
        // Try voting before voting session has started
        vm.prank(addr1);
        vm.expectRevert("Voting session havent started yet");
        _Voting.setVote(0);
        // Start voting session, vote once, then try voting again
        vm.prank(owner);
        _Voting.startVotingSession();
        vm.startPrank(addr1);
        _Voting.setVote(0); // First vote should succeed
        vm.expectRevert("You have already voted");
        _Voting.setVote(0); // Second attempt should fail
    }

    function test_ExpectEmit_WorkflowStatusChange() public {
        vm.prank(owner);
        vm.expectEmit(true, false, false, true);
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
        _Voting.startProposalsRegistering();
        vm.prank(owner);
        vm.expectEmit(true, false, false, true);
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
        _Voting.endProposalsRegistering();
        vm.prank(owner);
        vm.expectEmit(true, false, false, true);
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
        _Voting.startVotingSession();
        vm.prank(owner);
        vm.expectEmit(true, false, false, true);
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
        _Voting.endVotingSession();
        vm.prank(owner);
        vm.expectEmit(true, false, false, true);
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied);
        _Voting.tallyVotes();
    }

    function test_VotesAreTallied() public {
        vm.startPrank(owner);
        _Voting.addVoter(addr1);
        _Voting.startProposalsRegistering();
        vm.stopPrank();
        vm.startPrank(addr1);
        _Voting.addProposal("Proposal 1");
        vm.stopPrank();
        vm.startPrank(owner);
        _Voting.endProposalsRegistering();
        _Voting.startVotingSession();
        vm.stopPrank();
        vm.startPrank(addr1);
        _Voting.setVote(0);
        vm.stopPrank();
        vm.startPrank(owner);
        _Voting.endVotingSession();
        vm.stopPrank();
        vm.startPrank(owner);
        _Voting.tallyVotes();
        vm.stopPrank();
        assertEq(_Voting.winningProposalID(), 0);
    }

}
