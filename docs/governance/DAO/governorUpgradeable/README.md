# GovernorUpgradeable

## Functions

### supportsInterface(bytes4 interfaceId) -> bool

Checks if a contract implements an interface.

- `interfaceId`: The interface identifier

- `bool`: Whether the contract implements the interface

### name() -> string

Name of the governor instance (used in building the ERC712 domain separator).

- `string`: Name of the governor instance

### version() -> string

Gets the version of the governor instance.

- `string`: Version of the governor instance

### _updateDelay(uint256 newDelay)

Updates the minimum delay for proposal execution.

- `newDelay`: The new minimum delay

### _getDelay() -> uint256

Returns the minimum delay for proposal execution.

- `uint256`: The minimum delay

### hashProposal(address\[\] memory targets,bytes\[\] memory calldatas,bytes32 descriptionHash) -> uint256

Hashing function used to (re)build the proposal id from the proposal details.

- `targets`: Array of target contract addresses
- `calldatas`: Array of contract call data
- `descriptionHash`: Hash of the proposal description

- `uint256`: ID of the proposal

### state(uint256 proposalId) -> ProposalState

Gets the current state of a proposal.

- `proposalId`: ID of the proposal

- `ProposalState`: Current state of the proposal

### proposalSnapshot(uint256 proposalId) -> uint256

Gets the snapshot block number of a proposal.

- `proposalId`: ID of the proposal

- `uint256`: The snapshot block number

### proposalDeadline(uint256 proposalId) -> uint256

Gets the deadline block number of a proposal.

- `proposalId`: ID of the proposal

- `uint256`: The deadline block number

### proposalThreshold() -> uint256

Returns the proposal threshold.

- `uint256`: The proposal threshold

### _quorumReached(uint256 proposalId) -> bool

Amount of votes already cast passes the threshold limit.

- `proposalId`: ID of the proposal

- `bool`: Whether the quorum is reached

### _voteSucceeded(uint256 proposalId) -> bool

Checks if the vote succeeded for a proposal.

- `proposalId`: ID of the proposal

- `bool`: Whether the vote succeeded

### _countVote(uint256 proposalId,address account,uint8 support,uint256 weight)

Registers a vote for a proposal.

> \[!TIP\]   
> Support is generic and can represent various things depending on the voting system used.

- `proposalId`: ID of the proposal
- `account`: Address of the voter
- `support`: Whether the voter supports the proposal
- `weight`: Weight of the vote

### propose(address\[\] memory targets,bytes\[\] memory calldatas,string memory description) -> uint256

Creates a new proposal.

- `targets`: Array of target contract addresses
- `calldatas`: Array of contract call data
- `description`: Description of the proposal

- `uint256`: ID of the proposal

### queue(address\[\] memory targets,bytes\[\] memory calldatas,bytes32 descriptionHash) -> uint256

Moves a successful proposal to the queued state.

- `targets`: Array of target contract addresses
- `calldatas`: Array of contract call data
- `descriptionHash`: Hash of the proposal description

- `uint256`: ID of the proposal

### manualExecuted(uint256 proposalId) -> uint256

Manually executes a proposal.

- `proposalId`: ID of the proposal

- `uint256`: ID of the proposal

### execute(address\[\] memory targets,bytes\[\] memory calldatas,bytes32 descriptionHash) -> uint256

Executes a successful proposal.

- `targets`: Array of target contract addresses
- `calldatas`: Array of contract call data
- `descriptionHash`: Hash of the proposal description

- `uint256`: ID of the proposal

### castVote(uint256 proposalId,uint8 support) -> uint256

Casts a vote for a proposal.

- `proposalId`: ID of the proposal
- `support`: Whether the voter supports the proposal(Against, For, Abstain)
- `uint256`: Weight of the vote.

### relay(address target,uint256 value,bytes calldata data)

Relays a transaction or function call to an arbitrary target.

> \[!WARNING\]   
> That if the executor is simply the governor itself, use of `relay` is redundant.

- `target`: Target address
- `value`: Value to send with the call
- `data`: Data for the call

### withdraw(uint256 proposalId) -> uint256

Withdraws the voting tokens after the proposal is finalized.

- `proposalId`: ID of the proposal

- `uint256`: Amount of tokens withdrawn

## Structs

### ProposalCore

- `TimersUpgradeable.BlockNumber voteStart`: Start block number for voting
- `TimersUpgradeable.BlockNumber voteEnd`: End block number for voting
- `bool queued`: Whether the proposal is queued
- `bool executed`: Whether the proposal is executed
- `bool canceled`: Whether the proposal is canceled
- `bool manualExecuted`: Whether the proposal is manually executed

### Vote

- `address Voter`: Address of the voter
- `uint256 amount`: Amount of token voted
- `bool withdrawed`: Whether the voter has withdrawn their vote

