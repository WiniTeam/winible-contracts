// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./Winible.sol";
import "./Bottle.sol";

contract Cellar {

    uint256 public card;
    Winible public winible;
    uint256 public capacity;
    uint256 public aum;
    mapping (address => mapping (uint256 => bool)) public owned;

    modifier onlyOwner {
        require(winible.ownerOf(card) == msg.sender, "You don't have the key to manage this cellar");
        _;
    }

    modifier onlyController {
        require(address(winible) == msg.sender, "Only winible can call this function");
        _;
    }

    constructor (uint256 _card, uint256 _cap) {
        winible = Winible(msg.sender);
        card = _card;
        capacity = _cap;
    }

    function redeem (address[] memory _bottles, uint256[] memory _ids) public onlyOwner {
        require(_bottles.length == _ids.length, "Wrong input");
        for (uint256 i = 0; i < _bottles.length; i++) {
            //TODO check if burnable
            Bottle bottle = Bottle(_bottles[i]);
            bottle.burn(_ids[i]);
            aum -= 1;
        }
    }

    function transfer (uint256 _to, address[] memory _bottles, uint256[] memory _ids) public onlyOwner {
        require(_to != card, "Can't transfer to himself");
        require(_bottles.length == _ids.length, "Wrong input");
        
        address toCellar = winible.cellars(_to);

        require(toCellar != address(0), "Wrong cellar card");

        for (uint256 i = 0; i < _bottles.length; i++) {
            _transferBottle(toCellar, _bottles[i], _ids[i]);
            Cellar(toCellar).receiveBottle(_bottles[i], _ids[i]);
        }
    }

    function seize (address[] memory _bottles, uint256[] memory _ids) public {
        require(_bottles.length == _ids.length, "Wrong input");
       
        for (uint256 i = 0; i < _bottles.length; i++) {
            _transferBottle(winible.dionysos.address, _bottles[i], _ids[i]);
        }
    }

    //internal 

    function _transferBottle (address _to, address _bottle, uint256 _id) internal {
        Bottle bottle = Bottle(_bottle);

        require(bottle.expiry(_id) < block.timestamp, "Expired, can't transfer");

        bottle.transferFrom(address(this), _to, _id);
        owned[address(bottle)][_id] = false;
        aum -= 1;
    }

    //external

    function receiveBottle (address _bottle, uint256 _id) external {
        require(winible.whitelistedBottles(_bottle), "This is not a bottle");
        require(aum < capacity, "Capacity is full");
        require(owned[_bottle][_id] == false, "Already owner");
        require(Bottle(_bottle).ownerOf(_id) == address(this), "Not the new owner");

        owned[_bottle][_id] == true;
        aum += 1;
    }

    function changeCapacity (uint256 _cap) external onlyController {
        require(_cap > capacity, "Wrong input: _cap");
        capacity = _cap;
    }

}