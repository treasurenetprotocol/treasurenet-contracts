// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "./Stakeable.sol";
import "../Governance/IGovernance.sol";

/**
 * @dev TAT为TreasureNet ERC20 Token，实现了:
 *    - ERC20,其中mint由`production data contract`执行
 *    - Pausable
 *    - Burnable
 *    - Stake
*/
contract TAT is
Initializable,
OwnableUpgradeable,
ERC20PausableUpgradeable,
ERC20BurnableUpgradeable,
Stakeable
{
    IGovernance private _governance;

    /// @dev 合约初始化
    /// @param _name Token名称
    /// @param _symbol Token Symbol
    /// @param _governanceContract TreasureNet的治理合约
    function initialize(
        string memory _name,
        string memory _symbol,
        address _governanceContract
    ) public initializer {
        __Ownable_init();
        __ERC20_init(_name, _symbol);
        __ERC20Burnable_init();
        __ERC20Pausable_init();
        _governance = IGovernance(_governanceContract);
    }

    modifier onlyProductionDataContract(string memory _treasureKind) {
        // check producer by group
        (, address productionContract) = _governance.getTreasureByKind(_treasureKind);
        require(_msgSender() == productionContract, "");
        _;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20Upgradeable, ERC20PausableUpgradeable) {
        super._beforeTokenTransfer(from, to, amount);
        require(!paused(), "ERC20Pausable: token transfer while paused");
    }

    event TATHistory(string kind, bytes32 uniqueId, address from, address to, uint amount);
    /// @dev mint TAT
    /// @param _treasureKind treasure类型
    /// @param to  tat接收账户
    /// @param amount mint的TAT数量
    function mint(
        string memory _treasureKind,
        bytes32 _uniqueId,
        address to,
        uint256 amount
    ) public onlyProductionDataContract(_treasureKind) {
        require(to != address(0), "zero address");
        _mint(to, amount);
        emit TATHistory(_treasureKind, _uniqueId, msg.sender, to, amount);
    }

    /* temp faucet */
    function faucet(address user, uint256 amount) public {
        require(user != address(0), "zero address");
        _mint(user, amount);
    }

    /// @dev burn TAT
    /// @param _treasureKind treasure类型
    /// @param tokens 数量
    function burn(string memory _treasureKind, uint256 tokens)
    public
    onlyProductionDataContract(_treasureKind)
    {
        _burn(_msgSender(), tokens);
    }

    /// @dev 暂停TAT
    function pause() public onlyOwner {
        _pause();
    }

    /// @dev 解除暂停TAT
    function unpause() public onlyOwner {
        _unpause();
    }


    /// @dev 质押TAT
    ///  - Event
    ///        event Stake(address from,uint256 amount);
    /// @param _amount 质押的TAT数量
    function stake(address account, uint256 _amount) public override {
        require(balanceOf(account) >= _amount, "stake more than you own");
        _stake(account, _amount);
        _burn(account, _amount);
    }

    /// @dev 取回质押的TAT
    /// - Event
    ///    event Withdraw(address from,uint256 amount);
    /// @param _amount 取回的质押TAT数量
    function withdraw(address account, uint256 _amount) public override {
        require(stakeOf(account) >= _amount, "withdraw more than you staked");
        _withdraw(account, _amount);
        _mint(account, _amount);
    }
}
