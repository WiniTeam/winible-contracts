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
        minPrice = 15000000;
        maxPrice = 19000000;
        fixedMetadata = "ipfs://abcdefghm";
    }

    function buy (uint256 _card, uint256 _amount) payable override public {
        require(_amount > 0, "wrong amount");
        usdc.transferFrom(msg.sender, address(winible.dionysos()), getPrice(_card) * _amount);
        address cellar = winible.cellars(_card);


        for (uint i = 0; i < _amount; i++) {
            uint256 tokenId = circulatingSupply;
            require(tokenId < maxSupply, "Supply reached");

            _mint(cellar, tokenId);
            Cellar(cellar).receiveBottle(address(this), tokenId);
            expiry[tokenId] = block.timestamp + 30 days;

            emit BuyBottle(tokenId, cellar);

            circulatingSupply++;
        }
        
    }

    function getPrice (uint256 _forCard) override public view returns (uint256) {
        uint256 level = winible.levels(_forCard);
        if(level == 1) return maxPrice;
        else return minPrice;
    }

}