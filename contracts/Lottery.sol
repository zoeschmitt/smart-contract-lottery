// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Lottery is Ownable, VRFConsumerBase {
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }

    address payable[] public players;
    address payable public recentWinner;
    uint256 public randomness;
    uint256 public usdEntryFee;
    AggregatorV3Interface internal ethUsdPriceFeed;
    LOTTERY_STATE public lottery_state;
    uint256 public fee;
    bytes32 public keyhash;
    event RequestedRandomness(bytes32 requestId);

    constructor(
        address _priceFeedAddress,
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyhash
    ) public VRFConsumerBase(_vrfCoordinator, _link) {
        usdEntryFee = 50 * (10**18);
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        lottery_state = LOTTERY_STATE.CLOSED;
        fee = _fee;
        keyhash = _keyhash;
    }

    function enter() public payable {
        // $50 min
        require(lottery_state == LOTTERY_STATE.OPEN);
        require(msg.value >= getEntranceFee(), "Not enough ETH.");
        players.push(msg.sender);
    }

    function getEntranceFee() public view returns (uint256) {
        // In production you would want to use safe math.
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        // price feed has 8 decimal places
        uint256 adjustedPrice = uint256(price) * 10**10; // 18 decimals
        uint256 costToEnter = (usdEntryFee * 10**18) / adjustedPrice;
        return costToEnter;
    }

    function startLottery() public onlyOwner {
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "Cannot start a new lottery yet."
        );
        lottery_state = LOTTERY_STATE.OPEN;
    }

    function endLottery() public onlyOwner {
        // NOT A GOOD METHOD FOR RANDOMNESS
        // uint256(
        //     keccack256(
        //         abi.encodePacked(
        //             nonce, // predictable (transaction num)
        //             msg.sender, // predictable
        //             block.difficulty, // can be manipulated by the miners
        //             bloc.timestamp // predictable
        //         )
        //     ) % players.length
        // );
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        bytes32 requestId = requestRandomness(keyhash, fee);
        emit RequestedRandomness(requestId);
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        require(
            lottery_state == LOTTERY_STATE.CALCULATING_WINNER,
            "You aren't there yet."
        );
        require(_randomness > 0, "random-not-found");
        uint256 indexOfWinner = _randomness % players.length;
        recentWinner = players[indexOfWinner];
        // 7 players
        // 22
        // 22 % 7 = 1
        // 7 
        recentWinner.transfer(address(this).balance);
        // RESET
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
        randomness = _randomness;
    }
}
