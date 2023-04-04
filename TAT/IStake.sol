// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IStake {
    function stake(uint256 _amount) external;
    function withdraw(uint256 _amount) external;
    function stakeOf(address _staker) external returns (uint256);
    function totalStakes() external returns (uint256);
    function totalStakers() external returns (uint256);
}