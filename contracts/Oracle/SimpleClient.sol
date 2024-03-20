// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./OracleClient.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../Governance/IRoles.sol";

contract SimpleClient is Initializable, OwnableUpgradeable, OracleClient {
    using Counters for Counters.Counter;

    event OracleRequest(
        address requester,
        bytes32 requesterid,
        address callbackAddress,
        bytes4 callbackFunctionId
    );

    event AssetValueSet(bytes32 requesterid, uint256 Date, uint256 Value);

    struct AssetValue {
        uint256 Date;
        uint256 Value;
        uint256 Timestamp;
    }

    bytes32 private _requestIdToPullAssetValue; // oralce request id

    mapping(uint256 => AssetValue) private _assetMappedValues;
    AssetValue[] private _assetValues;

    Counters.Counter private _counter;

    IRoles private _roleController;

    function initialize(address _oracleContract, address _rolesContract) public initializer {
        __Ownable_init();
        __oracleClientInitialize(_oracleContract);

        _roleController = IRoles(_rolesContract);
    }

    modifier onlyFeeder() {
        require(
            _roleController.hasRole(keccak256("FEEDER"), _msgSender()),
            "Only Feeder can push data"
        );
        _;
    }

    function oracle() public view returns (address) {
        return _oracleContract();
    }

    function requesterid() public virtual returns (bytes32) {
        return _requestIdToPullAssetValue;
    }

    function registerAssetValueRequest() public onlyOwner returns (bytes32) {
        uint256 nonce = _nextNonce();

        _requestIdToPullAssetValue = _sendOracleRequest(
            address(this),
            this.receiveAssetValue.selector,
            nonce
        );

        emit OracleRequest(
            address(this),
            _requestIdToPullAssetValue,
            address(this),
            this.receiveAssetValue.selector
        );

        return _requestIdToPullAssetValue;
    }

    function receiveAssetValue(
        bytes32 _requestId,
        uint256 _date,
        uint256 _value
    ) public onlyFeeder {
        require(_requestId == _requestIdToPullAssetValue, "invalid oracle request id");
        require(_value > 0, "zero asset value");
        _setResourceValue(_date, _value);

        emit AssetValueSet(_requestId, _date, _value);

        _counter.increment();
    }

    function _setResourceValue(uint256 _date, uint256 _value) internal {
        require(_assetMappedValues[_date].Timestamp == 0, "product value at this date already set");

        AssetValue memory value;
        value.Date = _date;
        value.Value = _value;
        value.Timestamp = block.timestamp;

        _assetMappedValues[_date] = value;
        _assetValues.push(value);
    }

    function getAssetValue(uint256 _date) public view returns (uint256) {
        return _assetMappedValues[_date].Value;
    }
}
