// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IStake {
    function stake(address account, uint256 _amount) external;

    function withdraw(address account, uint256 _amount) external;

    function stakeOf(address _staker) external returns (uint256);

    function totalStakes() external returns (uint256);

    function totalStakers() external returns (uint256);
}
