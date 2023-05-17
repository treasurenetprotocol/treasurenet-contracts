// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../TAT/ITAT.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Bid is Initializable, OwnableUpgradeable {

    event BidRecord(address account, uint256 amount);
    event BidStart(uint256 height);

    struct BiderList {
        address bider;
        uint256 amount;
        uint256 time;
    }

    address[] public TATBiders;
    mapping(address => bool) isTATBid;
    mapping(address => uint256) bidAmount;
    mapping(address => uint256) bidTime;

    /* 最少1TAT */
    uint256 constant TAT_THRESHOLD = 1 * 1e18;
    uint256 _totalBid;

    address private governance;
    ITAT private _tat;

    // bonus stake 开始时间
    uint256 private _startAt;
    uint256 private constant ROUND_TIME = 5 minutes;

    function initialize(address _tatAddress) public initializer {
        __Ownable_init();
        _tat = ITAT(_tatAddress);
        _startAt = block.timestamp;
        _totalBid = 0;
        emit BidStart(block.number);
    }

    receive() external payable {}

    /* 是否已经进行过bonus stake */
    function isTATBider(address account) public view returns (bool){
        /* 超出周期等待触发的情况 */
        if (block.timestamp > _startAt + ROUND_TIME) {
            return false;
        }
        return isTATBid[account];
    }

    /* 查看自己投了多少TAT */
    function mybidAmount() public view returns (uint256){
        /* 用户不存在的情况 */
        if (bidAmount[msg.sender] == 0) {
            return 0;
        }
        /* 超出周期等待触发的情况 */
        if (block.timestamp > _startAt + ROUND_TIME) {
            return 0;
        }
        return bidAmount[msg.sender];
    }

    /* 查看本轮起始时间 */
    function roundTime() public view returns (uint256){
        require(_startAt > 0, "bonus stake has not started yet");
        uint256 time = _startAt;
        if (block.timestamp > _startAt + ROUND_TIME) {
            time = _startAt + (block.timestamp - _startAt) / ROUND_TIME * ROUND_TIME;
        }
        return time;
    }

    /* Bonus Stake main process */
    function bidTAT(uint256 amount) public returns (bool){
        require(amount >= TAT_THRESHOLD, "TAT not enough to bid");
        if (block.timestamp > _startAt + ROUND_TIME) {
            _startAt = _startAt + (block.timestamp - _startAt) / ROUND_TIME * ROUND_TIME;
            _totalBid = 0;
            for (uint256 i = 0; i < TATBiders.length; i++) {
                delete isTATBid[TATBiders[i]];
                delete bidAmount[TATBiders[i]];
                delete bidTime[TATBiders[i]];
            }
            delete TATBiders;
            //emit BidStart(_startAt);
        }

        _tat.stake(msg.sender, amount);

        if (!isTATBider(msg.sender)) {
            isTATBid[msg.sender] = true;
            TATBiders.push(msg.sender);
        }
        bidAmount[msg.sender] += amount;
        bidTime[msg.sender] = block.timestamp;

        _totalBid += amount;

        emit BidRecord(msg.sender, amount);

        return true;

    }

    /* 查询列表 */
    function bidderList() public view returns (BiderList[] memory, uint256, uint256){
        uint256 time = _startAt;
        /* 超出周期等待触发的情况 */
        if (block.timestamp > _startAt + ROUND_TIME) {
            BiderList[] memory _empty = new BiderList[](0);
            time = _startAt + (block.timestamp - _startAt) / ROUND_TIME * ROUND_TIME;
            return (_empty, 0, time);
        }
        BiderList[] memory list = new BiderList[](TATBiders.length);
        for (uint256 i = 0; i < TATBiders.length; i++) {
            list[i].bider = TATBiders[i];
            list[i].amount = bidAmount[TATBiders[i]];
            list[i].time = bidTime[TATBiders[i]];
        }
        return (list, _totalBid, time);
    }

}
