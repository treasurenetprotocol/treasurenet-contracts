// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IOracle {
    function createOracleRequest(
        address _callbackAddress,
        bytes4 _callbackFunctionId,
        uint256 _nonce
    ) external returns (bytes32);

    function cancelOracleRequest(
        bytes32 _requestId,
        address _callbackAddress,
        bytes4 _callbackFuncId
    ) external returns (bytes32);

    function setCurrencyValue(bytes32 _currencyKind,uint256 _currencyValue)  external;
    function getCurrencyValue(bytes32 _currencyKind) external view returns(uint256);
}
