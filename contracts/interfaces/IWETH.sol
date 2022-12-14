//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.9;
interface IWETH {
    
    function deposit() external payable;

    function withdraw(uint wad) external;

    function approve(address guy, uint wad) external returns (bool);

    function transfer(address dst, uint wad) external returns (bool);

    function transferFrom(address src, address dst, uint wad) external returns (bool);
}
