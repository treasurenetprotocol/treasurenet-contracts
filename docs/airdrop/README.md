# Airdrop

## Functions

### deployedAt() -> uint256

Track the contract's start time.

- `uint256`:Timestamp of contract deployment

### getRole(address account) -> Role

Used to retrieve the role of a specified address.

- `account`:Address of the account to get the role for

- `Role`:The role of the account (`FOUNDATION`, `VIP`, or `Unknown`)

### getVIPs() -> (address\[\] , uint256\[\])

Gets the list of VIP addresses and their corresponding ratios.

- `address[]`:Array of VIP addresses
- `uint256`:Array of VIP ratios

### getVIPInfo(address vip) -> (uint256,uint256,uint256,uint256)

Gets the claimed and claimable amounts for a VIP.

- `vip`:Address of the VIP
- `uint256`:Total claimed amount
- `uint256`:Total claimable amount
- `uint256`:Since which month the VIP started claiming
- `uint256`:Until which month the VIP can claim

### remainedToVIPs() -> uint256

Returns the remaining amount of tokens allocated for VIPs.

- `uint256`:Remaining amount of tokens for VIPs

### claimable() ->  (Role,uint256,ClaimStage,uint256,uint256)

Checks the claimable amount for the caller.

- `Role`: The role of the caller (`FOUNDATION` or `VIP`)
- `uint256`: Claimable amount
- `ClaimStage`: Current claim stage for the foundation
- `uint256`: Since which month the VIP started claiming
- `uint256`: Until which month the VIP can claim

### claim()

Claims the tokens for the caller.

### foundationWithdrawed() -> uint256

Returns the amount withdrawn by the foundation.

- `uint256`: Stage1 withdrawal amount of the foundation

### receiveIntermidiateFund()

Receives intermediate funds and distributes to VIPs.

### foundationClaimVIPs()

Allows the foundation to claim the remaining tokens allocated for VIPs after 1 year.

### propose(ProposalPurpose purpose,address\[\] memory vips,uint256\[\] memory ratios) -> uint256

Creates a proposal to change VIPs' ratios.

- `purpose`: Purpose of the proposal
- `vips`: Array of VIP addresses
- `ratios`: Array of new ratios for VIPs

- `uint256`: Proposal ID

### signTransaction(uint256 \_proposalId) -> bool

Allows Foundation Managers or Board Directors to sign a proposal.

- `_proposalId`: ID of the proposal to sign

- `bool`: Whether the signing was successful

### executeProposal(uint256 \_proposalId)

Executes a signed proposal.

- `_proposalId`: ID of the proposal to execute

## Structs

### Proposal

- `address proposer`:Address of the proposer

- `ProposalPurpose purpose`:Purpose of the proposal

- `address[] vips`:Array of VIP addresses

- `uint256[] ratios`:Array of ratios for VIPs

- `uint8 sigCount`:Number of signatures received

- `uint256 excuteTime`:Time when the proposal will be executed

- `mapping(address => uint8) signatures`:Mapping of signers and their signatures

## Enums

### Role

- `Unknown`:Unknown role
- `VIP`:VIP role
- `FOUNDATION`:Foundation role

### ClaimStage

- `StageUnknown`:Unknown stage
- `Stage1`:First claim stage
- `Stage2`:Second claim stage

### ProposalPurpose

- `ChangeVIP`:Modify user whitelist and user ratio (MulSig)

## Events

### Claimed

Emitted when tokens are claimed.

- `Role`: The role of the claimer
- `uint256`: Claimed amount
- `ClaimStage`: Current claim stage for the foundation
- `uint256`: Since which month the VIP started claiming
- `uint256`: Until which month the VIP can claim

### FoundationClaimed(address foundation, ClaimStage stage, uint256 amount)

Emitted when the foundation claims tokens.

- `address`: Foundation's address
- `ClaimStage`: Current claim stage
- `uint256`: Amount claimed

### VIPClaimed(address vip, uint256 sinceMonth, uint256 toMonth, uint256 amount);

Emitted when a VIP claims tokens.

- `address`: VIP's address
- `uint256`: Since which month the VIP started claiming
- `uint256`: Until which month the VIP can claim
- `uint256`: Amount claimed

### ReceivedInterFund(address from,uint256 currentMonth,uint256 amount,uint256 remainedToVips);

Emitted when intermediate funds are received.

- `address`: Sender's address
- `uint256`: Current month
- `uint256`: Amount received
- `uint256`: Remaining amount allocated for VIPs

### ProposalSucc(uint256 proposalId, uint256 executeTime);

Emitted when a proposal meets the threshold and is successful.

- `uint256`: Proposal ID
- `uint256`: Execution time

### ProposalSigned(uint256 proposalId, address signer);

Emitted when a proposal is signed.

- `uint256`: Proposal ID.
- `address`: Signer's address.

### ProposalExecuted(uint256 proposalId, ProposalPurpose purpose);

Emitted when a proposal is executed.

- `uint256`: Proposal ID
- `ProposalPurpose`: Purpose of the proposal

### ChangeVIP(address vip, uint256 before, uint256 now);

Emitted when VIP ratios are changed.

- `address`: VIP's address
- `uint256`: Previous ratio
- `uint256`: New ratio
