// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./GovernorUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


/**
 * @dev DAO 自治组织合约实现
 * @title DAO 自治组织合约
 * @author bjwswang
 */
contract DAO is OwnableUpgradeable,GovernorUpgradeable {
    /// DAO合约部署时区块时间
    uint256 private _deployedBlockTime;
    /// 当前区块奖励
    uint256 private _blockReward;
    /// 投票周期
    uint256 private _votingPeriod;

    event MinDelayChange(uint256 oldDuration, uint256 newDuration);

    /// 投票类型: Agains反对 For统一 Abstain弃权
    enum VoteType {
        Against,
        For,
        Abstain
    }

    struct ProposalVote {
        uint256 againstVotes;
        uint256 forVotes;
        uint256 abstainVotes;
        mapping(address => bool) hasVoted;
    }

    mapping(uint256 => ProposalVote) private _proposalVotes;

    event ProposalThresholdSet(uint256 oldProposalThreshold, uint256 newProposalThreshold);

    modifier onlyDAO() {
        require(_msgSender() == address(this), "only DAO");
        _;
    }

    /// @dev 合约初始化
    /// @param _name DAO组织名称
    /// @param _minTimeDelay 最小时间延时 (timestamp)
    /// @param __votingPeriod 投票周期 ()
    function initialize(string memory _name,uint256 _minTimeDelay,uint256 __votingPeriod) public initializer {
        __Ownable_init();
        __Governor_init(_name,_minTimeDelay);

        _deployedBlockTime = block.number;

        _blockReward = 5;
        // with blocks
        _votingPeriod = __votingPeriod;
    }

    receive() external payable {}
    fallback() external payable {}

    // Governor implementation

    function COUNTING_MODE() public pure virtual override returns (string memory) {
        return "support=bravo&quorum=for,abstain";
    }

    /// @dev 用户是否已经投票
    /// @param proposalId 提议的ID
    /// @param account 账户地址
    /// @return bool 是否投票
    function hasVoted(uint256 proposalId, address account)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _proposalVotes[proposalId].hasVoted[account];
    }

    /// @dev 查看proposal当前的投票详情
    /// @param proposalId 提议的ID
    /// @return uint256 投反对票的数量
    /// @return uint256 投同意票的数量
    /// @return uint256 投弃权票的数量
    function proposalVotes(uint256 proposalId)
        public
        view
        virtual
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        ProposalVote storage proposalvote = _proposalVotes[proposalId];
        return (proposalvote.againstVotes, proposalvote.forVotes, proposalvote.abstainVotes);
    }

    /// @dev 更新time depay(通过DAO提议完成)
    /// @param newDelay 新的延时配置
    function updateDelay(uint256 newDelay) public virtual override onlyDAO() {
        _updateDelay(newDelay);
    }

    /// @dev 查询当前votingDelay
    /// @return uint256 返回
    function votingDelay() public view override returns (uint256) {
        return _getDelay();
    }

    /// @dev 更新投票周期(通过DAO提议完成)
    /// @param newVotingPeriod 新的投票周期
    function updateVotingPeriod(uint256 newVotingPeriod) public virtual  onlyDAO() {
        _votingPeriod = newVotingPeriod;
    }

    /// @dev 查询当前投票周期
    /// @return uint256 投票周期
    function votingPeriod() public view override returns (uint256) {
        return _votingPeriod;
    }

    /// @dev 设置区块奖励
    /// @param newBlockReward 新的区块奖励
    function setBlockReward(uint256 newBlockReward) public onlyDAO() {
        _blockReward = newBlockReward;
    }

    /// @dev 查询区块奖励
    /// @return uint 区块奖励
    function blockReward() public view returns(uint) {
        return _blockReward;
    }

    /// @dev 提议生效的法定票数
    /// @return uint256 返回值
    function quorum(uint256 blockNumber) public view override returns (uint256) {
        return ((blockNumber - _deployedBlockTime) * _blockReward * 5) / 100;
    }

    function _quorumReached(uint256 proposalId) internal view virtual override returns (bool) {
        ProposalVote storage proposalvote = _proposalVotes[proposalId];

        return
            quorum(proposalSnapshot(proposalId)) <=
            proposalvote.forVotes + proposalvote.abstainVotes;
    }

    function _voteSucceeded(uint256 proposalId) internal view virtual override returns (bool) {
        ProposalVote storage proposalvote = _proposalVotes[proposalId];

        return proposalvote.forVotes > proposalvote.againstVotes;
    }

    function _countVote(
        uint256 proposalId,
        address account,
        uint8 support,
        uint256 weight
    ) internal virtual override {
        ProposalVote storage proposalvote = _proposalVotes[proposalId];

        require(!proposalvote.hasVoted[account], "GovernorVotingSimple: vote already cast");
        proposalvote.hasVoted[account] = true;

        if (support == uint8(VoteType.Against)) {
            proposalvote.againstVotes += weight;
        } else if (support == uint8(VoteType.For)) {
            proposalvote.forVotes += weight;
        } else if (support == uint8(VoteType.Abstain)) {
            proposalvote.abstainVotes += weight;
        } else {
            revert("GovernorVotingSimple: invalid value for enum VoteType");
        }
    }
}
