# IGovernance

## Functions

### addTreasure(string memory \_treasureType,address \_producer,address \_productionData)

Adds a new treasure asset (this method can only be called from the multi-signature contract).

- `_treasureType`: Name of the asset
- `_producer`: Address of the producer contract
- `_productionData`: Address of the production data contract

### fmThreshold() -> uint256

Returns the current governance multi-signature contract threshold.

- `uint256`: Threshold value

### getTreasureByKind(string memory \_treasureType) -> (address,address)

Returns the addresses of the producer and production data contracts for a given treasure type.

- `_treasureType`: Name of the asset

- `address`: Address of the producer contract
- `address`: Address of the production data contract