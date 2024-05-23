## Stakeable

## Functions

### \_isStakeholder(address \_address) -> (bool,uint256)

Checks if an address is a stakeholder.

- `_address`: Address to check

- `bool`: Whether the address is a stakeholder
- `uint256`: Index of the stakeholder in **\_stakeHolders** array

### \_addStakeholder(address \_stakeholder)

Adds a new stakeholder to the **\_stakeHolders** array.

- `_stakeholder`: Address of the new stakeholder

### \_removeStakeholder(address \_stakeholder)

Removes a stakeholder from the **\_stakeHolders** array.

- `_stakeholder`: Address of the stakeholder to remove

### stakeOf(address \_stakeholder) -> uint256

Gets the stake amount of a stakeholder.

- `_stakeholder`: Address of the stakeholder

- `uint256`: Amount of stake

### totalStakes() -> uint256

Gets the total stakes across all stakeholders.

- `uint256`: Total stake amount

### totalStakers() -> uint256

Gets the total number of stakeholders.

- `uint256`: Total number of stakeholders

### stake(address account, uint256 \_amount)

Abstract function to stake an amount.

- `account`: Address of the stakeholder
- `_amount`: Amount to stake

### withdraw(address account, uint256 \_amount)

Abstract function to withdraw an amount.

- `account`: Address of the stakeholder
- `_amount`: Amount to withdraw

## Events

### Stake(address from, uint256 amount);

Emitted when a stake is made.

- `from`: Address of the stakeholder
- `amount`: Amount of stake

### Withdraw(address from, uint256 amount);

Emitted when a withdrawal is made.

- `from`: Address of the stakeholder
- `amount`: Amount of withdrawal