// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/IProductionData.sol";
import "../Governance/IRoles.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/Timers.sol";
import "./interfaces/IProducer.sol";
import "./Share.sol";

/**
 * @dev Producer为核心的生产商管理合约，实现了
 *    - 生产商管理: 增加/修改生产商
 *    - 生产商收益划分: Share
 *    - 与Otter Stream挂钩
*/
abstract contract Producer is Initializable, IProducer, Share {
    using SafeCast for uint256;

    bytes32 public constant FOUNDATION_MANAGER = keccak256("FOUNDATION_MANAGER");

    address private _mulSig;
    IRoles private _roles;

    string private _asset_type;
    mapping(bytes32 => ProducerCore) private _producers;
    mapping(bytes32 => ProducerStatus) private _producerStatus;

    // _producerTotalOccupied 记录此生产商(井)被通过DApp的Stream占用的比例 < 100
    mapping(bytes32 => uint256) private _producerTotalOccupied;

    mapping(bytes32 => address) private _dapps;

    IProductionData private _productionData;

    /// @dev 合约初始化
    /// @param _roleContract 角色管理合约
    /// @param _assetType 资产名称
    /// @param _productionDataContract 生产数据管理合约
    function __ProducerInitialize(
        address _mulSigContract,
        address _roleContract,
        string memory _assetType,
        address _productionDataContract,
        string[] memory _dappNames,
        address[] memory _payees
    ) internal onlyInitializing {
        require(_mulSigContract != address(0), "empty MulSig contract");
        require(_roleContract != address(0), "empty Role contract");
        require(keccak256(bytes(_assetType)) != keccak256(bytes("")), "empty treasure type");
        require(_productionDataContract != address(0), "empty ProductionData contract");

        _asset_type = _assetType;
        _roles = IRoles(_roleContract);
        _productionData = IProductionData(_productionDataContract);


        require(_dappNames.length == _payees.length, "dapps array must equal to payees array");
        for (uint256 i = 0; i < _dappNames.length; i++) {
            require(keccak256(bytes(_dappNames[i])) != keccak256(bytes("")), "has empty dapp name");
            require(_payees[i] != address(0), "has empty dapp payee");
            bytes32 dappId = keccak256(abi.encodePacked(_dappNames[i], _payees[i]));
            _dapps[dappId] = _payees[i];
            /* add an event here. */
            emit RegisterDAppConnect(_dappNames[i], _payees[i], dappId);
        }
    }

    modifier onlyFoundationManager() {
        require(_roles.hasRole(FOUNDATION_MANAGER, msg.sender), "must have role FOUNDATION_MANAGER ");
        _;
    }


    modifier onlyMulSig() {
        require(msg.sender == _mulSig, "");
        _;
    }

    /// @dev 添加生产商(only FOUNDATION_MANAGER)
    /// - Event
    ///     event AddProducer(bytes32 uniqueId,ProducerCore producer);
    /// @param _uniqueId 生产商唯一ID
    /// @param _producer 生产商信息
    function addProducer(bytes32 _uniqueId, ProducerCore memory _producer)
    public
    override
    {
        _beforeAddProducer(_uniqueId, _producer);
        _addProducer(_uniqueId, _producer);
        _afterAddProducer(_uniqueId);
        emit AddProducer(_uniqueId, _producer);
    }

    // TODO: implement below functions

    function _beforeAddProducer(bytes32 _uniqueId, ProducerCore memory _producer)
    internal
    virtual
    {
        ProducerCore memory producer = _producers[_uniqueId];
        require(producer.owner == address(0), "producer already exist");
    }

    function _addProducer(bytes32 _uniqueId, ProducerCore memory _producer) internal virtual {
        _producers[_uniqueId] = _producer;
    }

    function _afterAddProducer(bytes32 _uniqueId) internal virtual {
        _producerStatus[_uniqueId] = ProducerStatus.NotSet;
    }

    /// @dev 更新生产商状态(only FOUNDATION_MANAGER)
    /// - Event
    ///      event SetProducerStatus(bytes32 uniqueId,ProducerStatus status);
    /// @param _uniqueId 生产商唯一ID
    /// @param _newStatus 新状态
    // enum ProducerStatus {
    //     NotSet,
    //     Active,
    //     Deactive
    // }
    function setProducerStatus(bytes32 _uniqueId, ProducerStatus _newStatus)
    public
    override
    onlyFoundationManager
    {
        require(producerStatus(_uniqueId) != _newStatus, "status not changed");
        require(_newStatus!=ProducerStatus.NotSet,"invalid status");

        if (_newStatus == ProducerStatus.Active && _productionData.getTDRequestID(_uniqueId) == bytes32("")) {
            _productionData.registerTrustedDataRequest(_uniqueId);
        }

        if (_newStatus == ProducerStatus.Deactive && _productionData.getTDRequestID(_uniqueId) != bytes32("")) {
            _productionData.cancelTrustedDataRequest(_uniqueId);
        }

        _producerStatus[_uniqueId] = _newStatus;

        emit SetProducerStatus(_uniqueId, _newStatus);
    }

    event UpdateProducer(bytes32 uniqueId, ProducerCore _old, ProducerCore _new);
    /// @dev 更新生产商信息 (only FOUNDATION_MANAGER)
    /// - Event
    ///       event UpdateProducer(bytes32 uniqueId,ProducerCore _old ,ProducerCore _new);
    /// @param _uniqueId 生产商唯一ID
    /// @param _producer 生产商信息
    /// struct ProducerCore {
    ///     string nickname;
    ///     address owner;
    ///     uint256 API;
    ///     uint256 sulphur;
    /// }
    function updateProdcuer(bytes32 _uniqueId, ProducerCore memory _producer) public override {
        (,ProducerCore memory curr) = getProducer(_uniqueId);
        require(curr.owner == _producer.owner, "owner change not allowd");
        require(curr.owner == msg.sender, "only owner can update");
        _updateProducer(_uniqueId, _producer);

        _producerStatus[_uniqueId] = ProducerStatus.NotSet;

        emit UpdateProducer(_uniqueId, curr, _producer);
    }

    function _updateProducer(bytes32 _uniqueId, ProducerCore memory _producer) internal {
        _producers[_uniqueId] = _producer;
    }

    /// @dev 获取生产商状态
    /// @param _uniqueId 生产商唯一ID
    /// @return ProducerStatus 生产商状态
    function producerStatus(bytes32 _uniqueId) public view override returns (ProducerStatus) {
        return _producerStatus[_uniqueId];
    }

    /// @dev 获取生产商信息和状态
    /// @param _uniqueId 生产商唯一ID
    /// @return ProducerStatus 生产商状态
    /// @return ProducerCore
    function getProducer(bytes32 _uniqueId)
    public
    view
    override
    returns (ProducerStatus, ProducerCore memory)
    {
        if (producerStatus(_uniqueId) == ProducerStatus.NotSet) {
            ProducerCore memory emptyProducer;
            return (ProducerStatus.NotSet, emptyProducer);
        }
        return (producerStatus(_uniqueId), _producers[_uniqueId]);
    }

    event RegisterDAppConnect(string dap, address payee, bytes32 dappId);
    /// @dev 注册DApp
    /// @param dapp DApp的名称
    /// @param payee DApp的收款地址
    /// @return bytes32 DApp的id
    function registerDAppConnect(string memory dapp, address payee) external override onlyMulSig returns (bytes32) {
        require(keccak256(bytes(dapp)) != keccak256(bytes("")), "empty dapp name");
        require(payee != address(0), "empty DApp payee");
        bytes32 dappId = keccak256(abi.encodePacked(dapp, payee));
        require(_dapps[dappId] == address(0), "dapp already registered");
        _dapps[dappId] = payee;
        emit RegisterDAppConnect(dapp, payee, dappId);
        return dappId;
    }

    function getDAppPayee(bytes32 _dappId) public override view returns (address) {
        address payee = _dapps[_dappId];
        require(payee != address(0), "dapp with this dappId not registered yet");
        return payee;
    }

    /// @dev 链接Otter Stream
    /// @param _uniqueIds 生产商唯一ID数组
    /// @param _key 验证码
    /// @param _dappId DApp的ID
    function link(bytes32[] memory _uniqueIds, bytes32 _key, bytes32 _dappId) public override {
        require(_uniqueIds.length > 0, "at least 1 uniqueId is required");
        require(_dapps[_dappId] != address(0), "dapp with this id not found");

        uint256[] memory ratios = new uint256[](_uniqueIds.length);
        string[] memory nicknames = new string[](_uniqueIds.length);

        for (uint256 i = 0; i < _uniqueIds.length; i++) {
            (ProducerStatus status,ProducerCore memory p) = getProducer(_uniqueIds[i]);
            require(status == ProducerStatus.Active, "producer not active");
            //require(isHolder(_uniqueIds[i], msg.sender) || msg.sender == p.owner, "only producer holder or producer owner can link stream");
            require(isHolder(_uniqueIds[i], _dapps[_dappId]), "dapp's payee must be producer's holder");
            Holder memory hold = holder(_uniqueIds[i], _dapps[_dappId]);

            /*uint256 occupied = _producerTotalOccupied[_uniqueIds[i]];
            require(occupied + hold.ratio <= MAX_PIECES, "occupied ratio of a producer cannot exceedes MAX_PIECES(100)");
            _producerTotalOccupied[_uniqueIds[i]] = occupied + hold.ratio;
            ratios[i] = _producerTotalOccupied[_uniqueIds[i]];*/
            ratios[i] = hold.ratio;
            nicknames[i] = p.nickname;
        }

        emit Link(_key, _uniqueIds, ratios, nicknames, _dappId);
    }
}
