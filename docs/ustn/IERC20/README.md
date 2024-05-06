# IERC20

## Functions

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

### allowance(address tokenOwner, address spender) -> uint256

Query the remaining number of tokens authorized to spender by the tokenowner.

- `tokenOwner`: Address of the token owner
- `spender`: Address of the spender

- `uint256`: Remaining number of tokens authorized

### approve(address spender, uint256 tokens) -> bool

TokenOwner delegates spender to use tokens.

- `spender`: Address of the spender
- `tokens`: Amount of tokens to be approved

- `bool`: Returns **true** if the approval is successful

### transferFrom(address from, address to, uint256 tokens) -> bool

Transfer tokens from one address to another.

- `from`: Address from which the tokens are to be transferred
- `to`: Address to which the tokens are to be transferred
- `tokens`: Amount of tokens to be transferred

- `bool`: Returns **true** if the transfer is successful

## Events

### Transfer(address indexed from, address indexed to, uint256 tokens);

Emitted when tokens are transferred from one address to another.

- `from`: The address from which the tokens are transferred
- `to`: The address to which the tokens are transferred
- `tokens`: The amount of tokens transferred

### Approval(address indexed owner, address indexed spender, uint256 tokens);

Emitted when an approval is made to allow another address to spend tokens on behalf of the token owner.

- `owner`: The address that approves the spending of tokens
- `spender`: The address that is approved to spend the tokens
- `tokens`: The amount of tokens approved to be spent