// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "../../Governance/IParameterInfo.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract Expense is Initializable{
    enum Action {
        NotSet,
        Deposite,
        Withdraw,
        Penalty
    }
    enum Status {
        NotSet,
        Normal,
        Abnormal
    }
    struct Depositor {
        uint256 margin;
        address debtor;
        Status status;
    }

    event ExpenseHistory(
        uint256 time,
        address operator,
        Action _type,
        string content,
        uint256 tokens
    );

    receive() external payable {}

    mapping(address => Depositor) private _depositors;

    IParameterInfo private _parameterInfo;

    function __ExpenseInitialize(address _parameterInfoContract) internal onlyInitializing {
        _parameterInfo = IParameterInfo(_parameterInfoContract);
    }

    function _isDepositor(address _account) internal view returns (bool) {
        return _depositors[_account].status != Status(0);
    }

    modifier onlyDepositorNormal(address _account) {
        require(_depositors[_account].status == Status.Normal,"must be depositor and must be Normal");
        _;
    }

    function prepay() public payable returns (bool) {
        require(msg.value > 0, "payment must bigger than zero");

        Depositor storage depositor = _depositors[msg.sender];

        if (depositor.status == Status.NotSet) {
            depositor.margin = msg.value;
            depositor.status = Status.Normal;
            _depositors[msg.sender] = depositor;
        }else if (depositor.status == Status.Normal) {
            depositor.margin += msg.value;
            _depositors[msg.sender] = depositor;
        }else if (depositor.status == Status.Abnormal) {
            uint256 debt = depositor.margin;
            if (debt <= msg.value) {
                depositor.margin = msg.value - debt;
                depositor.status = Status.Normal;
                depositor.debtor = address(0);
                payable(depositor.debtor).transfer(debt);
            } else {
                depositor.margin -= msg.value;
                payable(depositor.debtor).transfer(msg.value);
            }
            _depositors[msg.sender] = depositor;
        }

        emit ExpenseHistory(block.timestamp, msg.sender, Action.Deposite, "deposite", msg.value);

        return true;
    }

    function withdraw(uint256 amount) public payable onlyDepositorNormal(msg.sender) returns (bool) {
        Depositor storage depositor = _depositors[msg.sender];
        require(depositor.margin >= amount, "margin is not enough");

        _depositors[msg.sender].margin -= amount;
        payable(msg.sender).transfer(amount);

        emit ExpenseHistory(block.timestamp, msg.sender, Action.Withdraw, "withdraw", amount);

        return true;
    }

    // customize
    function _penalty(
        address account,
        uint256 value,
        uint256 percent
    ) internal onlyDepositorNormal(account) returns (uint256) {
        Depositor storage depositor = _depositors[account];

        /* 为了精度percent100% 为10000  这里多除两个0*/
        uint256 penaltyCost = (value * percent * _parameterInfo.getPlatformConfig("marginRatio")) /
            100000000;

        if (depositor.margin >= penaltyCost) {
            depositor.margin -= penaltyCost;
            payable(address(this)).transfer(penaltyCost);  //TODO: 转给自己？
        } else {
            payable(address(this)).transfer(depositor.margin);  //TODO: 转给自己？
            depositor.margin = penaltyCost - depositor.margin;
            depositor.status = Status.Abnormal;
            depositor.debtor = address(this);
        }

        _depositors[msg.sender] = depositor;

        emit ExpenseHistory(block.timestamp, account, Action.Penalty, "penalty", penaltyCost);

        return penaltyCost;
    }

    function marginOf(address _account) public view returns (uint256, Status) {
        Depositor storage depositor = _depositors[_account];
        return (depositor.margin, depositor.status);
    }
}
