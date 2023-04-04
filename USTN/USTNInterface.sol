// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface USTNInterface{
    function bidCost(address bider, uint amount)external returns(bool);

    function bidBack(address bider, uint amount)external returns(bool);

    function burn(address account, uint256 tokens)external returns (bool);

    function reduceTotalSupply(uint amount)external returns(bool);

    function addTotalSupply(uint amount)external returns(bool);

    function addBalance(address add, uint amount)external returns(bool);

    function reduceBalance(address add, uint amount)external returns(bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address tokenOwner) external view returns (uint256 balance);  
    
    function transfer(address to, uint256 tokens) external returns (bool success);  
}
