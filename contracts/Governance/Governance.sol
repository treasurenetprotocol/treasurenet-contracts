// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IRoles.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/// @title Treasurenet的治理合约
/// @author bjwswang
contract Governance is OwnableUpgradeable {
    
    bytes32 public constant FOUNDATION_MANAGER = keccak256("FOUNDATION_MANAGER");

    // bytes32 public constant TREAUSRE_OIL = keccak256("OIL");
    // bytes32 public constant TREASURE_GAS = keccak256("GAS");

    IRoles private _role;
    address private _parameterInfo;
    address private _mulSig;

    address private _dao;

    mapping(bytes32 => Treasure) private _treasures;

     /// @dev Treasure核心数据结构，代表某类似资产，如OIL/GAS/ETHER
    struct Treasure {
        bytes32 Kind;
        address ProducerContract;
        address ProductionDataContract;
    }

     /// @dev 用于Governance合约的初始化
     /// @param _daoContract DAO合约地址
     /// @param _mulSigContract 多签合约地址
     /// @param _roleContract 角色管理合约地址
     /// @param _parameterInfoContract 参数管理合约地址
    function initialize(
        address _daoContract,
        address _mulSigContract,
        address _roleContract,
        address _parameterInfoContract,
        string[] memory _treasureTypes,
        address[] memory _producers,
        address[] memory _productionDatas        
    ) public initializer {
        _role = IRoles(_roleContract);
        _parameterInfo = _parameterInfoContract;
        _mulSig = _mulSigContract;

        _dao = _daoContract;

        require(_treasureTypes.length == _producers.length,"treasure length mismatch");
        require(_treasureTypes.length == _productionDatas.length,"treasureTypes mismatch with productionDatas length");

        for (uint256 i = 0; i < _treasureTypes.length; ++i) {
            require(_addTreasure(_treasureTypes[i], _producers[i], _productionDatas[i]),"failed to initialize treasure");
        }   
    }

    modifier onlyDAO() {
        require(_msgSender() == _dao, "only DAO contract");
        _;
    }

    modifier onlyMulSig() {
        require(_msgSender() == _mulSig, "");
        _;
    }
    
     /// @dev 返回当前Governance多钱合约通过的阈值
     /// @return 阈值
    function fmThreshold() public view returns (uint256) {
        return _role.getRoleMemberCount(FOUNDATION_MANAGER) / 2 + 1;
    }

    event AddTreasure(string treasureType,address producerContract,address produceDataContract);
     /// @dev 用于添加新的Treasure资产(此方法仅允许从MulSig合约调用)
     ///   - Events:
     ///    - event AddTreasure(string treasureType,address producerContract,address produceDataContract);
     /// @param _treasureType 资产名称
     /// @param _producer 资产对应的生产商管理合约地址
     /// @param _productionData 资产对应的生产数据管理合约地址
    function addTreasure(
        string memory _treasureType,
        address _producer,
        address _productionData
    ) public onlyMulSig {
        require(_addTreasure(_treasureType, _producer, _productionData),"failed to add treasure");
    }

    function _addTreasure(string memory _treasureType,address _producer,address _productionData) internal returns(bool){
        bytes32 kind = keccak256(bytes(_treasureType));
        require(_treasures[kind].ProducerContract == address(0), "treasure type already exists");
        require(_producer != address(0),"empty producer contract");
        require(_productionData!= address(0),"empty production data contract");

        Treasure memory newTreasure;
        newTreasure.Kind = kind;
        newTreasure.ProducerContract = _producer;
        newTreasure.ProductionDataContract = _productionData;

        _treasures[newTreasure.Kind] = newTreasure;

        emit AddTreasure(_treasureType, _producer, _productionData);

        return true;
    }


    /// @dev 用于通过Treasure的资产类型查询资产对应的合约地址
    /// @param _treasureType 资产名称
    /// @return address 生产商管理合约地址
    /// @return address 生产数据管理合约地址
    function getTreasureByKind(string memory _treasureType) public view returns (address, address) {
        bytes32 kind = keccak256(bytes(_treasureType));
        require(_treasures[kind].ProducerContract != address(0), "treasure not found");

        return (_treasures[kind].ProducerContract, _treasures[kind].ProductionDataContract);
    }
}
