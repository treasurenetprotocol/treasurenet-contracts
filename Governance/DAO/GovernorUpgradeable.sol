// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.2) (governance/Governor.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/DoubleEndedQueueUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/TimersUpgradeable.sol";
import "./IGovernorUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev GoverorUpgradeable实现了DAO合约的核心功能
 * @author bjwswang
 */
abstract contract GovernorUpgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, EIP712Upgradeable, IGovernorUpgradeable {
    using DoubleEndedQueueUpgradeable for DoubleEndedQueueUpgradeable.Bytes32Deque;
    using SafeCastUpgradeable for uint256;
    using TimersUpgradeable for TimersUpgradeable.BlockNumber;

    bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,uint8 support)");
    bytes32 public constant EXTENDED_BALLOT_TYPEHASH =
    keccak256("ExtendedBallot(uint256 proposalId,uint8 support,string reason,bytes params)");

    struct ProposalCore {
        TimersUpgradeable.BlockNumber voteStart;
        TimersUpgradeable.BlockNumber voteEnd;
        bool queued;
        bool executed;
        bool canceled;
        bool manualExecuted;
    }

    string private _name;

    mapping(uint256 => ProposalCore) private _proposals;

    uint256 private _minDelay;

    // proposalId => timestamp
    mapping(uint256 => uint256) private _timestamps;
    uint256 internal constant _DONE_TIMESTAMP = uint256(1);

    struct Vote {
        address Voter;
        uint256 amount;
        bool withdrawed;
    }

    mapping(uint256 => mapping(address => Vote)) private _votes;


    // This queue keeps track of the governor operating on itself. Calls to functions protected by the
    // {onlyGovernance} modifier needs to be whitelisted in this queue. Whitelisting is set in {_beforeExecute},
    // consumed by the {onlyGovernance} modifier and eventually reset in {_afterExecute}. This ensures that the
    // execution of {onlyGovernance} protected calls can only be achieved through successful proposals.
    DoubleEndedQueueUpgradeable.Bytes32Deque private _governanceCall;

    /**
     * @dev Restricts a function so it can only be executed through governance proposals. For example, governance
     * parameter setters in {GovernorSettings} are protected using this modifier.
     *
     * The governance executing address may be different from the Governor's own address, for example it could be a
     * timelock. This can be customized by modules by overriding {_executor}. The executor is only able to invoke these
     * functions during the execution of the governor's {execute} function, and not under any other circumstances. Thus,
     * for example, additional timelock proposers are not able to change governance parameters without going through the
     * governance protocol (since v4.6).
     */
    modifier onlyGovernance() {
        require(_msgSender() == _executor(), "Governor: onlyGovernance");
        if (_executor() != address(this)) {
            bytes32 msgDataHash = keccak256(_msgData());
            // loop until popping the expected operation - throw if deque is empty (operation not authorized)
            while (_governanceCall.popFront() != msgDataHash) {}
        }
        _;
    }

    /**
     * @dev Sets the value for {name} and {version}
     */
    function __Governor_init(string memory name_, uint256 minDelay_) internal onlyInitializing {
        __EIP712_init_unchained(name_, version());
        __Governor_init_unchained(name_);
        _minDelay = minDelay_;
    }

    function __Governor_init_unchained(string memory name_) internal onlyInitializing {
        _name = name_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC165Upgradeable) returns (bool) {
        // In addition to the current interfaceId, also support previous version of the interfaceId that did not
        // include the castVoteWithReasonAndParams() function as standard
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IGovernor-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IGovernor-version}.
     */
    function version() public view virtual override returns (string memory) {
        return "1";
    }


    function _updateDelay(uint256 newDelay) public virtual onlyGovernance {
        _minDelay = newDelay;
    }

    function _getDelay() internal view returns (uint256) {
        return _minDelay;
    }

    function hashProposal(
        address[] memory targets,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public pure virtual override returns (uint256) {
        return uint256(keccak256(abi.encode(targets, calldatas, descriptionHash)));
    }

    /// @dev 查询proposal的当前状态
    /// @param proposalId 提议的ID
    /// @return ProposalState
    /// enum ProposalState {
    ///     Pending,
    ///     Active,
    ///     Canceled,
    ///     Defeated,
    ///     Succeeded,
    ///     Queued,
    ///     Expired,
    ///     Executed,
    ///     ManualExecuted
    /// }
    function state(uint256 proposalId) public view virtual override returns (ProposalState) {
        ProposalCore storage proposal = _proposals[proposalId];

        if (proposal.queued) {
            return ProposalState.Queued;
        }

        if (proposal.executed) {
            return ProposalState.Executed;
        }

        if (proposal.canceled) {
            return ProposalState.Canceled;
        }

        if (proposal.manualExecuted) {
            return ProposalState.ManualExecuted;
        }

        uint256 snapshot = proposalSnapshot(proposalId);

        if (snapshot == 0) {
            revert("Governor: unknown proposal id");
        }

        if (snapshot >= block.number) {
            return ProposalState.Pending;
        }

        uint256 deadline = proposalDeadline(proposalId);

        if (deadline >= block.number) {
            return ProposalState.Active;
        }

        if (_quorumReached(proposalId) && _voteSucceeded(proposalId)) {
            return ProposalState.Succeeded;
        } else {
            return ProposalState.Defeated;
        }
    }

    /// @dev 查询proposal投票的开始时间
    /// @param proposalId 提议的ID
    /// @return uint256 开始时间(block number)
    function proposalSnapshot(uint256 proposalId) public view virtual override returns (uint256) {
        return _proposals[proposalId].voteStart.getDeadline();
    }

    /// @dev 查询proposal投票的截止时间(block number)
    /// @param proposalId 提议的ID
    /// @return uint256 截止时间(block number)
    function proposalDeadline(uint256 proposalId) public view virtual override returns (uint256) {
        return _proposals[proposalId].voteEnd.getDeadline();
    }

    /**
     * @dev Part of the Governor Bravo's interface: _"The number of votes required in order for a voter to become a proposer"_.
     */
    function proposalThreshold() public view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Amount of votes already cast passes the threshold limit.
     */
    function _quorumReached(uint256 proposalId) internal view virtual returns (bool);

    /**
     * @dev Is the proposal successful or not.
     */
    function _voteSucceeded(uint256 proposalId) internal view virtual returns (bool);


    /**
     * @dev Register a vote for `proposalId` by `account` with a given `support`, voting `weight` and voting `params`.
     *
     * Note: Support is generic and can represent various things depending on the voting system used.
     */
    function _countVote(
        uint256 proposalId,
        address account,
        uint8 support,
        uint256 weight
    ) internal virtual;


    /// @dev 发起一个新的提议
    /// @param targets 目标合约地址
    /// @param calldatas 合约调用数据
    /// @param description 描述信息
    /// @return uint256 proposal id
    function propose(
        address[] memory targets,
        bytes[] memory calldatas,
        string memory description
    ) public payable virtual override returns (uint256) {
        uint256 proposalId = hashProposal(targets, calldatas, keccak256(bytes(description)));

        require(targets.length == calldatas.length, "Governor: invalid proposal length");
        //require(targets.length > 0, "Governor: empty proposal");  //有手动执行的版本

        if (targets.length == 0) {//手动执行的版本
            require(msg.value >= 1 * 1e18, "Minimum 1UNIT");
            //要收费
        }

        ProposalCore storage proposal = _proposals[proposalId];
        require(proposal.voteStart.isUnset(), "Governor: proposal already exists");

        uint64 snapshot = 0;
        if (targets.length == 0) {//手动执行的版本
            snapshot = block.number.toUint64() - 1;
            //手动执行的版本不存在投票延迟
        }
        else {
            snapshot = block.number.toUint64() + votingDelay().toUint64();
        }
        uint64 deadline = snapshot + votingPeriod().toUint64();

        proposal.voteStart.setDeadline(snapshot);
        proposal.voteEnd.setDeadline(deadline);

        //payable(address(this)).transfer(msg.value);  //收费

        if (targets.length == 0) {//手动执行的版本 此处附加一次投票动作

            address voter = _msgSender();

            Vote memory vote;
            vote.Voter = voter;
            vote.amount = msg.value;
            vote.withdrawed = false;

            _votes[proposalId][voter] = vote;

            _castVote(proposalId, voter, 0, msg.value);
        }

        emit ProposalCreated(
            proposalId,
            _msgSender(),
            targets,
            calldatas,
            snapshot,
            deadline,
            description
        );

        return proposalId;
    }


    /// @dev 将投票成功的proposal(Succeeded)转移到待执行队列
    /// @param targets 目标合约地址
    /// @param calldatas 合约调用数据
    /// @param descriptionHash 描述信息的哈希值
    /// @return uint256 proposal id
    function queue(
        address[] memory targets,
        bytes[] memory calldatas,
        bytes32 descriptionHash) public virtual override returns (uint256) {

        uint256 proposalId = hashProposal(targets, calldatas, descriptionHash);
        ProposalState status = state(proposalId);

        require(status == ProposalState.Succeeded, "Governor: proposal not Succeeded yet");

        _timestamps[proposalId] = block.timestamp + _getDelay();
        _proposals[proposalId].queued = true;

        emit ProposalQueued(proposalId, block.timestamp + _getDelay());

        return proposalId;
    }

    /* 非执行类 只需要手动处理 标识完成执行即可 */
    function manualExecuted(
        uint256 proposalId
    ) public virtual override returns (uint256){
        //uint256 proposalId = hashProposal(targets, calldatas, descriptionHash);
        ProposalState status = state(proposalId);
        require(status == ProposalState.Queued, "Governor: proposal not Queued yet");
        _proposals[proposalId].queued = false;
        _proposals[proposalId].manualExecuted = true;
        _timestamps[proposalId] = _DONE_TIMESTAMP;
        emit ProposalManualExecuted(proposalId);
        return proposalId;
    }


    /// @dev 执行已经在待执行队列的proposal(Queued)
    /// @param targets 目标合约地址
    /// @param calldatas 合约调用数据
    /// @param descriptionHash 描述信息的哈希值
    /// @return uint256 proposal id
    function execute(
        address[] memory targets,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public payable virtual override returns (uint256) {
        uint256 proposalId = hashProposal(targets, calldatas, descriptionHash);

        ProposalState status = state(proposalId);

        require(status == ProposalState.Queued, "Governor: proposal not Queued yet");

        require(_timestamps[proposalId] != _DONE_TIMESTAMP && _timestamps[proposalId] < block.timestamp, "min deplay not passed yet");


        _proposals[proposalId].queued = false;
        _proposals[proposalId].executed = true;

        _timestamps[proposalId] = _DONE_TIMESTAMP;


        emit ProposalExecuted(proposalId);

        _beforeExecute(proposalId, targets, calldatas, descriptionHash);
        _execute(proposalId, targets, calldatas, descriptionHash);
        _afterExecute(proposalId, targets, calldatas, descriptionHash);

        return proposalId;
    }

    /**
     * @dev Internal execution mechanism. Can be overridden to implement different execution mechanism
     */
    function _execute(
        uint256, /* proposalId */
        address[] memory targets,
        bytes[] memory calldatas,
        bytes32 /*descriptionHash*/
    ) internal virtual {
        string memory errorMessage = "Governor: call reverted without message";
        for (uint256 i = 0; i < targets.length; ++i) {
            (bool success, bytes memory returndata) = targets[i].call(calldatas[i]);
            AddressUpgradeable.verifyCallResult(success, returndata, errorMessage);
        }
    }

    /**
     * @dev Hook before execution is triggered.
     */
    function _beforeExecute(
        uint256, /* proposalId */
        address[] memory targets,
        bytes[] memory calldatas,
        bytes32 /*descriptionHash*/
    ) internal virtual {
    }

    /**
     * @dev Hook after execution is triggered.
     */
    function _afterExecute(
        uint256, /* proposalId */
        address[] memory, /* targets */
        bytes[] memory, /* calldatas */
        bytes32 /*descriptionHash*/
    ) internal virtual {}

    /**
     * @dev Internal cancel mechanism: locks up the proposal timer, preventing it from being re-submitted. Marks it as
     * canceled to allow distinguishing it from executed proposals.
     *
     * Emits a {IGovernor-ProposalCanceled} event.
     */
    function _cancel(
        address[] memory targets,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal virtual returns (uint256) {
        uint256 proposalId = hashProposal(targets, calldatas, descriptionHash);
        ProposalState status = state(proposalId);

        require(
            status != ProposalState.Canceled && status != ProposalState.Expired && status != ProposalState.Executed,
            "Governor: proposal not active"
        );
        _proposals[proposalId].canceled = true;

        emit ProposalCanceled(proposalId);

        return proposalId;
    }

    /// @dev 发起投票(投票会质押一定的Token)
    /// @param proposalId 提议id
    /// @param support 是否支持该提议
    ///     enum VoteType {
    ///         Against, // 反对
    ///         For,   // 同意
    ///         Abstain  // 弃权
    ///     }
    /// @return uint256 返回weight
    function castVote(uint256 proposalId, uint8 support) public payable virtual override returns (uint256) {
        require(msg.value >= 1 * 1e18, "Minimum 1UNIT");
        address voter = _msgSender();

        Vote memory vote;
        vote.Voter = voter;
        vote.amount = msg.value;
        vote.withdrawed = false;

        _votes[proposalId][voter] = vote;

        return _castVote(proposalId, voter, support, msg.value);
    }


    /**
     * @dev Internal vote casting mechanism: Check that the vote is pending, that it has not been cast yet, retrieve
     * voting weight using {IGovernor-getVotes} and call the {_countVote} internal function.
     *
     * Emits a {IGovernor-VoteCast} event.
     */
    function _castVote(
        uint256 proposalId,
        address account,
        uint8 support,
        uint256 weight
    ) internal virtual returns (uint256) {
        require(state(proposalId) == ProposalState.Active, "Governor: vote not currently active");

        _countVote(proposalId, account, support, weight);

        emit VoteCast(account, proposalId, support, weight);

        return weight;
    }

    /**
     * @dev Relays a transaction or function call to an arbitrary target. In cases where the governance executor
     * is some contract other than the governor itself, like when using a timelock, this function can be invoked
     * in a governance proposal to recover tokens or Ether that was sent to the governor contract by mistake.
     * Note that if the executor is simply the governor itself, use of `relay` is redundant.
     */
    function relay(
        address target,
        uint256 value,
        bytes calldata data
    ) external virtual onlyGovernance {
        AddressUpgradeable.functionCallWithValue(target, data, value);
    }

    /**
     * @dev Address through which the governor executes action. Will be overloaded by module that execute actions
     * through another contract such as a timelock.
     */
    function _executor() internal view virtual returns (address) {
        return address(this);
    }


    /// @dev 提议结束后，投票者可提回其token
    /// @param proposalId 提议id
    /// @return uint256 返回得token数量
    function withdraw(uint256 proposalId) public payable virtual override returns (uint256) {
        require(state(proposalId) == ProposalState.Canceled || state(proposalId) == ProposalState.Defeated || state(proposalId) == ProposalState.Expired || state(proposalId) == ProposalState.Executed || state(proposalId) == ProposalState.ManualExecuted, "can not withdraw due to current proposal state");

        Vote storage vote = _votes[proposalId][_msgSender()];
        require(vote.withdrawed == false, "already withdrawed before");
        vote.withdrawed = true;

        payable(msg.sender).transfer(vote.amount);

        emit Withdrawed(proposalId, msg.sender, vote.amount);

        return vote.amount;
    }


    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}
