// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../Governance/IRoles.sol";
import "./IOracle.sol";

/**
 * @dev Oracle为核心的预言机合约，实现了
 *    - 发起/取消Oracle请求
 *    - 上传Oracle数据(Role.Feeder)
*/
contract Oracle is Initializable, OwnableUpgradeable, IOracle {
    bytes32 public constant FEEDER = keccak256("FEEDER");

    event OracleRequest(
        address requester,
        bytes32 requesterid,
        address callbackAddress,
        bytes4 callbackFunctionId
    );

    event CancelOracleRequest(address requester, bytes32 requestid);

    IRoles private _roleController;

    mapping(bytes32 => uint256) private _currencyValues;

    // requestid -> commitment id
    mapping(bytes32 => bytes32) private _commitments;

    /// @dev 合约初始化
    /// @param _roleContract 角色管理合约
    function initialize(address _roleContract) public initializer {
        __Ownable_init();
        _roleController = IRoles(_roleContract);
    }

    modifier onlyFeeder() {
        require(_roleController.hasRole(FEEDER, _msgSender()), "Only Feeder can push data");
        _;
    }

    /// @dev 发起预言机请求
    ///  - Event
    ///  ``` 
    ///  event OracleRequest(
    ///     address requester,
    ///     bytes32 requesterid,
    ///     address callbackAddress,
    ///     bytes4 callbackFunctionId
    // ); 
    /// ```
    /// @param _callbackAddress 回调合约地址
    /// @param _callbackFunctionId 回调合约方法
    /// @param _nonce nonce值
    /// @return bytes32 请求的request id
    function createOracleRequest(
        address _callbackAddress,
        bytes4 _callbackFunctionId,
        uint256 _nonce
    ) public override returns (bytes32) {
        bytes32 requestId = keccak256(abi.encodePacked(msg.sender, _nonce));
        require(_commitments[requestId] == 0, "must be a unique request id");
        _commitments[requestId] = keccak256(
            abi.encodePacked(_callbackAddress, _callbackFunctionId)
        );

        emit OracleRequest(msg.sender, requestId, _callbackAddress, _callbackFunctionId);

        return requestId;
    }

    /// @dev 取消预言机请求
    ///  - Event
    ///  ``` 
    ///  event CancelOracleRequest(
    ///     address requester,
    ///     bytes32 requesterid,
    ///     address callbackAddress,
    ///     bytes4 callbackFunctionId
    // ); 
    /// ```
    /// @param _requestId 请求 id
    /// @param _callbackAddress 回调合约地址
    /// @param _callbackFuncId 回调合约方法
    /// @return bytes32 请求的request id
    function cancelOracleRequest(
        bytes32 _requestId,
        address _callbackAddress,
        bytes4 _callbackFuncId
    ) public override returns (bytes32) {
        bytes32 paramsHash = keccak256(abi.encodePacked(_callbackAddress, _callbackFuncId));
        require(paramsHash == _commitments[_requestId], "Params do not match request ID");
        // delete _commitments[_requestId];

        emit CancelOracleRequest(msg.sender, _requestId);

        return _requestId;
    }

    // UNIT Value 
    function setCurrencyValue(bytes32 _currencyKind,uint256 _currencyValue) public override onlyFeeder {
        _currencyValues[_currencyKind] = _currencyValue;
    }

    function getCurrencyValue(bytes32 _currencyKind) public view override returns(uint256) {
        return _currencyValues[_currencyKind];
    }
}
