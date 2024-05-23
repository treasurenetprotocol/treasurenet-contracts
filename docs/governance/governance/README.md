# Governance

## Functions

### initialize(address \_daoContract,address \_mulSigContract,address \_roleContract,address \_parameterInfoContract,string\[\] memory \_treasureTypes,address\[\] memory \_producers,address\[\] memory \_productionDatas)

Initializes the governance contract.

- `_daoContract`: DAO contract address
- `_mulSigContract`: Multi-signature contract address
- `_roleContract`: Roles management contract address
- `_parameterInfoContract`: Parameter management contract address
- `_treasureTypes`: Array of asset names
- `_producers`: Array of producer contract addresses
- `_productionDatas`: Array of production data contract addresses

### fmThreshold() -> uint256

Returns the current governance multi-signature contract threshold.

- `uint256`: Threshold value

### addTreasure(string memory \_treasureType,address \_producer,address \_productionData)

Adds a new treasure asset (this method can only be called from the multi-signature contract).

- `_treasureType`: Name of the asset
- `_producer`: Address of the producer contract
- `_productionData`: Address of the production data contract

### getTreasureByKind(string memory \_treasureType) -> (address,address)

Returns the addresses of the producer and production data contracts for a given treasure type.

- `_treasureType`: Name of the asset

- `address`: Address of the producer contract
- `address`: Address of the production data contract

## Structs

### Treasure

- `bytes32 Kind`: The type of treasure.
- `address ProducerContract`: Address of the producer contract
- `address ProductionDataContract`: Address of the production data contract

## Events

### AddTreasure(string treasureType,address producerContract,address produceDataContract);

Emitted when a new treasure is added.

- `treasureType`: Name of the asset
- `producerContract`: Address of the producer contract
- `produceDataContract`: Address of the production data contract