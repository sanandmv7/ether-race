// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

contract EtherRace {
    address public owner; // Owner of the contract
    uint public raceDistance; // Total distance of the race
    uint public startTime; // Start time of the race
    mapping(address => uint) public balances; // Balances of each player
    mapping(address => uint) public positions; // Positions of each player

    event RaceStarted(uint startTime);
    event RaceEnded(address winner, uint time);

    address public winner;
    uint prize;

    bool prizeClaimed;

    constructor(uint _raceDistance) {
        owner = msg.sender;
        raceDistance = _raceDistance;
    }

    function startRace() public {
        require(msg.sender == owner, "Only the owner can start the race.");
        startTime = block.timestamp;
        emit RaceStarted(startTime);
    }

    function getRandomNumber(uint distance) internal view returns (uint) {
        uint random = uint(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.prevrandao,
                    msg.sender,
                    block.number
                )
            )
        );
        return ((random % distance) / 2) + 1;
    }

    function moveVehicle() public {
        require(startTime > 0, "The race has not started yet.");
        require(winner == address(0), "Race ended.");

        uint distance = getRandomNumber(raceDistance);

        // Calculate gas cost
        uint gasCost = tx.gasprice * distance;

        // Check player balance
        require(
            balances[msg.sender] >= gasCost,
            "Insufficient balance to pay gas."
        );

        // Update player position
        positions[msg.sender] += distance;

        // Deduct gas cost from player balance
        balances[msg.sender] -= gasCost;
        prize += gasCost;

        // Check if player has completed the race
        if (positions[msg.sender] >= raceDistance) {
            winner = msg.sender;
            emit RaceEnded(msg.sender, block.timestamp - startTime);
        }
    }

    function buyPowerUp() public payable {
        require(msg.value > 0, "Value must be greater than zero.");

        // Store power-up in contract balance
        balances[msg.sender] += msg.value;
    }

    function withdrawBalance() public {
        uint balance = balances[msg.sender];
        require(balance > 0, "Balance must be greater than zero.");

        // Transfer balance to player
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(balance);
    }

    function claimPrize() public {
        require(msg.sender == winner, "Only winner can claim prize.");
        require(!prizeClaimed, "Prize already claimed");
        prizeClaimed = true;
        payable(winner).transfer(prize);
    }
}
