// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "../TAT/ITAT.sol";
import "../Governance/IRoles.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Bid is Initializable, OwnableUpgradeable {
    bytes32 public constant FOUNDATION_MANAGER = keccak256("FOUNDATION_MANAGER");

    event bidResult(address _bider, string _type, string _result, uint _status, uint _amount);//_status, 1:return 2:expend
    event bidList(address account, uint256 amount);
    event bidBurn(address account, uint amount);

    struct TATList{
        address bider;
        uint256 amount;
    }

    address[] public TATBiders;
    mapping(address => bool) isTATBid;
    mapping(address => uint) bidAmount;

    uint private bidMode; //1:normol 2:auditor
    uint constant TATThreshold = 10**18;

    address private governance;
    IRoles private _role;
    ITAT private _tat;


    function initialize(address _roleAddress, address _tatAddress) public initializer {
        __Ownable_init();

        bidMode = 1;
        _role = IRoles(_roleAddress);
        _tat = ITAT(_tatAddress);
    }

    modifier onlyFoundationManager() {
        require(_role.hasRole(FOUNDATION_MANAGER, _msgSender()), "Only FoundationManager can use this function");
        _;
    }

    receive () external payable{}

    function isTATBider(address pAddr)public view returns(bool result){
        return isTATBid[pAddr];
    }
    
    //bid TAT to a active validator
    function bidTAT(uint amount) public returns(bool result){
        require(bidMode == 1, "auditor is operation");
        require(amount >= TATThreshold, "TAT not enough to bid");
        
        _tat.stake(amount);
        
        if(!isTATBider(msg.sender)){
            isTATBid[msg.sender]=true;
            TATBiders.push(msg.sender);
        }
        bidAmount[msg.sender] += amount;

        emit bidBurn(msg.sender, amount);

        return true;
    }

    function getList()public onlyFoundationManager returns(TATList[] memory){
        bidMode = 2;
        TATList[] memory list = new TATList[](TATBiders.length);
        for(uint a=0; a<TATBiders.length; a++){
            list[a].bider = TATBiders[a];
            list[a].amount = bidAmount[TATBiders[a]];
        }
        return list;
    }
    //reset algorithm
    function reset()public onlyFoundationManager returns(bool){
        bidMode = 1;
        for(uint a=0; a<TATBiders.length; a++){
            delete isTATBid[TATBiders[a]];
            delete bidAmount[TATBiders[a]];
        }

        delete TATBiders;

        return true;
    }
}
