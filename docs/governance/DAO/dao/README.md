# DAO

## Functions

### initialize(string memory \_name,uint256 \_minTimeDelay,uint256 \_\_votingPeriod)

Initializes the DAO contract with necessary parameters.

- `_name`: DAO organization name
- `_minTimeDelay`: Minimum time delay (timestamp)
- `__votingPeriod`: Voting period

### COUNTING_MODE() -> string

Returns the counting mode for the Governor.

- `string`: Counting mode string.

### hasVoted(uint256 proposalId,address account) -> bool

Whether the user has voted.

- `proposalId`: ID of the proposal
- `account`: Address of the user

- `bool`: Whether the user has voted

### proposalVotes(uint256 proposalId) -> (uint256,uint256,uint256)

View the current voting details of the proposal.

- `proposalId`: ID of the proposal

- `uint256`: The number of negative votes
- `uint256`: The number of agree votes
- `uint256`: The number of abstain votes

### updateDelay(uint256 newDelay)

update time depay (completed through DAO proposal).

- `newDelay`: New time delay (timestamp)

### votingDelay() -> uint256

Query the current voting delay.

- `uint256`: Current voting delay

### updateVotingPeriod(uint256 newVotingPeriod)

Updates the voting cycle (completed through DAO proposal).

- `newVotingPeriod`: New voting period

### votingPeriod() -> uint256

Query the current voting period.

- `uint256`: Current voting period

### setBlockReward(uint256 newBlockReward)

Set block reward.

- `newBlockReward`: New block reward

### setBlockRatio(uint256 newBlockRatio)

Set block ratio.

- `newBlockRatio`: New block ratio.

### blockReward() -> uint256

Get block reward.

- `uint256`: Current block reward

### blockRatio() -> uint256

Get the block ratio.

- `uint256`: Current block ratio.

### quorum(uint256 blockNumber) -> uint256

Calculates the quorum needed for a proposal.

- `blockNumber`: Block number

- `uint256`: Quorum

## Structs

### ProposalVote

- `uint256 againstVotes`: Number of votes against the proposal
- `uint256 forVotes`: Number of votes for the proposal
- `uint256 abstainVotes`: Number of abstain votes for the proposal
- `mapping(address => bool) hasVoted`: Mapping of addresses to check if an address has voted

## Enums

### VoteType

- `Against`: Against
- `For`: Agree
- `Abstain`: Abstain

## Events

### MinDelayChange(uint256 oldDuration, uint256 newDuration);

Emitted when the minimum time delay is changed.

- `uint256 oldDuration`: Old minimum time delay
- `uint256 newDuration`: New minimum time delay

### ProposalThresholdSet(uint256 oldProposalThreshold,uint256 newProposalThreshold);

Emitted when the proposal threshold is set.

- `uint256 oldProposalThreshold`: Old proposal threshold
- `uint256 newProposalThreshold`: New proposal threshold