const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("SmartBet", function () {
    let SmartBet;
    let smartBet;
    let admin, user1, user2, users;

    beforeEach(async function () {
        [admin, user1, user2, ...users] = await ethers.getSigners();
        SmartBet = await ethers.getContractFactory("SmartBet");
        smartBet = await SmartBet.deploy();
        await smartBet.deployed();
    });

    describe("User registration", function () {
        it("should allow a user to register", async function () {
            await smartBet.connect(user1).registerUser("User1");
            const userInfo = await smartBet.users(user1.address);
            expect(userInfo.username).to.equal("User1");
        });
    });

    describe("Placing bets", function () {
        it("should allow a user to place a bet", async function () {
            await smartBet.connect(user1).registerUser("User1");
            await smartBet.connect(admin).addMatch(1); // Add a match with ID 1
            await smartBet.connect(user1).placeBet(1, 2, 1, { value: ethers.utils.parseEther("0.01") });
        });
    });

    describe("Determining winners", function () {
        it("should correctly determine winners", async function () {
            // Enregistrement des utilisateurs
            await smartBet.connect(user1).registerUser("User1");
            await smartBet.connect(user2).registerUser("User2");

            // Ajout d'un match par l'admin
            await smartBet.connect(admin).addMatch(1);

            // Les utilisateurs placent des paris, user1 va gagner, user2 va perdre
            await smartBet.connect(user1).placeBet(1, 2, 1, { value: ethers.utils.parseEther("0.01") });
            await smartBet.connect(user2).placeBet(1, 1, 2, { value: ethers.utils.parseEther("0.01") });

            // L'admin met à jour les résultats du match pour que user1 soit le gagnant
            await smartBet.connect(admin).updateMatchResult(1, 2, 1);

            // L'admin détermine les gagnants
            await smartBet.connect(admin).determineWinners(1);
        });
    });
});
