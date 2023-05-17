// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract AirDrop is Initializable, OwnableUpgradeable {
    // FoundationManager
    address[] private _fms;
    // BoardDirector
    address[] private _boardDirectors;

    // 两种用户类型: 基金会和VIP用户
    enum Role {
        Unknown,
        FOUNDATION,
        VIP
    }

    // 基金会提取阶段
    enum ClaimStage {
        StageUnknown,
        Stage1,
        Stage2
    }

    uint256 private constant STAGE_TIMELOCK = 90 days;
    /* for test 15mins */
    /*uint256 private constant STAGE_TIMELOCK = 15 minutes;*/
    uint256 private constant AirDrop_TIMELOCK = 30 days;
    /* for test 10mins */
    /*uint256 private constant AirDrop_TIMELOCK = 5 minutes;*/
    uint256 private constant RELEASE_PERIODS = 12;

    // 不同阶段授予基金会的UNIT
    mapping(ClaimStage => uint256) private _toFoundation;
    // 基金会可提取(payable)账户
    address private _foundation;

    // 初始授予VIP的总量
    uint256 private _remainedToVips;
    // 每个月的空投总量(授予VIP)
    mapping(uint256 => uint256) private _totalPerMonth;

    // VIP账户 => 领取比例
    mapping(address => uint256) private _vips;

    // vip => month => ratio
    // 记录VIP的收益月份历史领取比例
    mapping(address => mapping(uint256 => uint256)) private _vipHistoryRatios;
    // 记录VIP的收益月份历史是否改变过
    mapping(address => mapping(uint256 => bool)) private _vipChangedAtMonth;

    address[] private _vipAccs;

    uint256 private _totalRatios;
    // 记录VIP账户当前提取到的月份，初始为0，即从未提取
    mapping(address => uint256) private _vipClaimedMonth;
    // VIP当前已经提取的总量
    mapping(address => uint256) private _vipClaimedAmount;
    // VIP可提取开始时间
    uint256 private _startAt;

    // Proposal with MulSig
    mapping(uint256 => Proposal) private proposals;
    mapping(uint256 => bool) private proposalExecuted;
    uint256 private currProposalId;

    uint256 private PROPOSAL_TIME_LOCK;

    receive() external payable {}

    function initialize(
        address[] memory vips,
        uint256[] memory ratios,
        address[] memory foundationManagers,
        address[] memory boardDirectors
    ) public initializer {
        __Ownable_init();
        require(foundationManagers.length >= 2, "must provide >2 foundation managers");
        require(boardDirectors.length >= 3, "must provide > 3 board directorys");
        require(vips.length != 0, "zero vips accounts");
        require(vips.length == ratios.length, "vips.length must equal to ratios.length");

        // 基金会3000w，第一阶段直接授予1500w
        _toFoundation[ClaimStage.Stage1] = 15000000 * 1e18;
        /* for test 15*/
        /*_toFoundation[ClaimStage.Stage1] = 15 * 1e18;*/
        // _timeline[ClaimStage.Stage1] = block.timestamp;
        // 第二阶段为第一阶段的3个月后，此时解锁另外的1500w
        _toFoundation[ClaimStage.Stage2] = 15000000 * 1e18;
        /* for test 15 */
        /*_toFoundation[ClaimStage.Stage2] = 15 * 1e18;*/
        // _timeline[ClaimStage.Stage2] = block.timestamp + 90 days;

        // 空投开始时间为当前合约初始化时间
        _startAt = block.timestamp;

        // 授予VIP客户6000w
         _remainedToVips = 60000000 * 1e18;
        /* for test 60 */
        /*_remainedToVips = 60 * 1e18;*/
        for (uint256 i = 1; i <= RELEASE_PERIODS; i++) {
            _totalPerMonth[i] = _remainedToVips / RELEASE_PERIODS;
        }

        // NOTE: always use 1st FM as the payable
        _foundation = foundationManagers[0];
        for (uint256 i = 0; i < foundationManagers.length; i++) {
            require(foundationManagers[i] != address(0), "has empty fm account");
            _fms.push(foundationManagers[i]);
        }
        for (uint256 i = 0; i < boardDirectors.length; i++) {
            require(boardDirectors[i] != address(0), "has empty board director account");
            _boardDirectors.push(boardDirectors[i]);
        }

        uint256 totalRatios;
        for (uint256 i = 0; i < vips.length; i++) {
            require(vips[i] != address(0), "has empty vip account");
            require(vips[i] != _foundation, "vip can't be foundation at the same time");
            require(_vips[vips[i]] == 0, "found duplicate vip account");

            _vips[vips[i]] = ratios[i];

            // 首月领取比例
            _vipHistoryRatios[vips[i]][1] = ratios[i];
            _vipChangedAtMonth[vips[i]][1] = true;

            _vipAccs.push(vips[i]);

            totalRatios = totalRatios + ratios[i];
        }
        /*require(totalRatios <= 100, "total ratios must <= 100");*/
        require(totalRatios <= 100 * 1e6, "total ratios must <= 100 * 1e6");
        _totalRatios = totalRatios;

        PROPOSAL_TIME_LOCK = 48 hours;
        /* for test 1mins */
        /*PROPOSAL_TIME_LOCK = 1 minutes;*/
    }

    modifier onlyFoundation() {
        require(msg.sender == _foundation, "only Foundation account is allowed");
        _;
    }

    modifier onlyFM() {
        bool found;
        for (uint256 i = 0; i < _fms.length; i++) {
            if (_fms[i] == msg.sender) {
                found = true;
                break;
            }
        }
        require(found, "only FoundationManager allowed");
        _;
    }

    function deployedAt() public view returns (uint256) {
        return _startAt;
    }

    function getRole(address account) public view returns (Role) {
        if (account == _foundation) {
            return Role.FOUNDATION;
        }
        if (_vips[account] != 0) {
            return Role.VIP;
        }
        return Role.Unknown;
    }

    function getVIPs() public view onlyFM returns (address[] memory, uint256[] memory) {
        uint256[] memory ratios = new uint256[](_vipAccs.length);
        for (uint256 i = 0; i < _vipAccs.length; i++) {
            ratios[i] = _vips[_vipAccs[i]];
        }
        return (_vipAccs, ratios);
    }

    function getVIPInfo(address vip)
    public
    view
    returns (
        uint256,
        uint256,
        uint256,
        uint256
    )
    {
        (uint256 totalClaimable, uint256 sinceMonth, uint256 toMonth) = _vipClaimable(vip);
        return (_vipClaimedAmount[vip], totalClaimable, sinceMonth, toMonth);
    }

    function remainedToVIPs() public view returns (uint256) {
        return _remainedToVips;
    }

    function claimable()
    public
    view
    returns (
        Role,
        uint256,
        ClaimStage,
        uint256,
        uint256
    )
    {
        address sender = msg.sender;
        // Foundation
        if (sender == _foundation) {
            (uint256 unaclaimedCmount, ClaimStage stage) = _foundationClaimable();
            return (Role.FOUNDATION, unaclaimedCmount, stage, 0, 0);
        }

        // VIP
        (uint256 amount, uint256 sinceMonth, uint256 toMonth) = _vipClaimable(sender);

        return (Role.VIP, amount, ClaimStage.Stage1, sinceMonth, toMonth);
    }

    function _foundationClaimable() internal view returns (uint256, ClaimStage) {
        ClaimStage currentStage = ClaimStage.Stage1;
        if (block.timestamp > _startAt + STAGE_TIMELOCK) {
            currentStage = ClaimStage.Stage2;
        }
        uint256 amount;
        // 判断当前阶段是否已经提取
        if (_toFoundation[currentStage] > 0) {
            amount += _toFoundation[currentStage];
        }
        // 判断阶段1是否已经提取
        if (currentStage == ClaimStage.Stage2 && _toFoundation[ClaimStage.Stage1] > 0) {
            amount += _toFoundation[ClaimStage.Stage1];
        }
        return (amount, currentStage);
    }

    function _vipClaimable(address vip) internal view returns (uint256, uint256, uint256) {
        // 判断是否已经提取完
        if (_remainedToVips == 0) {
            return (0, 0, 0);
        }

        // 计算从上次提取月份到当前月份之间总得可提取额度
        uint256 current = _currentMonth();

        // 最大为12
        if (current > RELEASE_PERIODS) {
            current = RELEASE_PERIODS;
        }

        uint256 claimedMonth = _vipClaimedMonth[vip];
        // 判断是否已经提取到了当前月份
        if (claimedMonth == current) {
            return (0, 0, 0);
        }

        // 计算从当前未提取月份到当前可提取月份之间
        uint256 totalClaimable;
        for (uint256 i = claimedMonth + 1; i <= current; i++) {
            //计算该月份可提取的数量(该月份的可提取总量*提取比例)
            uint256 actualRatio;
            for (uint256 j = i; j > 0; j--) {
                // 寻找最近一次的更新，作为当前月份的真实比例
                if (_vipChangedAtMonth[vip][j]) {
                    actualRatio = _vipHistoryRatios[vip][j];
                    break;
                }
            }

            uint256 amount = 0;
            /*amount = (_totalPerMonth[i] * actualRatio) / 100;*/
            if (i == 1) {
                amount = (_totalPerMonth[i] * actualRatio) / 100;
            }
            else {
                amount = _totalPerMonth[i] * actualRatio / 100 / 1e6;
                //1e6 actualRatio 小数问题 从第二期开始
            }
            totalClaimable = totalClaimable + amount;
        }
        return (totalClaimable, claimedMonth + 1, current);
    }

    event Claimed(
        Role role,
        uint256 claimedAmount,
        ClaimStage stage,
        uint256 sinceMonth,
        uint256 toMonth
    );

    function claim() public {
        if (msg.sender == _foundation) {
            (uint256 amount, ClaimStage stage) = _foundationClaim();
            emit Claimed(Role.FOUNDATION, amount, stage, 0, 0);
            return;
        }

        (uint256 vipAmount, uint256 sinceMonth, uint256 toMonth) = _vipClaim();
        emit Claimed(Role.VIP, vipAmount, ClaimStage.Stage1, sinceMonth, toMonth);

        return;
    }

    function foundationWithdrawed() public view returns (uint256) {
        return _toFoundation[ClaimStage.Stage1];
    }

    // foundationClaim用于基金会提取
    event FoundationClaimed(address foundation, ClaimStage stage, uint256 amount);

    function _foundationClaim() internal returns (uint256, ClaimStage) {
        (uint256 amount, ClaimStage currentStage) = _foundationClaimable();

        require(amount > 0, "foundation is unclaimable");

        _toFoundation[currentStage] = 0;

        if (currentStage == ClaimStage.Stage2 && _toFoundation[ClaimStage.Stage1] > 0) {
            _toFoundation[ClaimStage.Stage1] = 0;
        }

        payable(_foundation).transfer(amount);
        emit FoundationClaimed(_foundation, currentStage, amount);

        return (amount, currentStage);
    }

    event VIPClaimed(address vip, uint256 sinceMonth, uint256 toMonth, uint256 amount);

    function _vipClaim()
    internal
    returns (
        uint256,
        uint256,
        uint256
    )
    {
        // 计算当前可提取额度
        (uint256 amount, uint256 sinceMonth, uint256 toMonth) = _vipClaimable(msg.sender);

        require(amount > 0, "this vip is unclaimable");

        //更新当前的未提取额
        _remainedToVips = _remainedToVips - amount;

        // 更新VIP的提取记录
        _vipClaimedMonth[msg.sender] = toMonth;
        _vipClaimedAmount[msg.sender] += amount;

        payable(msg.sender).transfer(amount);

        emit VIPClaimed(msg.sender, sinceMonth, toMonth, amount);

        return (amount, sinceMonth, toMonth);
    }

    // eceiveIntermidiateFund UNIT to `toVIPs`
    event ReceivedInterFund(
        address from,
        uint256 currentMonth,
        uint256 amount,
        uint256 remainedToVips
    );

    function receiveIntermidiateFund() public payable {
        require(msg.value > 0, "zero UNIT");
        uint256 month = _currentMonth();
        // 当前月份在第12或者12个月后，代表空投已经结束
        if (month >= RELEASE_PERIODS) {
            return;
        }
        // 重新计算每月可提取的数量
        uint256 remainedMonths = RELEASE_PERIODS - _currentMonth();
        for (uint256 i = month + 1; i <= RELEASE_PERIODS; i++) {
            _totalPerMonth[i] = _totalPerMonth[i] + msg.value / remainedMonths;
        }
        _remainedToVips = _remainedToVips + msg.value;
        emit ReceivedInterFund(msg.sender, _currentMonth(), msg.value, _remainedToVips);
    }

    event FoundationClaimedVIPs(address account, uint256 amount);
    // 1 年后，基金会可以提取出所有为VIPs准备的空投金
    function foundationClaimVIPs() public onlyFoundation {
        require(
            _currentMonth() > RELEASE_PERIODS,
            "only excceedes the total periods(1year/12months)"
        );
        require(_remainedToVips > 0, "all claimed by VIPs(zero remainedToVips)");

        payable(_foundation).transfer(_remainedToVips);

        emit FoundationClaimedVIPs(_foundation, _remainedToVips);

        _remainedToVips = 0;


    }

    // 当前可提取的月份(3.1 == 3)
    function _currentMonth() internal view returns (uint256) {
        return (block.timestamp - _startAt) / AirDrop_TIMELOCK;
    }

    /* Integrate with MulSig */

    // 修改用户白名单和用户比例(MulSig)
    enum ProposalPurpose {
        ChangeVIP
    }
    struct Proposal {
        address proposer;
        ProposalPurpose purpose;
        address[] vips;
        uint256[] ratios;
        // 签名数量
        uint8 sigCount;
        // 执行时间
        uint256 excuteTime;
        mapping(address => uint8) signatures;
    }

    function _nextProposalId() internal returns (uint256) {
        currProposalId++;
        return currProposalId;
    }

    event SendProposal(
        uint256 proposalId,
        address proposer,
        ProposalPurpose purpose,
        address[] vips,
        uint256[] ratios
    );

    function propose(
        ProposalPurpose purpose,
        address[] memory vips,
        uint256[] memory ratios
    ) public returns (uint256) {
        require(vips.length == ratios.length, "vips and ratios must have same length");

        uint256 tempTotal = _totalRatios;
        for (uint256 i = 0; i < vips.length; i++) {
            require(vips[i] != address(0), "has zero vip address");
            /*require(ratios[i] <= 100, "ratio must <= 100");*/
            require(ratios[i] <= 100 * 1e6, "ratio must <= 100 * 1e6");

            uint256 currRatio = _vips[vips[i]];
            tempTotal = tempTotal - currRatio + ratios[i];
        }
        /*require(tempTotal <= 100, "total ratio must <=100");*/
        require(tempTotal <= 100 * 1e6, "total ratio must <=100 * 1e6");

        uint256 proposalId = _nextProposalId();

        Proposal storage proposal = proposals[proposalId];
        proposal.purpose = purpose;
        proposal.proposer = msg.sender;
        proposal.vips = vips;
        proposal.ratios = ratios;

        emit SendProposal(proposalId, msg.sender, purpose, vips, ratios);

        return proposalId;
    }

    // 0: 都不是  1: FoundationManager 2:BoardDirector
    function _fmOrBd(address account) internal view returns (uint256) {
        for (uint256 i = 0; i < _fms.length; i++) {
            if (_fms[i] == account) {
                return 1;
            }
        }

        for (uint256 i = 0; i < _boardDirectors.length; i++) {
            if (_boardDirectors[i] == account) {
                return 2;
            }
        }

        return 0;
    }

    function threshold() public pure returns (uint256) {
        return 3;
    }

    event ProposalSucc(uint256 proposalId, uint256 executeTime);
    event ProposalSigned(uint256 proposalId, address signer);

    /// @dev 由FoundationManager签发交易，同意某proposal
    /// @param _proposalId 提议对应的ID
    /// @return bool 请求是否成功
    function signTransaction(uint256 _proposalId) public returns (bool) {
        uint256 role = _fmOrBd(msg.sender);
        require(role != 0, "only FoundationManager or BoardDirector can sign");
        Proposal storage pro = proposals[_proposalId];
        require(pro.signatures[msg.sender] != 1, "already signed");

        pro.signatures[msg.sender] = 1;

        require(pro.sigCount < threshold(), "proposal already meet threshold");
        pro.sigCount++;

        // 满足阈值，设置执行时间(生效时间)
        if (pro.sigCount == threshold()) {
            pro.excuteTime = block.timestamp + PROPOSAL_TIME_LOCK;
            emit ProposalSucc(_proposalId, pro.excuteTime);
        }
        emit ProposalSigned(_proposalId, msg.sender);

        return true;
    }

    event ProposalExecuted(uint256 proposalId, ProposalPurpose purpose);
    event ChangeVIP(address vip, uint256 before, uint256 now);

    function executeProposal(uint256 _proposalId) public {
        require(!proposalExecuted[_proposalId], "proposal has been executed");

        Proposal storage pro = proposals[_proposalId];
        require(pro.proposer != address(0), "propsoal with this proposalId may not exist");
        /*require(pro.excuteTime > 0 && pro.excuteTime <= block.timestamp, "executeTime not meet");*/
        require(pro.sigCount >= threshold(), "proposal not meet threshold");

        if (pro.purpose == ProposalPurpose.ChangeVIP) {
            uint256 tempTotal = _totalRatios;
            for (uint256 i = 0; i < pro.vips.length; i++) {
                uint256 currRatio = _vips[pro.vips[i]];
                _vips[pro.vips[i]] = pro.ratios[i];
                if (currRatio == 0) {
                    _vipAccs.push(pro.vips[i]);
                }
                // 记录历史比例
                // 影响的是第二个周期的收益比例
                // |  currMonth() | curr | next  |
                _vipHistoryRatios[pro.vips[i]][_currentMonth() + 1] = pro.ratios[i];
                _vipChangedAtMonth[pro.vips[i]][_currentMonth() + 1] = true;
                tempTotal = tempTotal - currRatio + pro.ratios[i];
                emit ChangeVIP(pro.vips[i], currRatio, pro.ratios[i]);
            }
            /*require(tempTotal <= 100, "total ratios must <= 100");*/
            require(tempTotal <= 100 * 1e6, "total ratios must <= 100 * 1e6");
            _totalRatios = tempTotal;
        }

        proposalExecuted[_proposalId] = true;

        emit ProposalExecuted(_proposalId, pro.purpose);
    }
}
