# IOracle

## Functions

### createOracleRequest(address \_callbackAddress,bytes4 \_callbackFunctionId,uint256 \_nonce) -> bytes32

Creates a new Oracle request.

- `_callbackAddress`: Address of the callback contract
- `_callbackFunctionId`: Function ID of the callback
- `_nonce`: Nonce value

- `bytes32`: ID of the new request

### cancelOracleRequest(bytes32 \_requestId,address \_callbackAddress,bytes4 \_callbackFuncId) -> bytes32

Cancels an existing Oracle request.

- `_requestId`: ID of the request
- `_callbackAddress`: Address of the callback contract
- `_callbackFuncId`: Function ID of the callback

- `bytes32`: ID of the canceled request

### setCurrencyValue(bytes32 \_currencyKind,uint256 \_currencyValue)

Sets the value for a currency kind.

- `_currencyKind`: Kind of the currency
- `_currencyValue`: Value of the currency

### getCurrencyValue(bytes32 \_currencyKind) -> uint256

Gets the value for a currency kind.

- `_currencyKind`: Kind of the currency

- `uint256`: Value of the currency