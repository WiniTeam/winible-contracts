// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "../Bottle.sol";
import "../Cellar.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";


contract SampleBottle is Bottle {
    
    IERC20Metadata public usdc;

    constructor (address _winible, string memory _name, string memory _symbol, uint256 _supply, address _usdc) Bottle(_winible, _name, _symbol, _supply) {
        usdc = IERC20Metadata(_usdc);
        baseURI = "https://winible-club-api-alpha.vercel.app/bottles/metadata/";
    }

    function buy (uint256 _card) payable override public {
        uint256 tokenId = circulatingSupply;
        require(tokenId < maxSupply, "Supply reached");

        usdc.transferFrom(msg.sender, address(winible.dionysos()), getPrice(_card));

        address cellar = winible.cellars(_card);
        _mint(cellar, tokenId);
        Cellar(cellar).receiveBottle(address(this), tokenId);
        circulatingSupply++;
        expiry[tokenId] += 30 days;

        emit BuyBottle(tokenId, cellar);
    }

    function getPrice (uint256 _forCard) override public view returns (uint256) {
        uint256 level = winible.levels(_forCard);
        if(level == 1) return 19000000;
        else return 15000000;
    }

}