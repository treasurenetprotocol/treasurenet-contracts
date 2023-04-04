// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import "./DAO/IDAO.sol";
import "./IGovernance.sol";
import "./IParameterInfo.sol";
import "./IRoles.sol";
import "../Treasure/interfaces/IProducer.sol";

/// @title 多签合约
/// @author bjwswang
contract MulSig is Initializable, OwnableUpgradeable {
    bytes32 public constant FOUNDATION_MANAGER = keccak256("FOUNDATION_MANAGER");
    bytes32 public constant FEEDER = keccak256("FEEDER");

    mapping(uint256 => proposal) private proposals;
    uint256[] private pendingProposals;
    uint256 private proposalIDx;
    uint256 private confirmDuration;

    IDAO private _dao;
    IGovernance private _governance;
    IParameterInfo private _parameterInfo;
    IRoles private _roles;

    // 提议：
    // - 管理manager
    // - 管理用户组
    // - 管理platform config
    // - 管理discount config
    // - 管理矿物类型
    struct proposal {
        address proposer;
        string name;
        address _add;
        uint256 value;
        IParameterInfo.PriceDiscountConfig data;
        uint256 _type; // 1: adminPermission 2: addResource  3: dataConfig 4: discountConfig 5: registerDApp
        uint8 signatureCount;
        uint256 excuteTime;
        address producer;
        address productionData;
        mapping(address => uint8) signatures;

        string treasureKind;
        address payee;
    }

     /// @dev 用于MulSig合约的初始化
     /// @param _daoContract DAO合约地址
     /// @param _governanceContract 治理合约地址
     /// @param _roleContract 角色管理合约地址
     /// @param _parameterInfoContract 参数管理合约地址
    function initialize(
        address _daoContract,
        address _governanceContract,
        address _roleContract,
        address _parameterInfoContract,
        uint256 _confirmation
    ) public initializer {
        __Ownable_init();

        confirmDuration = _confirmation * 1 minutes;

        _dao = IDAO(_daoContract);
        _governance = IGovernance(_governanceContract);
        _parameterInfo = IParameterInfo(_parameterInfoContract);
        _roles = IRoles(_roleContract);
    }

    modifier onlyDAO() {
        require(_msgSender() == address(_dao), "only DAO");
        _;
    }

    modifier onlyFoundationManager() {
        require(_roles.hasRole(FOUNDATION_MANAGER , _msgSender()), "only foundation manager");
        _;
    }


    event ManagePermission(uint256 proposalId,address proposer, string name, address _add);
     /// @dev 发起新的提议，为某用户添加/注销角色权限
     ///  - 仅允许FoundationManager发起
     ///  - Event:
     ///  -   `event ManagePermission(address proposer, string name, address _add, uint256 proposalId);`
     /// @param _name: 操作类型,包括:
     ///   - FMD: 注销FoundationManager权限
     ///   - FMA: 添加FoundationManager权限
     ///   - FEEDERD: 添加FEEDER权限
     ///   - FEEDERA：注销FEEDER权限
     /// @param _account 账户地址
     /// @return bool 是否成功发起proposal
    function proposeToManagePermission(string memory _name, address _account) public onlyFoundationManager returns (bool) {
        require(address(0) != _account, "MulSig:zero address");
        uint256 proposalID = proposalIDx++;
        proposal storage kk = proposals[proposalID];
        kk.proposer = msg.sender;
        kk.name = _name;
        kk._add = _account;
        kk._type = 1;
        kk.signatureCount = 0;
        pendingProposals.push(proposalID);

        emit ManagePermission(proposalID,msg.sender, _name, _account);

        return true;
    }

    event AddResource(uint256 proposalId,address proposer, string name, address producerContract,address productionContract);
     /// @dev 用于添加新的Treasure资产
     ///  - Event:
     ///     - event AddResource(address proposer, string name, address producerContract,address productionContract);
     /// @param _name  资产名称
     /// @param _producer 生产商管理合约
     /// @param _productionData 生产数据管理合约
     /// @return bool 是否成功发起proposal
    function proposeToAddResource(
        string memory _name,
        address _producer,
        address _productionData
    ) public onlyFoundationManager returns (bool) {
        uint256 proposalID = proposalIDx++;
        proposal storage kk = proposals[proposalID];
        kk.proposer = msg.sender;
        kk.name = _name;
        kk._type = 2;
        kk.signatureCount = 0;
        kk.producer = _producer;
        kk.productionData = _productionData;

        pendingProposals.push(proposalID);

        emit AddResource(proposalID,msg.sender, _name, _producer, _productionData);

        return true;
    }

   event RegisterDApp(uint256 proposalId,address proposer,string treasure, string dapp,address payee);
   function proposeToRegisterDApp(
        string memory _treasure,
        string memory _dapp,
        address _payee
    ) public onlyFoundationManager returns (bool) {
        require(keccak256(bytes(_treasure)) != keccak256(bytes("")),"empty treasure name");
        require(keccak256(bytes(_dapp)) != keccak256(bytes("")),"empty dapp name");
        require(_payee != address(0),"empty DApp payee");

        (address producerContract,) = _governance.getTreasureByKind(_treasure);
        require(producerContract != address(0),"treasure with this kind not found");

        uint256 proposalID = proposalIDx++;
        proposal storage kk = proposals[proposalID];
        kk.proposer = msg.sender;

        kk.name = _dapp;
        kk.treasureKind = _treasure;
        kk.payee = _payee;
        kk._type = 5;

        kk.signatureCount = 0;

        pendingProposals.push(proposalID);

        emit RegisterDApp(proposalID, kk.proposer,_treasure, _dapp, _payee);

        return true;
    }


    event SetPlatformConfig(uint256 proposalId,address proposer, string name, uint256 _value);
    /// @dev 用于发起修改平台配置信息(parameterInfo)
    ///  - Event
    ///     -  event SetPlatformConfig(address proposer, string name, uint256 _value);
     /// @param _name  配置信息key
     /// @param _value 配置信息值
     /// @return bool 是否成功发起proposal
    function proposeToSetPlatformConfig(string memory _name, uint256 _value) public onlyFoundationManager returns (bool) {
        uint256 proposalID = proposalIDx++;
        proposal storage kk = proposals[proposalID];
        kk.proposer = msg.sender;
        kk.name = _name;
        kk.value = _value;
        kk._type = 3;
        kk.signatureCount = 0;
        pendingProposals.push(proposalID);

        emit SetPlatformConfig(proposalID,msg.sender, _name, _value);

        return true;
    }

    event SetDiscountConfig(uint256 proposalId,address proposer,IParameterInfo.PriceDiscountConfig config);
    /// @dev 用于发起修改资产的折扣信息(parameterInfo.DiscountConfig)
    ///  - Event
    ///     - event SetDiscountConfig(address proposer,IParameterInfo.PriceDiscountConfig config);
    ///       struct PriceDiscountConfig {
    ///         uint256 API;
    ///         uint256 sulphur;
    ///         uint256[4] discount;
    ///       }
    /// @param b1  API数据
    /// @param b2  sulphur酸度数据
    /// @param b3  discount[0]
    /// @param b4  discount[1]
    /// @param b5  discount[2]
    /// @param b6  discount[3]
    /// @return bool 是否成功发起proposal
    function proposeToSetDiscountConfig(
        uint256 b1,
        uint256 b2,
        uint256 b3,
        uint256 b4,
        uint256 b5,
        uint256 b6
    ) public onlyFoundationManager returns (bool) {
        uint256 proposalID = proposalIDx++;
        proposal storage kk = proposals[proposalID];
        kk.proposer = msg.sender;
        kk.data.API = b1;
        kk.data.sulphur = b2;
        kk.data.discount[0] = b3;
        kk.data.discount[1] = b4;
        kk.data.discount[2] = b5;
        kk.data.discount[3] = b6;
        kk._type = 4;
        kk.signatureCount = 0;
        pendingProposals.push(proposalID);

        emit SetDiscountConfig(proposalID,msg.sender,kk.data);

        return true;
    }

    /// @dev 用于获取pending状态的proposal列表
    /// @return uint256[] proposal id列表
    function getPendingProposals() public view onlyFoundationManager returns (uint256[] memory) {
        return pendingProposals;
    }

    event ProposalSigned(uint256 proposalId,address signer);
    /// @dev 由FoundationManager签发交易，同意某proposal
    /// @param _proposalId 提议对应的ID
    /// @return bool 请求是否成功
    function signTransaction(uint256 _proposalId) public onlyFoundationManager returns (bool) {
        proposal storage pro = proposals[_proposalId];
        // 未满足 多签阈值要求
        require(pro.signatureCount < _governance.fmThreshold(), "limit");
        // 当前signature发送者未发送过
        require(pro.signatures[msg.sender] != 1,"already signed");
        // 设置为已签名
        pro.signatures[msg.sender] = 1;
        pro.signatureCount++;

        // 满足阈值，设置执行时间(生效时间)
        if (pro.signatureCount >= _governance.fmThreshold()) {
            // 区块创建时间的两小时后
            pro.excuteTime = block.timestamp + confirmDuration;
        }
        emit ProposalSigned(_proposalId, msg.sender);

        return true;
    }

    event ProposalExecuted(uint256 proposalId);
    /// @dev 由FoundationManager执行某个proposal(已经完成投票的Id）
    /// @param _proposalId 提议对应的ID
    /// @return bool 请求是否成功
    function excuteProposal(uint256 _proposalId) public onlyFoundationManager returns (bool) {
        proposal storage pro = proposals[_proposalId];
        require(pro.excuteTime <= block.timestamp, "executeTime not meet");

        if (pro._type == 1) {
            if (keccak256(bytes(pro.name)) == keccak256(bytes("FMD"))) {
                _roles.revokeRole(FOUNDATION_MANAGER, pro._add);
            } else if (keccak256(bytes(pro.name)) == keccak256(bytes("FMA"))) {
                _roles.grantRole(FOUNDATION_MANAGER, pro._add);
            }
            if (keccak256(bytes(pro.name)) == keccak256(bytes("FEEDERD"))) {
                _roles.revokeRole(FEEDER, pro._add);
            } else if (keccak256(bytes(pro.name)) == keccak256(bytes("FEEDERA"))) {
                _roles.grantRole(FEEDER, pro._add);
            }
        } else if (pro._type == 2) {
            // treasure management
            _governance.addTreasure(pro.name, pro.producer, pro.productionData);
        } else if (pro._type == 3) {
            _parameterInfo.setPlatformConfig(pro.name, pro.value);
        } else if (pro._type == 4) {
            _parameterInfo.setPriceDiscountConfig(
                pro.data.API,
                pro.data.sulphur,
                pro.data.discount[0],
                pro.data.discount[1],
                pro.data.discount[2],
                pro.data.discount[3]
            );
        }else if (pro._type == 5) {
            (address producerAddr,) = _governance.getTreasureByKind(pro.treasureKind);
            require(producerAddr!= address(0),"treasure not found with proposal's treasure kind");
            IProducer _producer = IProducer(producerAddr);
            _producer.registerDAppConnect(pro.name,pro.payee);
        }
        deleteProposals(_proposalId);

        emit ProposalExecuted(_proposalId);

        return true;
    }

    /// @dev 查询proposal的详细信息
    /// @param _proposalId 提议对应的ID
    /// @return string 名称
    /// @return address 账户地址(如果为修改账户权限)
    /// @return uint256 a1 数值 (平台配置信息或者折扣信息)
    /// @return uint256 a2 数值 (折扣信息)
    /// @return uint256 a3 数值 (折扣信息)
    /// @return uint256 a4 数值 (折扣信息)
    /// @return uint256 a5 数值 (折扣信息)
    /// @return uint256 a6 数值 (折扣信息)
    /// @return uint256 executeTime 执行时间 (折扣信息)
    function transactionDetails(uint256 _proposalId)
        public
        view
        returns (
            string memory,
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        proposal storage pro = proposals[_proposalId];
        if (pro._type == 1) {
            return (pro.name, pro._add, 0, 0, 0, 0, 0, 0, pro.excuteTime);
        } else if (pro._type == 2) {
            return (pro.name, address(0), 0, 0, 0, 0, 0, 0, pro.excuteTime);
        } else if (pro._type == 3) {
            return (pro.name, address(0), pro.value, 0, 0, 0, 0, 0, pro.excuteTime);
        } else if (pro._type == 4) {
            return (
                "0",
                address(0),
                pro.data.API,
                pro.data.sulphur,
                pro.data.discount[0],
                pro.data.discount[1],
                pro.data.discount[2],
                pro.data.discount[3],
                pro.excuteTime
            );
        }
    }

    /// @dev 删除proposal
    /// @param _proposalId 提议对应的ID
    function deleteProposals(uint256 _proposalId) public onlyFoundationManager {
        uint8 replace = 0;
        for (uint256 i = 0; i < pendingProposals.length; i++) {
            if (1 == replace) {
                pendingProposals[i - 1] = pendingProposals[i];
            } else if (_proposalId == pendingProposals[i]) {
                replace = 1;
            }
        }
        if (1 == replace) {
            delete pendingProposals[pendingProposals.length - 1];
            pendingProposals.pop();
            delete proposals[_proposalId];
        }
    }
}
