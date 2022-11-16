// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Winible.sol";

abstract contract Bottle is ERC721Burnable {

    using Strings for uint256;

    uint256 public maxSupply;
    uint256 public circulatingSupply;
    uint256 public defaultExpiry;
    mapping(uint256 => uint256) public expiry;
    Winible public winible;
    string public baseURI;

    event BuyBottle (uint256 indexed _id, address _toCellar);

    constructor(address _winible, string memory _name, string memory _symbol, uint256 _supply) ERC721(_name, _symbol) {
        winible = Winible(_winible);
        maxSupply = _supply;
    }

    modifier onlyController {
        require(address(winible) == msg.sender, "Only winible can call this function");
        _;
    }

    function buy (uint256 _card) payable virtual public;
    
    function getPrice (uint256 _forCard) public virtual view returns (uint256);

    function increaseExpiry (uint256 _bottle, uint256 _duration) external onlyController {
        require(_exists(_bottle));
        expiry[_bottle] += _duration;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

}