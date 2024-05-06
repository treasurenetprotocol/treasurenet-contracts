# gravity

## Functions

### lastBatchNonce(address \_erc20Address) -> uint256

Retrieves the last batch nonce for a specific ERC20 token.

- `_erc20Address`: Address of the ERC20 token
- `uint256`: Last batch nonce for the given ERC20 token

### lastLogicCallNonce(bytes32 \_invalidation\_id) -> uint256

Retrieves the last logic call nonce for a specific invalidation ID.

- `_invalidation_id`: Invalidation ID for the logic call

- `uint256`: Last logic call nonce for the given invalidation ID

### verifySig(address \_signer,bytes32 \_theHash,Signature calldata \_sig) -> bool

Utility function to verify Geth-style signatures.

- `_signer`: Address of the signer

- `_theHash`: Hash to verify the signature

- `_sig`: Signature data

- `bool`: Whether the signature is valid

### validateValset(ValsetArgs calldata \_valset, Signature\[\] calldata \_sigs)

Validates the current validator set and signatures.

- `_valset`: Validator set details
- `_sigs`: Array of signatures

### makeCheckpoint(ValsetArgs memory \_valsetArgs, bytes32 \_gravityId) -> bytes32

Generates a checkpoint hash from the validator set details.

- `_valsetArgs`: Validator set details

- `_gravityId`: Gravity ID
- `bytes32`: Checkpoint hash

### checkValidatorSignatures(ValsetArgs calldata \_currentValset,Signature\[\] calldata \_sigs,bytes32 \_theHash,uint256 \_powerThreshold)

Checks that enough validators have signed off on the provided hash.

- `_currentValset`: Current validator set details
- `_sigs`: Array of signatures
- `_theHash`: Hash to verify the signatures
- `_powerThreshold`: Power threshold

### updateValset(ValsetArgs calldata \_newValset,ValsetArgs calldata \_currentValset,Signature\[\] calldata \_sigs)

Updates the validator set by validating the new set and the signatures.

- `_newValset`: New validator set details

- `_currentValset`: Current validator set details

- `_sigs`: Array of signatures

### submitBatch(ValsetArgs calldata \_currentValset,Signature\[\] calldata \_sigs,uint256\[\] calldata \_amounts,address\[\] calldata \_destinations,uint256\[\] calldata \_fees,uint256 \_batchNonce,address \_tokenContract,uint256 \_batchTimeout)

Processes a batch of Cosmos to Ethereum transactions.

- `_currentValset`: Current validator set details

- `_sigs`: Array of signatures

- `_amounts`: Array of transfer amounts

- `_destinations`: Array of destination addresses

- `_fees`: Array of fee amounts

- `_batchNonce`: Batch nonce

- `_tokenContract`: Address of the ERC20 token contract

- `_batchTimeout`: Timeout block height.

### submitLogicCall(ValsetArgs calldata \_currentValset,Signature\[\] calldata \_sigs,LogicCallArgs memory \_args)

Executes an arbitrary logic call by transferring tokens to a logic contract and calling an arbitrary function.

- `_currentValset`: Current validator set details

- `_sigs`: Array of signatures

- `_args`: Logic call arguments

### sendToCosmos(address \_tokenContract,string calldata \_destination,uint256 \_amount)

Transfers tokens to the Cosmos network.

- `_tokenContract`: Address of the ERC20 token contract

- `_destination`: Cosmos destination address

- `_amount`: Amount of tokens to send

### deployERC20(string calldata \_cosmosDenom,string calldata \_name,string calldata \_symbol,uint8 \_decimals)

Deploys a new ERC20 token with the entire supply granted to the Gravity contract.

- `_cosmosDenom`: Cosmos denomination

- `_name`: Name of the ERC20 token

- `_symbol`: Symbol of the ERC20 token

- `_decimals`: Decimals of the ERC20 token

## Structs

### LogicCallArgs

- `uint256[] transferAmounts`: Array of transfer amounts to the logic contract

- `address[] transferTokenContracts`: Array of token contracts for transfers

- `uint256[] feeAmounts`: Array of fee amounts to be transferred to msg.sender

- `address[] feeTokenContracts`: Array of token contracts for fees

- `address logicContractAddress`: Address of the logic contract to call

- `bytes payload`: Payload data for the logic call

- `uint256 timeOut`: Block height beyond which the logic call is not valid

- `bytes32 invalidationId`: Identifier for replay prevention

- `uint256 invalidationNonce`: Nonce for replay prevention

### ValsetArgs

- `address[] validators`: Array of validator addresses
- `uint256[] powers`: Array of validator powers
- `uint256 valsetNonce`: Nonce of the validator set
- `uint256 rewardAmount`: Reward amount denominated in the reward token
- `address rewardToken`: Reward token address

### Signature

- `uint8 v`: Recovery id

- `bytes32 r`: Signature parameter

- `bytes32 s`: Signature parameter

## Events

### TransactionBatchExecutedEvent(uint256 indexed \_batchNonce,address indexed \_token,uint256 \_eventNonce);

Emitted when a transaction batch is executed.

- `uint256 indexed _batchNonce`: Nonce of the executed batch
- `address indexed _token`: Address of the token contract
- `uint256 _eventNonce`: Nonce of the event

### SendToCosmosEvent(address indexed \_tokenContract,address indexed \_sender,string \_destination,uint256 \_amount,uint256 \_eventNonce);

Emitted when tokens are sent from Ethereum to Cosmos.

- `address indexed _tokenContract`: Address of the token contract
- `address indexed _sender`: Address of the sender
- `string _destination`: Destination address on the Cosmos network
- `uint256 _amount`: Amount of tokens sent
- `uint256 _eventNonce`: Nonce of the event

### ERC20DeployedEvent(string \_cosmosDenom,address indexed \_tokenContract,string \_name,string \_symbol,uint8 \_decimals,uint256 \_eventNonce);

Emitted when an ERC20 token is deployed.

- `string _cosmosDenom`: Denomination of the token on the Cosmos network
- `address indexed _tokenContract`: Address of the deployed ERC20 token contract
- `string _name`: Name of the ERC20 token
- `string _symbol`: Symbol of the ERC20 token
- `uint8 _decimals`: Number of decimals for the ERC20 token
- `uint256 _eventNonce`: Nonce of the event

### ValsetUpdatedEvent(uint256 indexed \_newValsetNonce,uint256 \_eventNonce,uint256 \_rewardAmount,address \_rewardToken,address\[\] \_validators,uint256\[\] \_powers);

Emitted when the validator set is updated.

- `uint256 indexed _newValsetNonce`: Nonce of the new validator set
- `uint256 _eventNonce`: Nonce of the event
- `uint256 _rewardAmount`: Reward amount denominated in the reward token
- `address _rewardToken`: Reward token address
- `address[] _validators`: Array of validator addresses
- `uint256[] _powers`: Array of validator powers

### LogicCallEvent(bytes32 \_invalidationId,uint256 \_invalidationNonce,bytes \_returnData,uint256 \_eventNonce);

Emitted when an arbitrary logic call is executed.

- `bytes32 _invalidationId`: Identifier for replay prevention
- `uint256 _invalidationNonce`: Nonce for replay prevention
- `bytes _returnData`: Return data from the logic call
- `uint256 _eventNonce`: Nonce of the event