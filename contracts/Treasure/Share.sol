// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./interfaces/IShare.sol";

/**
 * @dev Share为收益划分合约
*/
contract Share is IShare {
    // MAX_HOLDER except owner
    uint256 public constant MAX_HOLDERS = 9;
    uint256 public constant MAX_PIECES = 100;

    // unique id => owner
    mapping(bytes32 => address) private _owners;

    // unique id => Shares
    mapping(bytes32 => mapping(address => Holder)) private _holders;
    mapping(bytes32 => address[]) private _holderAddresses;

    // unique id => total holders
    mapping(bytes32 => uint256) private _totalHolders;

    // unique id => total shared
    // producer owns (100 - _totalShared)
    mapping(bytes32 => uint256) private _totalShared;

    modifier onlyProducerOwner(bytes32 _uniqueId) virtual {
        require(_owners[_uniqueId] != address(0), "producer share not exist");
        require(_owners[_uniqueId] == msg.sender, "only the producer itself");
        _;
    }

    // set by internal management
    function _setOwner(bytes32 _uniqueId, address _owner) internal {
        require(_owners[_uniqueId] == address(0), "producer share alread exist");
        _owners[_uniqueId] = _owner;
    }

    /// @dev 是否为Producer的所有人
    /// @param _uniqueId 生产商(矿井)唯一ID
    /// @param _producer 账户地址
    /// @return bool 是否为所有人
    function isProducerOwner(bytes32 _uniqueId, address _producer)
        public
        view
        returns (bool)
    {
        return (_owners[_uniqueId] == _producer);
    }

    // Core functions in Share Contract


    /// @dev 最大受益人数量(包括Producer所有人)
    /// @return uint256 数量
    function maxShares() public pure override returns (uint256) {
        return MAX_HOLDERS+1;
    }


    /// @dev 当前受益人数量
    /// @param _uniqueId 生产商(矿井)唯一ID
    /// @return uint256 数量
    function totalHolders(bytes32 _uniqueId) public view override returns (uint256) {
        return _totalHolders[_uniqueId];
    }

     /// @dev 当前划分出去的份额
    /// @param _uniqueId 生产商(矿井)唯一ID
    /// @return uint256 数量   
    function totalShared(bytes32 _uniqueId) public view override returns (uint256) {
        return _totalShared[_uniqueId];
    }

     /// @dev 是否为生产商收益持有人
    /// @param _uniqueId 生产商(矿井)唯一ID
    /// @param _holder 持有人
    /// @return bool 是否为持有人
    function isHolder(bytes32 _uniqueId, address _holder)
        public
        view
        override
        returns (bool)
    {
        Holder memory h = _holders[_uniqueId][_holder];
        return (h.flag == Flag.Holder);
    }

     /// @dev 查询持有人信息
    /// @param _uniqueId 生产商(矿井)唯一ID
    /// @param _holder 持有人账户
    /// @return Holder 持有人信息
    function holder(bytes32 _uniqueId, address _holder)
        public
        view
        override
        returns (Holder memory)
    {
        return _holders[_uniqueId][_holder];
    }

    /// @dev 设置持有人
    /// @param _uniqueId 生产商(矿井)唯一ID
    /// @param _holderAddrs 持有人账户数组
    /// @param _ratios 持有比例(100)数组
    function setHolders(
        bytes32 _uniqueId,
        address[] memory _holderAddrs,
        uint256[] memory _ratios
    ) public override onlyProducerOwner(_uniqueId) {
        require(_holderAddrs.length == _ratios.length,"Holders and Ratios must have same length");
        for(uint i=0; i< _holderAddrs.length; i++){
            _setHolder(_uniqueId, _holderAddrs[i], _ratios[i]);
        }
    }

    function _setHolder(
        bytes32 _uniqueId,
        address _holder,
        uint256 _ratio
    ) internal {
        require(!isProducerOwner(_uniqueId, _holder), "share owner do not need to setHolder");

        require(_ratio <= MAX_PIECES, "ratio excceedes MAX_PIECES(100)");
        Holder memory h = holder(_uniqueId, _holder);

        uint256 _th = totalHolders(_uniqueId);
        uint256 _ts = totalShared(_uniqueId) + _ratio - h.ratio;

        // MAX_HOLDER
        if (h.flag == Flag.NotHolder) {
            _th += 1;
            require(_th <= MAX_HOLDERS, "exceedes MAX_HOLDERS(10)");
            // save holder address to `_holderAddresses`
            h.index =  _holderAddresses[_uniqueId].length;
            _holderAddresses[_uniqueId].push(_holder);
        }

        // MAX_PIECES
        require(_ts <= MAX_PIECES, "total ratio exceedes MAX_PIECES(100)");

        h.ratio = _ratio;
        h.flag = Flag.Holder;

        _holders[_uniqueId][_holder] = h;

        _totalHolders[_uniqueId] = _th;
        _totalShared[_uniqueId] = _ts;

        emit SetHolder(_uniqueId, _holder, _ratio, _th, _ts);
    }
 


    /// @dev 将持有份额转给其他人
    /// @param _uniqueId 生产商(矿井)唯一ID
    /// @param _toHolder 接收者
    /// @param _ratio 转移份额数量
    /// @return uint256 发送者最新份额
    /// @return uint256 接受者最新份额
    function splitHolder(bytes32 _uniqueId,address _toHolder,uint256 _ratio) public override returns(uint256,uint256)  {
        require(_toHolder != address(0),"receiver must not be zero address");
        require(_ratio <= MAX_PIECES,"ratio exceedes MAX_PIECE(100)");
     
        Holder memory sender = holder(_uniqueId,msg.sender);
        require(sender.flag == Flag.Holder,"not a share holder");
        require(sender.ratio >= _ratio,"sender's ratio not enough");

        sender.ratio = sender.ratio - _ratio;

        Holder memory receiver = holder(_uniqueId,_toHolder);

        receiver.ratio = receiver.ratio + _ratio;

        // Update total holders
        if (receiver.flag == Flag.NotHolder){
            uint256 _th = totalHolders(_uniqueId);
            _th += 1;
            require(_th <= MAX_HOLDERS, "exceedes MAX_HOLDERS(10)");

            receiver.flag = Flag.Holder;
            _totalHolders[_uniqueId] = _th;

            // save new receiver to `_holderAddresses`
            receiver.index =  _holderAddresses[_uniqueId].length;
            _holderAddresses[_uniqueId].push(_toHolder);
        }

        _holders[_uniqueId][msg.sender] = sender;
        _holders[_uniqueId][_toHolder] = receiver;

        emit SplitHolder(_uniqueId, msg.sender, _toHolder, _ratio);

        return (sender.ratio,receiver.ratio);
    }

    /// @dev 删除持有人
    /// @param _uniqueId 生产商(矿井)唯一ID
    /// @param _holder 持有人地址
    function deleteHolder(bytes32 _uniqueId, address _holder)
        public
        override
        onlyProducerOwner(_uniqueId)
    {
        Holder memory h = holder(_uniqueId, _holder);
        require(h.flag == Flag.Holder, "must be a holder");
        require(h.ratio == 0, "must have zero share");

        emit DeleteHolder(_uniqueId, _holder);

        uint256 index = h.index;
        address[] storage hs = _holderAddresses[_uniqueId];
        if(hs.length >1) {
            hs[index] = hs[hs.length-1];
        }
        hs.pop();

        delete (_holders[_uniqueId][_holder]);

        _totalHolders[_uniqueId] -= 1;
    }

    /// @dev 计算各持有人的收益
    /// @param _uniqueId 生产商(矿井)唯一ID
    /// @param total 总收益
    function calculateRewards(bytes32 _uniqueId,uint256 total) public view override returns(address[] memory,uint256[] memory) {
        address[] memory accounts = new address[](_totalHolders[_uniqueId]+1);
        uint256[] memory amounts = new uint256[](_totalHolders[_uniqueId]+1);
        uint256 shared;

        for(uint256 i=0;i<_totalHolders[_uniqueId];i++) {
            address account =  _holderAddresses[_uniqueId][i];
            Holder memory h = holder(_uniqueId,account);
            accounts[i] = account;
            uint256 share =  h.ratio*total/100;
            amounts[i] = share;
            shared = shared + share;
        }
        // set owner
        accounts[_totalHolders[_uniqueId]] = _owners[_uniqueId];
        amounts[_totalHolders[_uniqueId]] = total - shared;

        return (accounts,amounts);
    }
}
