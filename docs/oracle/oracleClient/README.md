# OracleClient

## Functions

### \_\_oracleClientInitialize(address \_oracleContractAddress)

Initializes the OracleClient contract.

- `_oracleContractAddress`: Address of the Oracle contract

### \_oracleContract() -> address

Returns the address of the Oracle contract.

- `address`: Address of the Oracle contract

### \_currNonce() -> uint256

Returns the current nonce value.

- `uint256`: Current nonce value

### \_nextNonce() -> uint256

Increments and returns the next nonce value.

- `uint256`: Next nonce value

### \_sendOracleRequest(address \_callbackAddress,bytes4 \_callbackFunctionId,uint256 \_request_nonce) -> bytes32

Sends an Oracle request.

- `_callbackAddress`: Address of the callback contract
- `_callbackFunctionId`: Function ID of the callback
- `_request_nonce`: Nonce value for the request

### \_cancelOracleRequest(bytes32 \_requestId,address \_callbackAddress,bytes4 \_callbackFunctionId)

Cancels an existing Oracle request.

- `_requestId`: ID of the request to cancel
- `_callbackAddress`: Address of the callback contract
- `_callbackFunctionId`: Function ID of the callback

## Events

### Request(bytes32 requestid,address callbackAddress,bytes4 callbackFunctionId,uint256 nonce);

Emitted when an Oracle request is sent.

- `requestid`: ID of the request
- `callbackAddress`: Address of the callback contract
- `callbackFunctionId`: Function ID of the callback
- `nonce`: Nonce value used for the request