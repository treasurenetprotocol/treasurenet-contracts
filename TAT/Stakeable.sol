// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IStake.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

abstract contract Stakeable is IStake {
    using SafeMath for uint256;

    address[] internal _stakeHolders;

    mapping(address => uint256) internal _stakes;

    function _isStakeholder(address _address) internal view returns (bool, uint256) {
        for (uint256 s = 0; s < _stakeHolders.length; s += 1) {
            if (_address == _stakeHolders[s]) return (true, s);
        }
        return (false, 0);
    }

    function _addStakeholder(address _stakeholder) internal {
        (bool _is, ) = _isStakeholder(_stakeholder);
        if (!_is) _stakeHolders.push(_stakeholder);
    }

    function _removeStakeholder(address _stakeholder) internal {
        (bool _is, uint256 s) = _isStakeholder(_stakeholder);
        if (_is) {
            _stakeHolders[s] = _stakeHolders[_stakeHolders.length - 1];
            _stakeHolders.pop();
        }
    }

    function stakeOf(address _stakeholder) public view override returns (uint256) {
        return _stakes[_stakeholder];
    }

    function totalStakes() public view override returns (uint256) {
        uint256 _totalStakes = 0;
        for (uint256 s = 0; s < _stakeHolders.length; s += 1) {
            _totalStakes = _totalStakes.add(_stakes[_stakeHolders[s]]);
        }
        return _totalStakes;
    }

    function totalStakers() public view override returns (uint256) {
        return _stakeHolders.length;
    }

    // Logics to bid and withdraw
    event Stake(address from,uint256 amount);
    function _stake(uint256 amount) internal {
        if (_stakes[msg.sender] == 0) _addStakeholder(msg.sender);
        _stakes[msg.sender] = _stakes[msg.sender].add(amount);
        emit Stake(msg.sender, amount);
    }

    event Withdraw(address from,uint256 amount);
    function _withdraw(uint256 amount) internal {
        require(_stakes[msg.sender] > amount, "withdrawed tokens bigger than staked");
        _stakes[msg.sender] = _stakes[msg.sender].sub(amount);
        if (_stakes[msg.sender] == 0) _removeStakeholder(msg.sender);
        emit Withdraw(msg.sender, amount);
    }

    function stake(uint256 _amount) public override virtual;
    function withdraw(uint256 _amount) public override virtual;
}
