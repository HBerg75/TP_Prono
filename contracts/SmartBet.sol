// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SmartBet {
    struct User {
        address addr;
        string username;
        uint balance;
    }
    
    struct Bet {
        address user;
        uint matchId;
        uint predictedScoreTeamA;
        uint predictedScoreTeamB;
        bool isWinner;
    }
    
    struct Match {
        uint id;
        uint scoreTeamA;
        uint scoreTeamB;
        bool isFinished;
    }
    
    address public admin;
    uint public entryFee = 0.01 ether;
    Match[] public matches;
    Bet[] public bets;
    mapping(address => User) public users;
    mapping(uint => Bet[]) public matchBets; // Mapping from matchId to array of bets
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only the admin can call this function.");
        _;
    }
    
    constructor() {
        admin = msg.sender;
    }
    
    function registerUser(string memory _username) public {
        require(users[msg.sender].addr == address(0), "User already registered.");
        users[msg.sender] = User(msg.sender, _username, 0);
    }
    
    function addMatch(uint _matchId) public onlyAdmin {
        matches.push(Match(_matchId, 0, 0, false));
    }
    
    function placeBet(uint _matchId, uint _predictedScoreTeamA, uint _predictedScoreTeamB) public payable {
        require(msg.value == entryFee, "Incorrect entry fee.");
        require(matches[_matchId].id == _matchId, "Match does not exist.");
        Bet memory newBet = Bet(msg.sender, _matchId, _predictedScoreTeamA, _predictedScoreTeamB, false);
        bets.push(newBet);
        matchBets[_matchId].push(newBet);
    }
    
    function updateMatchResult(uint _matchId, uint _scoreTeamA, uint _scoreTeamB) public onlyAdmin {
        Match storage matchToUpdate = matches[_matchId];
        require(!matchToUpdate.isFinished, "Match is already finished.");
        matchToUpdate.scoreTeamA = _scoreTeamA;
        matchToUpdate.scoreTeamB = _scoreTeamB;
        matchToUpdate.isFinished = true;
    }
    
    function determineWinners(uint _matchId) public onlyAdmin {
        require(matches[_matchId].isFinished, "Match is not finished yet.");
        uint winnersCount = 0;
        for (uint i = 0; i < matchBets[_matchId].length; i++) {
            if (matchBets[_matchId][i].predictedScoreTeamA == matches[_matchId].scoreTeamA &&
                matchBets[_matchId][i].predictedScoreTeamB == matches[_matchId].scoreTeamB) {
                matchBets[_matchId][i].isWinner = true;
                winnersCount++;
            }
        }
        if (winnersCount > 5) {
            distributeWinningsRandomly(_matchId, winnersCount);
        } else {
            distributeWinningsToAll(_matchId);
        }
    }
    
    function distributeWinningsRandomly(uint _matchId, uint winnersCount) private {
        for (uint i = 0; i < 5; i++) {
            uint randomIndex = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, i))) % winnersCount;
            address winnerAddress = matchBets[_matchId][randomIndex].user;
            users[winnerAddress].balance += (address(this).balance / 5);
        }
    }
    
    function distributeWinningsToAll(uint _matchId) private {
        uint winningAmount = address(this).balance / matchBets[_matchId].length;
        for (uint i = 0; i < matchBets[_matchId].length; i++) {
            if (matchBets[_matchId][i].isWinner) {
                address winnerAddress = matchBets[_matchId][i].user;
                users[winnerAddress].balance += winningAmount;
            }
        }
    }
    
    function withdrawWinnings() public {
        uint amount = users[msg.sender].balance;
        require(amount > 0, "No winnings to withdraw.");
        users[msg.sender].balance = 0;
        payable(msg.sender).transfer(amount);
        }
    }