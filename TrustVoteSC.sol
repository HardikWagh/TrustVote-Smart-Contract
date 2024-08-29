// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TrustVote {
    address public deployer;

    enum UserRole { None, Voter, Candidate, Owner, Admin }

    struct Organization {
        address owner;
        string name;
        string registrationNumber;
        string location;
        string contactNumber;
        string electionType;
        string proofHash;
        bool isApproved;
    }

    struct Voter {
        string name;
        string email;
        string mobileNo;
        string designation;
        string proofHash;
        bool isVerified;
        bool hasVoted;
    }

    struct Candidate {
        string partyName;
        string partySlogan;
        string partyImage;
        string manifestoHash;
        bool isApproved;
    }

    struct Election {
        string electionName;
        uint startTime;
        uint endTime;
        bool isActive;
        bool isResultsPublished;
    }

    struct Vote {
        address voterAddress;
        uint candidateId;
        uint electionId;
    }

    struct Poll {
        string pollQuestion;
        string[] options;
        mapping(address => bool) hasResponded;
        uint[] votes;
    }

    Organization[] public organizations;
    Election[] public elections;
    Poll[] public polls;

    mapping(address => Voter) public voters;
    mapping(address => Candidate) public candidates;
    mapping(address => UserRole) public userRoles;

    // Testing for get details of voter and candidate 
    address[] public voterAddresses;
    address[] public candidateAddresses;

    mapping(uint => Vote[]) public electionVotes; // electionId to votes

    event OrganizationRegistered(uint orgId);
    event OrganizationApproved(uint orgId);
    event VoterRegistered(address voter);
    event VoterApproved(address voter);
    event CandidateRegistered(address candidate);
    event CandidateApproved(address candidate);
    event ElectionCreated(uint electionId);
    event VoteCasted(address voter, uint electionId, uint candidateId);
    event PollCreated(uint pollId);
    event PollResponseSubmitted(address voter, uint pollId, uint optionIndex);
    event ElectionResultsPublished(uint electionId);

    modifier onlyDeployer() {
        require(msg.sender == deployer, "Only deployer can call this function");
        _;
    }

    modifier onlyOwner() {
        require(userRoles[msg.sender] == UserRole.Owner, "Only owner can call this function");
        _;
    }

    modifier onlyAdmin() {
        require(userRoles[msg.sender] == UserRole.Admin || userRoles[msg.sender] == UserRole.Owner, "Only admin or owner can call this function");
        _;
    }

    modifier onlyVoter() {
        require(userRoles[msg.sender] == UserRole.Voter, "Only voters can call this function");
        _;
    }

    modifier onlyCandidate() {
        require(userRoles[msg.sender] == UserRole.Candidate, "Only candidates can call this function");
        _;
    }

    modifier onlyACOV() {
        require(userRoles[msg.sender] == UserRole.Owner || userRoles[msg.sender] == UserRole.Admin || userRoles[msg.sender] == UserRole.Candidate || userRoles[msg.sender] == UserRole.Voter, "Caller is not the owner, admin, candidate, or voter.");
        _;
    }

    constructor() {
        deployer = msg.sender;
    }

    // Organization Management
    function registerOrganization(
        string memory name,
        string memory registrationNumber,
        string memory location,
        string memory contactNumber,
        string memory electionType,
        string memory proofHash
    ) public {
        organizations.push(Organization({
            owner: msg.sender,
            name: name,
            registrationNumber: registrationNumber,
            location: location,
            contactNumber: contactNumber,
            electionType: electionType,
            proofHash: proofHash,
            isApproved: false
        }));
        emit OrganizationRegistered(organizations.length - 1);
    }

    function approveOrganization(uint orgId) public onlyDeployer {
        organizations[orgId].isApproved = true;
        userRoles[organizations[orgId].owner] = UserRole.Owner;
        emit OrganizationApproved(orgId);
    }

    function rejectOrganization(uint orgId) public onlyDeployer {
        delete organizations[orgId];
    }

    // Admin Management
    function appointAdmin(address _admin) public onlyOwner {
        userRoles[_admin] = UserRole.Admin;
    }

    function removeAdmin(address _admin) public onlyOwner {
        userRoles[_admin] = UserRole.None;
    }

    // Voter Management
    // Function to Register Voter
    function registerVoter(
        string memory _name,
        string memory _email,
        string memory _mobileNo,
        string memory _designation,
        string memory _proofHash
    ) public {
        // Register voter details
        voters[msg.sender] = Voter(_name, _email, _mobileNo, _designation, _proofHash, false, false);

        // Add voter address to array if not already added
        bool alreadyExists = false;
        for (uint256 i = 0; i < voterAddresses.length; i++) {
            if (voterAddresses[i] == msg.sender) {
                alreadyExists = true;
                break;
            }
        }

        if (!alreadyExists) {
            voterAddresses.push(msg.sender);
        }
    }

    function approveVoter(address voterAddress) public onlyAdmin {
        voters[voterAddress].isVerified = true;
        userRoles[voterAddress] = UserRole.Voter;
        emit VoterApproved(voterAddress);
    }

    function rejectVoter(address voterAddress) public onlyAdmin {
        delete voters[voterAddress];
    }

        // Function to Register Candidate
    function registerCandidate(
        string memory _partyName,
        string memory _partySlogan,
        string memory _partyImage,
        string memory _manifestoHash
    ) public onlyVoter{
        // Register candidate details
        candidates[msg.sender] = Candidate(_partyName, _partySlogan, _partyImage, _manifestoHash, false);

        // Add candidate address to array if not already added
        bool alreadyExists = false;
        for (uint256 i = 0; i < candidateAddresses.length; i++) {
            if (candidateAddresses[i] == msg.sender) {
                alreadyExists = true;
                break;
            }
        }

        if (!alreadyExists) {
            candidateAddresses.push(msg.sender);
        }
    }

    function approveCandidate(address candidateAddress) public onlyAdmin {
        candidates[candidateAddress].isApproved = true;
        userRoles[candidateAddress] = UserRole.Candidate;
        emit CandidateApproved(candidateAddress);
    }

    function rejectCandidate(address candidateAddress) public onlyAdmin {
        delete candidates[candidateAddress];
    }

    // Election Management
    function createElection(
        string memory electionName,
        uint startTime,
        uint endTime
    ) public onlyAdmin {
        elections.push(Election({
            electionName: electionName,
            startTime: startTime,
            endTime: endTime,
            isActive: false,
            isResultsPublished: false
        }));
        emit ElectionCreated(elections.length - 1);
    }

    function openVoting(uint electionId) public onlyAdmin {
        elections[electionId].isActive = true;
    }

    function closeVoting(uint electionId) public onlyAdmin {
        elections[electionId].isActive = false;
    }

    function publishResults(uint electionId) public onlyAdmin {
        elections[electionId].isResultsPublished = true;
        emit ElectionResultsPublished(electionId);
    }

    function getElectionResults(uint electionId) public view returns (Vote[] memory) {
        require(elections[electionId].isResultsPublished, "Results not published yet");
        return electionVotes[electionId];
    }

    function getCurrentVotingStatus(uint electionId) public view returns (bool) {
        return elections[electionId].isActive;
    }

    // Voting Management
    function castVote(uint electionId, uint candidateId) public onlyACOV {
        require(elections[electionId].isActive, "Voting is not active");
        require(!voters[msg.sender].hasVoted, "You have already voted");

        voters[msg.sender].hasVoted = true;
        electionVotes[electionId].push(Vote({
            voterAddress: msg.sender,
            candidateId: candidateId,
            electionId: electionId
        }));
        emit VoteCasted(msg.sender, electionId, candidateId);
    }

    function getAllVotersWhoVoted(uint electionId) public view returns (address[] memory) {
        uint voteCount = electionVotes[electionId].length;
        address[] memory votedAddresses = new address[](voteCount);

        for (uint i = 0; i < voteCount; i++) {
            votedAddresses[i] = electionVotes[electionId][i].voterAddress;
        }
        return votedAddresses;
    }


    // Poll Management
    function createPoll(string memory question, string[] memory options) public onlyAdmin {
        Poll storage poll = polls.push();
        poll.pollQuestion = question;
        poll.options = options;
        poll.votes = new uint[](options.length);
        emit PollCreated(polls.length - 1);
    }

    function submitPollResponse(uint pollId, uint optionIndex) public onlyACOV{
        require(!polls[pollId].hasResponded[msg.sender], "You have already responded to this poll");
        polls[pollId].hasResponded[msg.sender] = true;
        polls[pollId].votes[optionIndex]++;
        emit PollResponseSubmitted(msg.sender, pollId, optionIndex);
    }

    function getPollResults(uint pollId) public view returns (uint[] memory) {
        return polls[pollId].votes;
    }

    // New functions to fetch registered and approved organizations, voters, and candidates

    // Function to Get Registered Organizations
    function getRegisteredOrganizations() public view returns (Organization[] memory) {
        return organizations;
    }

    // Function to Get Approved Organizations
    function getApprovedOrganizations() public view returns (Organization[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < organizations.length; i++) {
            if (organizations[i].isApproved) {
                count++;
            }
        }
        
        Organization[] memory approvedOrganizations = new Organization[](count);
        uint256 j = 0;
        for (uint256 i = 0; i < organizations.length; i++) {
            if (organizations[i].isApproved) {
                approvedOrganizations[j] = organizations[i];
                j++;
            }
        }
        return approvedOrganizations;
    }
    
    // Function to Get Registered Voters
    function getRegisteredVoters() public view returns (Voter[] memory) {
        Voter[] memory allVoters = new Voter[](voterAddresses.length);

        for (uint256 i = 0; i < voterAddresses.length; i++) {
            allVoters[i] = voters[voterAddresses[i]];
        }

        return allVoters;
    }

    // Function to Get Registered Candidates
    function getRegisteredCandidates() public view returns (Candidate[] memory) {
        Candidate[] memory allCandidates = new Candidate[](candidateAddresses.length);

        for (uint256 i = 0; i < candidateAddresses.length; i++) {
            allCandidates[i] = candidates[candidateAddresses[i]];
        }

        return allCandidates;
    }

    // Function to Get Approved Voters
    function getApprovedVoters() public view returns (Voter[] memory) {
        uint256 count = 0;
        
        // Count approved voters
        for (uint256 i = 0; i < voterAddresses.length; i++) {
            if (voters[voterAddresses[i]].isVerified) {
                count++;
            }
        }

        Voter[] memory approvedVoters = new Voter[](count);
        uint256 j = 0;

        // Add approved voters to array
        for (uint256 i = 0; i < voterAddresses.length; i++) {
            if (voters[voterAddresses[i]].isVerified) {
                approvedVoters[j] = voters[voterAddresses[i]];
                j++;
            }
        }

        return approvedVoters;
    }    

    // Function to Get Approved Candidates
    function getApprovedCandidates() public view returns (Candidate[] memory) {
        uint256 count = 0;
        
        // Count approved candidates
        for (uint256 i = 0; i < candidateAddresses.length; i++) {
            if (candidates[candidateAddresses[i]].isApproved) {
                count++;
            }
        }

        Candidate[] memory approvedCandidates = new Candidate[](count);
        uint256 j = 0;

        // Add approved candidates to array
        for (uint256 i = 0; i < candidateAddresses.length; i++) {
            if (candidates[candidateAddresses[i]].isApproved) {
                approvedCandidates[j] = candidates[candidateAddresses[i]];
                j++;
            }
        }

        return approvedCandidates;
    }

    // Contract Management
    function resetContract() public onlyDeployer {
        // Reset logic: This will remove all data and reset the contract state.
        delete organizations;
        delete elections;
        delete polls;

        for (uint i = 0; i < organizations.length; i++) {
            delete organizations[i];
        }

        for (uint i = 0; i < elections.length; i++) {
            delete elections[i];
        }

        for (uint i = 0; i < polls.length; i++) {
            delete polls[i];
        }

        address[] memory votedAddresses = getAllVotersWhoVoted(elections.length - 1);
        for (uint i = 0; i < votedAddresses.length; i++) {
            delete voters[votedAddresses[i]];
            delete candidates[votedAddresses[i]];
            delete userRoles[votedAddresses[i]];
        }
    }

}
