# IDAO

## Functions

### propose(address\[\] memory targets,bytes\[\] memory calldatas,string memory description) -> uint256

Creates a new proposal.

- `targets`: Array of target contract addresses
- `calldatas`: Array of contract call data
- `description`: Description of the proposal

- `uint256`: ID of the proposal

### castVote(uint256 proposalId,uint8 support) -> uint256

Casts a vote for a proposal.

- `proposalId`: ID of the proposal
- `support`: Support type (Against, For, Abstain)

- `uint256`: Voting balance

### withdraw(uint256 proposalId) -> uint256

Withdraws the voting tokens after the proposal is finalized.

- `proposalId`: ID of the proposal

- `uint256`: Withdrawn balance

### queue(address\[\] memory targets,bytes\[\] memory calldatas,bytes32 descriptionHash) -> uint256

Moves a successful proposal to the queued state.

- `targets`: Array of target contract addresses
- `calldatas`: Array of contract call data
- `descriptionHash`: Hash of the proposal description

- `uint256`: ID of the proposal

### execute(address\[\] memory targets,bytes\[\] memory calldatas,bytes32 descriptionHash) -> uint256

Executes a queued proposal.

- `targets`: Array of target contract addresses
- `calldatas`: Array of contract call data
- `descriptionHash`: Hash of the proposal description

- `uint256`: ID of the proposal

### hasVoted(uint256 proposalId,address account) -> bool

Checks if a voter has voted on a proposal.

- `proposalId`: ID of the proposal
- `account`: Voter's account address

- `bool`: `true` if the voter has voted, `false` otherwise

### state(uint256 proposalId) -> ProposalState

Gets the current state of a proposal.

- `proposalId`: ID of the proposal

- `ProposalState`: Current state of the proposal

### setBlockReward(uint256 newBlockReward)

Sets the block reward.

- `newBlockReward`: New block reward value

### setBlockRatio(uint256 newBlockRatio)

Sets the block ratio.

- `newBlockRatio`: New block ratio value

### blockReward() -> uint256

Gets the current block reward.

- `uint256`: Current block reward value

### blockRatio() -> uint256

Gets the current block ratio.

- `uint256`: Current block ratio value

### updateDelay(uint256 newDelay)

Updates the proposal voting delay.

- `newDelay`: New voting delay value

### votingDelay() -> uint256

Gets the current proposal voting delay.

- `uint256`: Current voting delay value

## Enums

### ProposalState

- `Pending`: Proposal is pending
- `Active`: Proposal is active
- `Canceled`: Proposal is canceled
- `Defeated`: Proposal is defeated
- `Succeeded`: Proposal is succeeded
- `Queued`: Proposal is queued
- `Expired`: Proposal is expired
- `Executed`: Proposal is executed