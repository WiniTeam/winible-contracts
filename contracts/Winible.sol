// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
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
    // levelId => cellar capacity to add
    mapping (uint256 => uint256) public capacityUpdate;

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

    address public signer;

    constructor(address _ethusd, address _usdc, address _weth, address _signer) ERC721 ("Winible Club","Winible"){
        oracle = IChainLink(_ethusd);
        usdc = IERC20Metadata(_usdc);
        wETH = IWETH(_weth);

        dionysos = new Dionysos();

        signer = _signer;

        uint256 decimals = usdc.decimals();

        //create levels
        levelPrices[1] = 20 * (10 ** decimals);
        levelNames[1] = "Flex";
        capacityUpdate[1] = 6;

        levelPrices[2] = 200 * (10 ** decimals);
        levelNames[2] = "Premium";
        capacityUpdate[2] = 60;

        levelPrices[3] = 1000 * (10 ** decimals);
        levelNames[3] = "Elite";
        capacityUpdate[3] = type(uint256).max;

    }

    function build (uint256 _level, bool _inETH) payable public returns (uint256) {
        uint256 price = levelPrices[_level];
        if (_inETH) {
            price = getPriceInETH(price);
        }
        
        address to = msg.sender;
        _collectPayment(price, to, _inETH);

        uint256 cardId = totalSupply();

        Cellar cellar = new Cellar(cardId, capacityUpdate[_level]);
        levels[cardId] = _level;
        cellars[cardId] = address(cellar);

        _mint(to, cardId);

        return cardId;
    }

    //_data = {cardId}-{timestamp};{chain}-{pfp}-{pfpid};{name} 
    function updateData (uint256 _card, bytes memory _data, bytes memory _signature) payable public {
        require(msg.sender == ownerOf(_card), "Not the _card owner.");
        
        //TODO check free or not -> if not free collect payement
        address recovered = ECDSA.recover(ECDSA.toEthSignedMessageHash(_data), _signature);
        require(recovered == signer, "Not signed by signer");

        data[_card] = _data;
    }

    function increase (uint256 _card, uint256 _cap) payable public {
        //TODO check price and collect

        _addCap(cellars[_card], _cap);

    }

    function buyPerk (uint256 _card, uint256 _perk, bool _inETH) payable public {
        require(!perks[_card][_perk] && !defaultPerks[levels[_card]][_perk], "_card already has this _perk");

        uint256 price = perkPrices[_perk];
        if (_inETH) {
            price = getPriceInETH(price);
        }
        _collectPayment(price, msg.sender, _inETH);

        perks[_card][_perk] = true;
    }

    function increaseExpiry (address[] memory _bottles, uint256[] memory _ids, uint256 _duration, bool _inETH) public payable {
        require(_bottles.length == _ids.length, "Wrong input (_bottles or _ids)");
        
        uint256 price;
        uint256 decimals = usdc.decimals();
        if (_duration == 30 days) {
            price = 1 * (10 ** decimals);
        }
        else if (_duration == 182 days) {
            price = 15 * (10 ** (decimals - 1));
        }
        else if (_duration == 365 days) {
            price = 2 * (10 ** decimals);
        }
        else {
            price = 0;
        }

        price *= _ids.length;

        require(price > 0, "Wrong input (_duration)");

        if (_inETH) {
            price = getPriceInETH(price);
        }
        _collectPayment(price, msg.sender, _inETH);

        for (uint256 i = 0; i < _bottles.length; i++) {
            Bottle(_bottles[i]).increaseExpiry(_ids[i], _duration);
        }

    }

    function getPriceInETH (uint256 _usdcPrice) public view returns (uint256) {

        uint256 ethDecimals = 18;
        uint256 usdcDecimals = usdc.decimals();
        uint256 oracleDecimals = oracle.decimals();

        (, int256 answer, , ,) = oracle.latestRoundData();

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

    // function setDionysos (address _dionysos) public onlyOwner()

    //internal 
    function _collectPayment (uint256 _amount, address _payer, bool _inETH) internal {
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

    function _addCap (address _cellar, uint256 _add) internal {
        Cellar cellar = Cellar(_cellar);
        uint256 capacity = cellar.capacity();

        if (_add == type(uint256).max) {
            cellar.changeCapacity(_add);
        }
        else {
            cellar.changeCapacity(capacity + _add);
        } 
    }

}
