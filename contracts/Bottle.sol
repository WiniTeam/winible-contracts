// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "./Winible.sol";

abstract contract Bottle is ERC721Burnable {

    uint256 public maxSupply;
    uint256 public defaultExpiry;
    mapping(uint256 => uint256) public expiry;
    Winible public winible;


    constructor(address _winible, string memory _name, string memory _symbol) ERC721(_name, _symbol){
        winible = Winible(_winible);
    }

    modifier onlyController {
        require(address(winible) == msg.sender, "Only winible can call this function");
        _;
    }

    function buy (uint256 _card) payable virtual public;
    

    function increaseExpiry (uint256 _bottle, uint256 _duration) external onlyController {
        require(_exists(_bottle));
        expiry[_bottle] += _duration;
    }

}