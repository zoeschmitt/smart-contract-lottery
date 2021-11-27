// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Lottery is Ownable {
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }

    address payable[] public players;
    uint256 public usdEntryFee;
    AggregatorV3Interface internal ethUsdPriceFeed;
    LOTTERY_STATE public lottery_state;

    constructor(address _priceFeedAddress) public {
        usdEntryFee = 50 * (10**18);
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        lottery_state = LOTTERY_STATE.CLOSED;
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
        
    }
}
