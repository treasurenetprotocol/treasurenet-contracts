// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract SampleDAO is Initializable {
    address private _dao;

    uint256 private _blockReward;

    event BlockRewardReset(uint256 oldB,uint256 newB);

    function initialize(address dao_) initializer public {
        require(dao_!=address(0),"empty address");
        _dao = dao_;
    }

    modifier onlyDAO() {
        require(msg.sender == _dao,"only dao");
        _;
    }

    function blockReward() public view returns (uint256) {
        return _blockReward;
    }

    function setBlockReward(uint256 _newReward) public onlyDAO {
        uint256 old = _blockReward;
        _blockReward = _newReward;
        emit BlockRewardReset(old, _newReward);
    }

    event PayEth(uint256);
    function receiveEth() public payable {
        emit PayEth(msg.value);
    }
}