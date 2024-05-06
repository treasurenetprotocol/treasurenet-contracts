## IStake

### stake(address account, uint256 \_amount)

Abstract function to stake an amount.

- `account`: Address of the stakeholder
- `_amount`: Amount to stake

### withdraw(address account, uint256 \_amount)

Abstract function to withdraw an amount.

- `account`: Address of the stakeholder
- `_amount`: Amount to withdraw

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