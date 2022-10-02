// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

library Structs {
    
    struct Perk {
        uint256 id;
        uint256 price;
        string name;
    }

    struct Level {
        uint256 id;
        uint256 price;
        string name;
        Perk[] perks;
    }

    struct Card {
        uint256 id;
        Level level;
        Perk[] extraPerks;
        address cellar;
        bytes data;
    }  
}
