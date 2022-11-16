// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "../interfaces/IChainLink.sol";

contract ChainLink is IChainLink {

    function decimals() external view override returns (uint8) { return 8;}

    function description() external view override returns (string memory) { return "";}

    function version() external view override returns (uint256) {return 1;}

    function getRoundData(uint80 _roundId)
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) {
        return (0, 146745064475, 1667916227, 1667916227, 0);
    }

    function latestRoundData()
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) {
        return (0, 146745064475, 1667916227, 1667916227, 0);
    }
}