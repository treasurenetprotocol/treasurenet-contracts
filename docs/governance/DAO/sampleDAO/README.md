# SampleDAO

## Functions

### initialize(address dao\_)

Initializes the contract with the DAO address.

- `dao_`: Address of the DAO

### blockReward() -> uint256

Gets the current block reward value.

- `uint256`: Current block reward value

### setBlockReward(uint256 \_newReward)

Sets the block reward value.

- `_newReward`: New block reward value

### receiveEth()

Receives Ether and emits a `PayEth` event.

## Events

### BlockRewardReset(uint256 oldB, uint256 newB);

Emitted when the block reward is updated.

- `uint256 oldB`: Old block reward value
- `uint256 newB`: New block reward value

### PayEth(uint256);

Emitted when Ether is received by the contract.

- `uint256`: Amount of Ether received

