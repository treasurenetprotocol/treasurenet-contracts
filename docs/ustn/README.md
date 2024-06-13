# USTN Token

The USTN contract is an ERC-20 token contract based on the Ethereum blockchain, aimed at managing the issuance, transfer, and other operations of USTN tokens. This contract implements the standard ERC-20 interface and extends several special features, including auction management, financial management, and exchange between USTN and UNIT. The contract also integrates role management and oracle systems to ensure the security and accuracy of various operations.

The main functions of this governance contract include:

- Token management: issuing, destroying, and transferring USTN tokens.
- Exchange function: Exchange between USTN and UNIT based on the exchange rate provided by the oracle machine.
- Auction management: Token operations related to auctions.
- Financial management: Increase or decrease the total supply of tokens and account balance.

## Table of Contents

- [Installation](#installation)
- [Defining the features](#Defining the features)
- [Contributing](#contributing)
- [Code of Conduct](#code-of-conduct)
- [License](#license)
- [Tests](#tests)
- [Other contract API details](#Other contract API details)

## Installation

To install and set up the TAT smart contract for development, follow these steps:

```bash
# Clone the repository
git clone https://github.com/treasurenetprotocol/treasurenet-contracts.git

# Navigate to the project directory
cd treasurenetprotocol

# Install the dependencies
npm install
```

## Defining the features

| Function                                                     | Description                                                  |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| `transfer(address to, uint256 tokens)` -> bool               | Transfer USTN tokens to a specified address.<br />`to`: Address to which the tokens are to be transferred <br />`tokens`: Amount of tokens to be transferred <br />`bool`: Returns `true` if the transfer is successful |
| `approve(address spender, uint256 tokens) ` -> bool          | TokenOwner delegates spender to use tokens.<br />`spender`: Address of the spender <br />`tokens`: Amount of tokens to be approved <br />`bool`: Returns **true** if the approval is successful |
| `transferFrom(address from, address to, uint256 tokens) ` -> bool | Transfer tokens from one address to another.<br />`from`: Address from which the tokens are to be transferred <br />`to`: Address to which the tokens are to be transferred <br />`tokens`: Amount of tokens to be transferred <br />`bool`: Returns **true** if the transfer is successful |
| `addTotalSupply(uint amount) ` -> bool                       | Increase the total amount issued by the amount.<br />`amount`: Amount to add to the total supply <br />`bool`: Returns **true** if the operation is successful |

### Initializing the Contract

First, deploy the contract and then initialize it with the required parameters. For example:

```solidity
USTN ustn = new USTN();
ustn.initialize(0x1bB5bf909d1200fb4730d899BAd7Ab0aE8487B0b, 0xa738B14dcbeb4340Bd7fC082BD03E3234e8165eF, 0x03C6FcED478cBbC9a4FAB34eF9f40767739D1Ff7, 0x1aE0EA34a72D944a8C7603FfB3eC30a6669E454C);
```

## Contributing

We welcome contributions to the project! Please follow these steps to contribute:

1. Fork the repository.
2. Create a new branch (`git checkout -b feature-branch`).
3. Commit your changes (`git commit -am 'Add new feature'`).
4. Push to the branch (`git push origin feature-branch`).
5. Create a new Pull Request.

Please ensure your code adheres to our coding standards and includes relevant tests.

## Code of Conduct

We expect all contributors to adhere to our [Code of Conduct](link-to-code-of-conduct). Please read it to understand the expected behavior.

## License

This project is licensed under the MIT License. See the [LICENSE](link-to-license) file for details.

## Tests

To run the tests for this project, taking OIL as an example, it is as follows

```js
const { web3 } = require("@openzeppelin/test-helpers/src/setup");

// USTN.test.js
const USTN = artifacts.require("USTN");
const Roles = artifacts.require("Roles");
const Oracle = artifacts.require("Oracle");
const MulSig = artifacts.require("MulSig");
const USTNFinance = artifacts.require("USTNFinance");
const USTNAuction = artifacts.require("USTNAuction");

const currencyKind = web3.utils.asciiToHex("USTN");
const unit = web3.utils.asciiToHex("UNIT");

contract("USTN", async (accounts) => {

    let ustn;
    let roles;
    let oracle;
    let mulSig;
    let ustnFinance;
    let ustnAuction;
    before(async () => {
        ustn = await USTN.deployed();
        roles = await Roles.deployed();
        oracle = await Oracle.deployed();
        mulSig = await MulSig.deployed();
        ustnFinance = await USTNFinance.deployed();
        ustnAuction = await USTNAuction.deployed();
    })

    it("should initialize properly", async () => {
        const ustnAuction = accounts[1];
        const ustnFinance = accounts[2];
        await roles.initialize(mulSig.address, [accounts[7]], [accounts[8]], [accounts[9]]);
        await oracle.initialize(roles.address);
        await ustn.initialize(roles.address, oracle.address, ustnAuction, ustnFinance, {from: accounts[0]});
        assert.equal(await ustn.name(), "ustn token");
        assert.equal(await ustn.decimals(), 18);
        assert.equal(await ustn.symbol(), "USTN");
    });

    it("should allow transfer of tokens", async () => {
        const amount = web3.utils.toBN(10 * 1e18);
    
        // Add balance to account[3]
        await ustn.addBalance(accounts[3], amount, { from: accounts[2] });
    
        const initialBalanceSender = web3.utils.toBN(await ustn.balanceOf(accounts[3]));
        const initialBalanceReceiver = web3.utils.toBN(await ustn.balanceOf(accounts[4]));
    
        const tokens = web3.utils.toBN(1 * 1e18);
        
        // Transfer tokens
        await ustn.transfer(accounts[4], tokens, { from: accounts[3] });
        
        // Get final balances
        const finalBalanceSender = web3.utils.toBN(await ustn.balanceOf(accounts[3]));
        const finalBalanceReceiver = web3.utils.toBN(await ustn.balanceOf(accounts[4]));
        
        // Check the sender's balance
        const expectedFinalBalanceSender = initialBalanceSender.sub(tokens);
        assert.equal(finalBalanceSender.toString(), expectedFinalBalanceSender.toString(), "Sender balance should decrease by the transfer amount");
        
        // Check the receiver's balance
        const expectedFinalBalanceReceiver = initialBalanceReceiver.add(tokens);
        assert.equal(finalBalanceReceiver.toString(), expectedFinalBalanceReceiver.toString(), "Receiver balance should increase by the transfer amount");
    });

    it("should allow approval and transferFrom", async () => {
        const approvalAmount = web3.utils.toBN(5 * 1e18);
        const transferAmount = web3.utils.toBN(2 * 1e18);
        const initialBalanceAccount3 = await ustn.balanceOf(accounts[3]);
    
        // Approve accounts[5] to spend tokens on behalf of accounts[3]
        await ustn.approve(accounts[5], approvalAmount, { from: accounts[3] });
    
        // Use transferFrom to transfer tokens from accounts[3] to accounts[6]
        await ustn.transferFrom(accounts[3], accounts[6], transferAmount, { from: accounts[5] });
    
        // Get final balances
        const finalBalanceAccount3 = web3.utils.toBN(await ustn.balanceOf(accounts[3]));
        const finalBalanceAccount6 = web3.utils.toBN(await ustn.balanceOf(accounts[6]));
    
        // Calculate expected final balances
        const expectedFinalBalanceAccount3 = initialBalanceAccount3.sub(transferAmount);
        const expectedFinalBalanceAccount6 = transferAmount; // accounts[6] initial balance is 0
    
        // Check if the final balance of accounts[3] decreased by the transfer amount
        assert.equal(finalBalanceAccount3.toString(), expectedFinalBalanceAccount3.toString(), "Final balance of accounts[3] should decrease by the transfer amount");
    
        // Check if the final balance of accounts[6] increased by the transfer amount
        assert.equal(finalBalanceAccount6.toString(), expectedFinalBalanceAccount6.toString(), "Final balance of accounts[6] should increase by the transfer amount");
    });
    
    it("should not allow transfer without enough balance", async () => {
        const balance = await ustn.balanceOf(accounts[0]);
        const amount = balance.add(web3.utils.toBN(1));
        try {
            await ustn.transfer(accounts[3], amount, { from: accounts[0] });
            assert.fail("Transfer should have failed");
        } catch (err) {
            assert.ok(err.message.includes("USTN: balances not enough"), "Transfer error message incorrect");
        }
    });
    
    it("should mint USTN correctly", async () => {
        // Set currency value
        await oracle.setCurrencyValue(currencyKind, web3.utils.toWei('1', 'ether'), {from: accounts[9]});
        await oracle.setCurrencyValue(unit, web3.utils.toWei('1', 'ether'), { from: accounts[9] });

        const currencyValue = await oracle.getCurrencyValue(currencyKind);
        console.log("Currency value:", currencyValue.toString());
    
        // Get initial balance
        const initialBalance = await ustn.balanceOf(accounts[0]);
        console.log("Initial balance:", initialBalance.toString());
    
        // Define minting amount (in Ether)
        const mintingAmountInEther = "1";
        const value = web3.utils.toWei(mintingAmountInEther, "ether");
        console.log("Minting value in Wei:", value);
    
        // Call mint function to mint tokens, sending Ether along with the transaction
        await ustn.mint({ from: accounts[0], value: value });
        console.log("Mint function called");
    
        // Get final balance
        const finalBalance = await ustn.balanceOf(accounts[0]);
        console.log("Final balance:", finalBalance.toString());
    
        // Calculate expected minted amount
        const exchangeRate = await ustn.mintRate(value);
        const expectedMintedAmount = exchangeRate.toString();
        console.log("Expected minted amount:", expectedMintedAmount);
    
        // Verify the balance change after minting
        assert.equal(finalBalance.sub(initialBalance).toString(), expectedMintedAmount, "Minted value should be added to the balance");
    });
    

    it("should mintBack USTN correctly", async () => {
        const ustn = await USTN.deployed();
        const initialBalance = await ustn.balanceOf(accounts[0]);
        const value = web3.utils.toWei("1", "ether");
        await ustn.mint({ from: accounts[0], value: value });
        const valueInTokens = await ustn.mintRate(value);
        await ustn.mintBack(valueInTokens, { from: accounts[0] });
        const finalBalance = await ustn.balanceOf(accounts[0]);
        assert.equal(finalBalance.toString(), initialBalance.toString());
    });

    it("should not allow mintBack exceeding threshold", async () => {
        const ustn = await USTN.deployed();
        const initialBalance = await ustn.balanceOf(accounts[0]);
        const value = web3.utils.toWei("1", "ether");
        await ustn.mint({ from: accounts[0], value: value });
        const valueInTokens = await ustn.mintRate(value);
        try {
        await ustn.mintBack(valueInTokens.add(web3.utils.toBN(1)), { from: accounts[0] });
        assert.fail("MintBack should have failed");
        } catch (err) {
        assert.ok(err.message.includes("overflow the mintbak threshold"), "MintBack error message incorrect");
        }
    });

    it("should allow burning tokens", async () => {
        const ustn = await USTN.deployed();
        const initialBalance = await ustn.balanceOf(accounts[1]);
        const amount = web3.utils.toBN(100);
        await ustn.burn(accounts[1], amount, { from: accounts[1] });
        const finalBalance = await ustn.balanceOf(accounts[1]);
        assert.equal(finalBalance.toString(), initialBalance.sub(amount).toString());
    });
});

```

use the following command:

```bash
npm run test
```

Make sure all tests pass before submitting a pull request.

## Other contract API details

[IERC20](D:\work\Treasurenet-contracts\fork\treasurenet-contracts\docs\ustn\IERC20\README.md)

[USTN](D:\work\Treasurenet-contracts\fork\treasurenet-contracts\docs\ustn\USTN\README.md)

[USTNAuction](D:\work\Treasurenet-contracts\fork\treasurenet-contracts\docs\ustn\USTNAuction\README.md)

[USTNFinance](D:\work\Treasurenet-contracts\fork\treasurenet-contracts\docs\ustn\USTNFinance\README.md)

[USTNInterface](D:\work\Treasurenet-contracts\fork\treasurenet-contracts\docs\ustn\USTNInterface\README.md)