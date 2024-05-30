## USTNInterface

## Functions

### bidCost(address bider, uint amount) -> bool

Transfer USTN tokens from bider to AuctionManager.

> \[!WARNING\]   
> Only allow USTNAuction contract to use.
> Require to get the account address of AuctionManager.

- `bider`: Address of the bidder
- `amount`: Amount of USTN to be transferred

- `bool`: Returns **true** if the operation is successful

### bidBack(address bider, uint amount) -> bool

Transfer USTN tokens from AuctionManager to bider.

> \[!WARNING\]   
> Only allow USTNAuction contract to use.
> Require to get the account address of AuctionManager.

- `bider`: Address of the bidder
- `amount`: Amount of USTN to be transferred

- `bool`: Returns **true** if the operation is successful

### burn(address account, uint256 tokens) -> bool

Burns the number of tokens of AuctionManager.

> \[!WARNING\]   
> Only allowed for USTNAuction.
>
> Triggered when receiving the auction item.

- `account`: Address from which the tokens are to be burned
- `tokens`: Amount of tokens to be burned

- `bool`: Returns **true** if the operation is successful

### reduceTotalSupply(uint amount) -> bool

Reduce the total amount issued by the amount.

> \[!WARNING\]   
> Only allow USTNFinance to use.
> Repay the loan to reduce the bank's additional issuance.

- `amount`: Amount to reduce from the total supply

- `bool`: Returns **true** if the operation is successful

### addTotalSupply(uint amount) -> bool

Increase the total amount issued by the amount.

> \[!WARNING\]   
> Only allow USTNFinance to use.
> The loan interest causes the total issuance to increase.

- `amount`: Amount to add to the total supply

- `bool`: Returns **true** if the operation is successful

### addBalance(address add, uint amount) -> bool

Increase the balance of the specified address.

> \[!WARNING\]   
> Only allow USTNFinance to use.

- `add`: Address to which the balance is to be increased
- `amount`: Amount of USTN to be added

- `bool`: Returns `true` if the operation is successful

### reduceBalance(address add, uint amount) -> bool

Reduce the balance of the specified address.

> \[!WARNING\]   
> Only allow USTNFinance to use.

- `add`: Address from which the balance is to be reduced
- `amount`: Amount of USTN to be reduced

- `bool`: Returns **true** if the operation is successful

### totalSupply() -> uint256

Get the total circulation of USTN.

- `uint256`: Total supply of the USTN token

### balanceOf(address tokenOwner) -> uint256

Query the USTN balance of the specified tokenOwner account.

- `tokenOwner`: Address of the account to query

- `uint256`: USTN balance of the specified account

### transfer(address to, uint256 tokens) -> bool

Transfer USTN tokens to a specified address.

- `to`: Address to which the tokens are to be transferred
- `tokens`: Amount of tokens to be transferred

- `bool`: Returns `true` if the transfer is successful