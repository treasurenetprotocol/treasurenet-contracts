## Stake Boosting(Bid)

## Functions

### isTATBider(address account) -> bool

Checks if an account is a TAT bidder.

- `account`:  Address of the account to check

- `bool`: `true` if the account is a TAT bidder, `false` otherwise

### mybidAmount() -> uint256

Gets the amount of TAT a user has bid.

- `uint256`: Amount of TAT the sender has bid

### roundStartBlock() -> uint256

Gets the start block of the current round.

- `uint256`: Start block of the current round

### bidTAT(uint256 amount) -> bool

Allows an account to bid TAT.

- `amount`: Amount of TAT to bid

- `bool`: `true` if the bid was successful

### bidderList() -> (BiderList\[\] memory, uint256, uint256)

Gets the list of TAT bidders.

- `BiderList[]`: Array of bidders with their details
- `uint256`: Total amount of TAT bid
- `uint256`: Start block of the current round

## Structs

### BiderList

- `address bider`: Address of the bidder
- `uint256 amount`: Amount of TAT bid by the bidder
- `uint256 block`: Block number at which the bid was made

## Events

### BidRecord

Emitted when a bid is made.

- `address account`: Address of the bidder

- `uint256 amount`: Amount of TAT bidder

### BidStart

Emitted when a new bidding round starts.

- `height`: Block number at which the bidding round started