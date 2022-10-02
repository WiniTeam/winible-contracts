// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Dionysos is Ownable {

    function withdrawAll (address[] memory _tokens) public onlyOwner {
        for (uint i = 0; i < _tokens.length; i++) {
            IERC20 token = IERC20(_tokens[i]);
            token.transferFrom(address(this), msg.sender, token.balanceOf(address(this)));
        }
    }
    
}