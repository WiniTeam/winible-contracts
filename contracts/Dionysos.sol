// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./Winible.sol";
import "./Bottle.sol";
import "./Cellar.sol";

contract Dionysos is Ownable {

    enum Status {
        Passed,
        Paid,
        Expired,
        Cancelled
    }

    struct Order {
        uint256 id;
        uint256 time;
        address[] bottles;
        uint256[] ids;
        Status status;
        address by;
    }

    uint256 public orderAmount;
    mapping (uint256 => Order) public orders;
    mapping (address => mapping (uint256 => bool)) public inOrder;

    
    Winible public winible;

    constructor () {
        winible = Winible(msg.sender);
    }

    function withdrawAll (address[] memory _tokens) public onlyOwner {
        for (uint i = 0; i < _tokens.length; i++) {
            IERC20 token = IERC20(_tokens[i]);
            token.transfer(msg.sender, token.balanceOf(address(this)));
        }
    }

    function createOrder (uint256 _card, address[] memory _bottles, uint256[] memory _ids) public returns (uint256) {
        uint256 id = orderAmount;
        address owner = winible.ownerOf(_card);

        orders[id] = Order(id, block.timestamp, _bottles, _ids, Status.Passed, owner);

        orderAmount++;

        return id;
    }

    function getMessageHash(uint256 _id, uint256 _amount, bytes memory _data) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_id, _amount, _data));
    }


    function completeOrder(uint256 _orderId, uint256 _amount, bytes memory _data, bytes memory _signature) public {
        Order memory order = orders[_orderId];
        // require(order.by == msg.sender, "Ordered by another wallet");
        // require(order.status == Status.Passed, "Order already processed");

        address recovered = ECDSA.recover(ECDSA.toEthSignedMessageHash(getMessageHash(_orderId, _amount, _data)), _signature);
        //TODO check expiry
        require(recovered == winible.API(), "Not the signer");



        // orders[_orderId].status = Status.Paid;
    }

    function cancel (uint256 _orderId, uint256 _toCard) public {
        Order memory order = orders[_orderId];
        require(msg.sender == winible.ownerOf(_toCard), "Not the owner of the vault");
        require(msg.sender == order.by, "Not the order initiator");
        require(order.status == Status.Passed, "Can't be cancelled");

        address[] memory bottles = order.bottles;
        uint256[] memory ids = order.ids;

        Cellar cellar = Cellar(winible.cellars(_toCard));

        for (uint i = 0; i < ids.length; i++) {
            Bottle bottle = Bottle(bottles[i]);
            uint256 id = ids[i];
            bottle.transferFrom(address(this), address(cellar), id);
            cellar.receiveBottle(address(cellar), id);
        }

        orders[_orderId].status = Status.Cancelled;
    }
    
}