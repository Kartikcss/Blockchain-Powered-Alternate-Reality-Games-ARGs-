// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AlternateRealityGame {
    struct Player {
        uint level; // Player's level
        uint totalPoints; // Total points earned
        bool isRegistered; // Registration status
    }

    struct Challenge {
        uint id; // Challenge ID
        string description; // Description of the challenge
        uint points; // Points awarded for completion
        bool isActive; // Whether the challenge is active
    }

    address public admin; // Address of the game admin
    uint public totalChallenges; // Number of challenges
    uint public rewardPool; // Total reward pool balance

    mapping(address => Player) public players; // Player details
    mapping(uint => Challenge) public challenges; // Challenge details
    mapping(address => mapping(uint => bool)) public completedChallenges; // Tracks challenges completed by players

    event PlayerRegistered(address player);
    event ChallengeCreated(uint challengeId, string description, uint points);
    event ChallengeCompleted(address player, uint challengeId, uint points);
    event RewardPoolFunded(address contributor, uint amount);
    event RewardsClaimed(address player, uint reward);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    constructor() {
        admin = msg.sender; // Set contract deployer as admin
    }

    /// @notice Register a new player
    function registerPlayer() public {
        require(!players[msg.sender].isRegistered, "Player already registered");
        players[msg.sender] = Player(1, 0, true);
        emit PlayerRegistered(msg.sender);
    }

    /// @notice Admin creates a new challenge
    function createChallenge(string memory _description, uint _points) public onlyAdmin {
        require(_points > 0, "Points must be greater than 0");
        totalChallenges++;
        challenges[totalChallenges] = Challenge(totalChallenges, _description, _points, true);
        emit ChallengeCreated(totalChallenges, _description, _points);
    }

    /// @notice Complete a challenge
    function completeChallenge(uint _challengeId) public {
        require(players[msg.sender].isRegistered, "Player not registered");
        require(_challengeId > 0 && _challengeId <= totalChallenges, "Invalid challenge ID");
        require(challenges[_challengeId].isActive, "Challenge is inactive");
        require(!completedChallenges[msg.sender][_challengeId], "Challenge already completed");

        Player storage player = players[msg.sender];
        Challenge storage challenge = challenges[_challengeId];

        player.totalPoints += challenge.points;
        completedChallenges[msg.sender][_challengeId] = true;

        // Level up player if total points exceed the threshold (e.g., 100 points per level)
        if (player.totalPoints >= player.level * 100) {
            player.level++;
        }

        emit ChallengeCompleted(msg.sender, _challengeId, challenge.points);
    }

    /// @notice Contribute to the reward pool
    function fundRewardPool() public payable {
        require(msg.value > 0, "Contribution must be greater than 0");
        rewardPool += msg.value;
        emit RewardPoolFunded(msg.sender, msg.value);
    }

    /// @notice Claim rewards for a player based on points
    function claimRewards(address _player) public onlyAdmin {
        require(players[_player].isRegistered, "Player not registered");
        require(rewardPool > 0, "Insufficient reward pool");

        Player storage player = players[_player];
        uint reward = (rewardPool * player.totalPoints) / totalPoints();

        require(reward > 0, "No rewards for this player");
        rewardPool -= reward;

        payable(_player).transfer(reward);
        emit RewardsClaimed(_player, reward);
    }

    /// @notice Calculate total points across all players
    function totalPoints() public view returns (uint total) {
        address currentPlayer = msg.sender; // Temporary workaround to calculate total points
        if (players[currentPlayer].isRegistered) {
            total += players[currentPlayer].totalPoints;
        }
    }
}
