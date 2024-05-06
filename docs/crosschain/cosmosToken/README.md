# cosmosToken

## Functions

### decimals() -> uint8

Overrides the ERC20 decimals function to return the specific number of decimals for the Cosmos ERC20 token.

- `uint8`:Number of decimals for the Cosmos ERC20 token

### totalSupply() -> uint256

Calculates and returns the total supply of the Cosmos ERC20 token on Ethereum. It is not an accurate total supply, but rather the total supply of the given Cosmos asset on Ethereum at the moment.

- `uint256`:Total supply of the Cosmos ERC20 token on Ethereum