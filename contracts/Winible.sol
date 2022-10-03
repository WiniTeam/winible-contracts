// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./Cellar.sol";
import "./Dionysos.sol";
import "./Bottle.sol";
import "./interfaces/IChainLink.sol";
import "./interfaces/IWETH.sol";

contract Winible is ERC721Enumerable, Ownable {


    //Cards 
    // cardId => cardLevel
    mapping (uint256 => uint256) public levels;
    // cardId => cardCellar
    mapping (uint256 => address) public cellars;
    // cardId => card data
    mapping (uint256 => bytes) public data;
    // cardId (perkId) => hasPerk
    mapping (uint256 => mapping (uint256 => bool)) public perks;

    //Levels
    // levelId => level price
    mapping (uint256 => uint256) public levelPrices;
    // levelId => level name
    mapping (uint256 => string) public levelNames;
    // levelId (perkId) => hasPerk
    mapping (uint256 => mapping (uint256 => bool)) public defaultPerks;

    //Perks
    // perkId => perk price
    mapping (uint256 => uint256) public perkPrices;
    // perkId => perk name
    mapping (uint256 => string) public perkNames;

    uint public constant MIN_LEVEL = 1;
    uint public constant MAX_LEVEL = 3;

    mapping (address => bool) public whitelistedBottles;

    Dionysos public dionysos;

    IChainLink public oracle;
    IERC20Metadata public usdc;
    IWETH public wETH;

    constructor(address _ethusd, address _usdc, address _weth) ERC721 ("Winible Club","Winible"){
        oracle = IChainLink(_ethusd);
        usdc = IERC20Metadata(_usdc);
        wETH = IWETH(_weth);

        uint256 decimals = usdc.decimals();

        //create base perks
        // Structs.Perk memory cellar3d = Structs.Perk(0, 50, "3D Cellar");
        // perks[0] = cellar3d;

        // //create base levels
        // Structs.Level memory flex = Structs.Level(1, 40, "Flex", new Structs.Perk[](0));
        // levels[1] = flex;


        // levels[2] = Structs.Level(2, 200, "Elite", new Structs.Perk[](0));
        // levels[3] = Structs.Level(3, 800, "Premium", new Structs.Perk[](0));


        // levelsPrices[MIN_LEVEL] = 40 * decimals; //40$
    }

    function build (bool _inETH) payable public returns (uint256) {
        uint256 price = levelPrices[MIN_LEVEL];
        if (_inETH) {
            price = getPriceInETH(price);
        }
        
        address to = msg.sender;
        _collectPayement(price, to, _inETH);

        uint256 cardId = totalSupply();

        Cellar cellar = new Cellar(cardId, 30);
        levels[cardId] = MIN_LEVEL;
        cellars[cardId] = address(cellar);

        _mint(to, cardId);

        return cardId;
    }

    function upgrade (uint256 _card, uint _level) payable public {
        require(ownerOf(_card) == msg.sender, "");
        // require(_level >= levels[_card] && _level <= MAX_LEVEL, "");

        //TODO check price and collect

        //TODO increase cellar cap,
        //TODO add perks
        
    }

    //_data = {cardId}-{timestamp};{chain}-{pfp}-{pfpid};{name} 
    function updateData (uint256 _card, bytes memory _data, bytes memory _signature) payable public {
        require(msg.sender == ownerOf(_card), "Not the card owner.");
        
        //TODO check free or not -> if not free collect payement
        //TODO check _data is signed by API -> _signature

        data[_card] = _data;
    }

    function increase (uint256 _card, uint256 _cap) payable public {
        Cellar cellar = Cellar(cellars[_card]);
        
        if (_cap == type(uint256).max) {
            _cap = type(uint256).max - cellar.capacity();
        }

        //TODO check price and collect

        cellar.increaseCapacity(_cap);
    }

    function buyPerk (uint256 _card, uint256 _perk, bool _inETH) payable public {
        require(!perks[_card][_perk] && !defaultPerks[levels[_card]][_perk], "Already have this perk");

        uint256 price = perkPrices[_perk];
        if (_inETH) {
            price = getPriceInETH(price);
        }
        
        _collectPayement(price, msg.sender, _inETH);

        perks[_card][_perk] = true;
    }

    function increaseExpiry(address[] memory _bottles, uint256[] memory _ids, uint256 _duration) public payable {
        require(_bottles.length == _ids.length, "Wrong input");

        //TODO collect payment

        for (uint256 i = 0; i < _bottles.length; i++) {
            Bottle(_bottles[i]).increaseExpiry(_ids[i], _duration);
        }

    }

    function getPriceInETH (uint256 _usdcPrice) public view returns (uint256) {

        uint256 ethDecimals = 18;
        uint256 usdcDecimals = usdc.decimals();
        uint256 oracleDecimals = oracle.decimals();

        (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = oracle.latestRoundData();

        uint256 oraclePrice = uint256(answer);
        
        return (
            (_usdcPrice * (10 ** (ethDecimals * 2 - usdcDecimals)))
            / ( oraclePrice * (10 ** (ethDecimals - oracleDecimals)))
        );
    }

    function hasPerk (uint256 _card, uint256 _perk) public view returns (bool) {
        return (defaultPerks[levels[_card]][_perk] || perks[_card][_perk]);
    }

    function createPerk (uint256 _id, uint256 _price, string memory _name, uint256[] memory _defaults ) public onlyOwner {
        perkNames[_id] = _name;
        perkPrices[_id] = _price;
        for (uint i = 0; i < _defaults.length; i++) {
            defaultPerks[_defaults[i]][_id] = true;
        }
    }


    //restricted
    function setWhitelist (address _bottle, bool _isWhitelisted) public onlyOwner {
        whitelistedBottles[_bottle] = _isWhitelisted;
    }

    //internal 
    function _collectPayement (uint256 _amount, address _payer, bool _inETH) internal {
        if(_inETH) {
            require(msg.value == _amount, "Not enough");
            _wrapAndTransfer(_amount);
        }
        else {
            usdc.transferFrom(_payer, address(dionysos), _amount);
        }
    }

    function _wrapAndTransfer (uint256 _amount) internal {
        wETH.deposit{value: _amount}();
        require(wETH.transfer(address(dionysos), _amount));
    }

}
