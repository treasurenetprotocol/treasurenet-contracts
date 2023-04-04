// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IOracle.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract OracleClient is Initializable {
    event Request(
        bytes32 requestid,
        address callbackAddress,
        bytes4 callbackFunctionId,
        uint256 nonce
    );

    using SafeMath for uint256;

    IOracle private _oracle;

    // requestID => oracle contract
    mapping(bytes32 => address) private _oracleRequests;
    uint256 private _nonce;

    function __oracleClientInitialize(address _oracleContractAddress) internal onlyInitializing {
        _oracle = IOracle(_oracleContractAddress);
    }

    function _oracleContract() internal view returns (address) {
        return address(_oracle);
    }

    function _currNonce() internal view returns (uint256) {
        return _nonce;
    }

    function _nextNonce() internal returns (uint256) {
        _nonce = _nonce.add(1);
        return _nonce;
    }

    function _sendOracleRequest(
        address _callbackAddress,
        bytes4 _callbackFunctionId,
        uint256 _request_nonce
    ) internal returns (bytes32) {
        bytes32 expectedRequestId = keccak256(abi.encodePacked(address(this), _request_nonce));

        require(
            expectedRequestId ==
                _oracle.createOracleRequest(_callbackAddress, _callbackFunctionId, _request_nonce),
            "requestid mismatch,check oracle logic"
        );

        return expectedRequestId;
    }

    function _cancelOracleRequest(
        bytes32 _requestId,
        address _callbackAddress,
        bytes4 _callbackFunctionId
    ) internal {
        _oracle.cancelOracleRequest(_requestId, _callbackAddress, _callbackFunctionId);
    }
}
