# TAT

The TAT contract is the TreasureNet ERC20 token implementation, featuring mintable, pausable, and burnable capabilities, along with staking functionality. The contract leverages several OpenZeppelin libraries for upgradeable features and governance integration.

## Table of Contents

- [Installation](#installation)
- [Defining the features](#Defining the features)
- [Contributing](#contributing)
- [Code of Conduct](#code-of-conduct)
- [License](#license)
- [Tests](#tests)
- [FAQ](#faq)

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

## Usage example

### Defining the features

| Function                                                     | Description                                                  |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| `mint(string memory _treasureKind,bytes32 _uniqueId,address to,uint256 amount)` | This function mints a specified amount of tokens to a given address. The function requires the caller to be authorized via the `onlyProductionDataContract(_treasureKind)` modifier, ensures the recipient address is non-zero, mints the specified amount of tokens to the given address, and emits an event recording the minting action. |
| `faucet(address user, uint256 amount)`                       | This function mints a specified amount of tokens to a given address. It takes two parameters: `user`: The address to which the tokens will be minted.<br />`amount`: The number of tokens to mint.<br />The function checks that the recipient address is non-zero and then mints the specified amount of tokens to that address. |
| `burn(string memory _treasureKind, uint256 tokens)`          | This function allows authorized contracts to burn a specified number of tokens from the caller's balance. It takes two parameters:<br />`_treasureKind`: A string representing the type of treasure.<br />`tokens`: The number of tokens to burn.<br />The function requires the caller to be authorized via the `onlyProductionDataContract(_treasureKind)` modifier and then burns the specified number of tokens from the caller's balance. |
| `pause()`                                                    | This function allows the contract owner to pause the contract. It is marked as public and can only be called by the owner (`onlyOwner`). When called, it invokes the `_pause()` function to pause the contract's activities. |
| `unpause()`                                                  | This function allows the contract owner to unpause the contract. It is marked as public and can only be called by the owner (`onlyOwner`). When called, it invokes the `_unpause()` function to resume the contract's activities. |
| `stake(address account, uint256 _amount)`                    | function allows a user to stake a specified amount of tokens. It takes two parameters:<br />  `account`: The address of the account that is staking tokens. <br />`_amount`: The amount of tokens to stake.<br />The function checks that the account has a sufficient balance to stake the specified amount. If the balance is sufficient, it calls `_stake(account, _amount)` to handle the staking logic and then burns the staked tokens by calling `_burn(account, _amount)`. |
| `withdraw(address account, uint256 _amount)`                 | The function checks that the account has enough staked tokens to cover the withdrawal amount. If the condition is met, it calls `_withdraw(account, _amount)` to handle the withdrawal logic and then mints the withdrawn tokens back to the account by calling `_mint(account, _amount)`. It also emits a `Withdraw` event indicating the withdrawal action. |

### Initializing the Contract

First, deploy the contract and then initialize it with the required parameters. For example:

```solidity
TAT tat = new TAT();
tat.initialize("OIL", "OIL", 0x03C6FcED478cBbC9a4FAB34eF9f40767739D1Ff7);
```

### Minting TAT

Mints new TAT tokens. Only the production data contract can call this function.

```solidity
tat.mint(
    "OIL", 
    0x4872484e4579694e575a65745956524879303873690000000000000000000000,
    0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db, 
    10
);
```

### Faucet

A temporary function to mint tokens to a specified address. This is typically used for testing purposes.

```solidity
tat.faucet(0x03C6FcED478cBbC9a4FAB34eF9f40767739D1Ff7, 100)
```

### Approve

approve of account amount is required before stake.

```solidity
tat.approve(0x03C6FcED478cBbC9a4FAB34eF9f40767739D1Ff7, 50)
```

### Staking TAT

Allows users to stake a specified amount of TAT tokens.

```solidity
tat.stake(0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db, 500);
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
const OilProducer = artifacts.require("OilProducer");
const OilData = artifacts.require("OilData");
const Governance = artifacts.require("Governance");
const TAT = artifacts.require("TAT");

const WELL = {
    NICKNAME: "Well1",
    UNIQUE_ID: "0x4872484e4579694e575a65745956524879303873690000000000000000000000",
    REQUEST_ID: "",
    ACCOUNT: "",
    API: 3000n,
    SULPHUR: 480n
}
const ASSETS = {
    KIND: "OIL",
    REQUEST_ID: "",
}

const PRODUCTION_DATA = [
    {DATE: "240101", VOLUME: 1000n, PRICE: 100n},
    {DATE: "240102", VOLUME: 2000n, PRICE: 200n},
]

const TRUSTED_PRODUCTION_DATA = {
    MONTH: "2401", VOLUME: 2500n
}

const EXPENSE_AMOUNT = BigInt(10 * 1e18);

const TAT_THRESHOLD = web3.utils.toBN(1 * 1e18);

contract("tat", async (accounts) => {

    it("Add oil producers and modify status.", async () => {
        const oilProducer = await OilProducer.deployed();
        
        WELL.ACCOUNT = accounts[2];

        const _producer = [WELL.NICKNAME, WELL.ACCOUNT, WELL.API.toString(), WELL.SULPHUR.toString(), '']
        const _uniqueId = WELL.UNIQUE_ID;

        /* Send the transaction and call the Add Producer function of the contract */
        const stepAddProducer = await oilProducer.addProducer(_uniqueId, _producer, {from: WELL.ACCOUNT});

        for (let i = 0; i < stepAddProducer.logs.length; i++) {
            if (stepAddProducer.logs[i].event === "AddProducer") {
                const eventArgs = stepAddProducer.logs[i].args;
                assert.equal(eventArgs.uniqueId, _uniqueId);
                assert.deepEqual([eventArgs.producer.nickname, eventArgs.producer.owner, eventArgs.producer.API, eventArgs.producer.sulphur, eventArgs.producer.account], _producer);
            }
        }

        const _newStatus = 1;
        /* Send the transaction and call the Set Producer Status function of the contract */
        const stepSetProducerStatus = await oilProducer.setProducerStatus(_uniqueId, _newStatus, {from: accounts[0]});

        for (let i = 0; i < stepSetProducerStatus.logs.length; i++) {
            if (stepSetProducerStatus.logs[i].event === "SetProducerStatus") {
                const eventArgs = stepSetProducerStatus.logs[i].args;
                assert.equal(eventArgs.uniqueId, _uniqueId);
                assert.equal(eventArgs.status, _newStatus.toString());
                WELL.REQUEST_ID = eventArgs.requestId;
            }
        }

        /* Call the getProducer function of the contract */
        const resultProducer = await oilProducer.getProducer.call(_uniqueId);

        assert.equal(resultProducer[0].toNumber(), 1);
        assert.deepEqual([resultProducer[1].nickname, resultProducer[1].owner, resultProducer[1].API, resultProducer[1].sulphur, resultProducer[1].account], _producer);
    })

    it("deposit expense", async () => {
        const oilData = await OilData.deployed();

        await oilData.prepay({from: WELL.ACCOUNT, value: EXPENSE_AMOUNT.toString()});
    })

    it("register asset value request", async () => {
        const oilData = await OilData.deployed();

        await oilData.registerAssetValueRequest({from: accounts[0]});
    })

    for (let i = 0; i < PRODUCTION_DATA.length; i++) {
        it("send Asset Price(" + PRODUCTION_DATA[i].DATE + ")", async () => {
            const oilData = await OilData.deployed();

            /* Data */
            const _date = PRODUCTION_DATA[i].DATE;
            const _assetPrice = PRODUCTION_DATA[i].PRICE;

            await oilData.receiveAssetValue(ASSETS.REQUEST_ID, _date, _assetPrice.toString(), {from: accounts[0]});

            /* query price */
            const resultPrice = await oilData.getAssetValue.call(_date);
            assert.equal(resultPrice.toNumber(), _assetPrice);
        })
        it("send production data(" + PRODUCTION_DATA[i].DATE + ")", async () => {
            const oilData = await OilData.deployed();

            /* Data */
            const _volume = PRODUCTION_DATA[i].VOLUME;
            const _date = PRODUCTION_DATA[i].DATE;
            const _month = PRODUCTION_DATA[i].DATE.substring(0, 4);
            const _productionData = [WELL.UNIQUE_ID, 0, WELL.ACCOUNT, _volume.toString(), 0, _date, _month, '', 0, 0, 0];

            await oilData.setProductionData(WELL.UNIQUE_ID, _productionData, {from: WELL.ACCOUNT})
        })
    }

    it("set trusted production data", async () => {
        const oilData = await OilData.deployed();

        const _volume = TRUSTED_PRODUCTION_DATA.VOLUME;
        const _month = TRUSTED_PRODUCTION_DATA.MONTH;
        const _productionData = [WELL.UNIQUE_ID, 0, WELL.ACCOUNT, _volume.toString(), 0, 0, _month, '', 0, 0, 0];

        await oilData.receiveTrustedProductionData(WELL.REQUEST_ID, WELL.UNIQUE_ID, _productionData, {from: accounts[0]});
    })

    it("clearing", async () => {
        const oilData = await OilData.deployed();
        const tat = await TAT.deployed();

        /* Data */
        const _month = TRUSTED_PRODUCTION_DATA.MONTH;

        /* Query TAT Balance */
        let tatBalance_before = await tat.balanceOf(WELL.ACCOUNT);
        tatBalance_before = tatBalance_before.toNumber();

        /* Calculate Discount */
        let discount = 9000n
        if (WELL.API > 3110n && WELL.SULPHUR >= 500n) discount = 8500n;
        if (WELL.API <= 3110n && WELL.SULPHUR < 500n) discount = 8000n;
        if (WELL.API <= 3110n && WELL.SULPHUR >= 500n) discount = 7500n;

        /* Calculate total minting amount and total production */
        let _pAmount = 0n;
        let _pVolume = 0n;
        for (let i = 0; i < PRODUCTION_DATA.length; i++) {
            const singleAmount = PRODUCTION_DATA[i].VOLUME * PRODUCTION_DATA[i].PRICE * discount * BigInt(1e18) / BigInt(1e12);
            _pAmount = _pAmount + singleAmount;
            _pVolume = _pVolume + PRODUCTION_DATA[i].VOLUME;
        }

        let _trustedVolume = TRUSTED_PRODUCTION_DATA.VOLUME

        const _deviation = (_pVolume - _trustedVolume) * 100n * 100n / _trustedVolume;

        /* Corrected total production and minting amount */
        let _amount = _pAmount;
        let _volume = _pVolume;
        if (_pVolume > _trustedVolume) {
            _amount = _amount * _trustedVolume / _volume;
            _volume = _trustedVolume;
        }

        /* Calculate expense */
        let _expense = 0n;
        if (_deviation > 1000n && _deviation < 3000n) {
            _expense = _amount * _deviation * 100n / 100000000n
        }
        if (_deviation >= 3000n) {
            _expense = _amount * 10000n * 100n / 100000000n
        }

        /* compare production data */
        const resultProductionData = await oilData.getProductionData.call(WELL.UNIQUE_ID, _month);
        assert.equal(resultProductionData.uniqueId, WELL.UNIQUE_ID);
        assert.equal(resultProductionData.month, _month.toString());
        assert.equal(resultProductionData.price, _pAmount.toString());
        assert.equal(resultProductionData.amount, _pVolume.toString());

        /* Clearing */
        await oilData.clearing(WELL.UNIQUE_ID, _month, {from: WELL.ACCOUNT});

        /* Get Expense balance */
        const resultExpense = await oilData.marginOf.call(WELL.ACCOUNT);
        assert.equal(resultExpense[0].toString(), (EXPENSE_AMOUNT - _expense).toString());

        /* Query TAT Balance */
        let tatBalance_after = await tat.balanceOf(WELL.ACCOUNT);
        tatBalance_after = web3.utils.toBN(tatBalance_after);

        await tat.mint(ASSETS.KIND, WELL.UNIQUE_ID, WELL.ACCOUNT, 100, { from: accounts[0] });
    })
    
    it("Should not mint TAT tokens by non-production data contract", async () => {
        const tat = await TAT.deployed()
        const amount = 10;

        try {
        await tat.mint(ASSETS.KIND, WELL.UNIQUE_ID, WELL.ACCOUNT, amount, { from: accounts[3] });
        assert(false, "Minting TAT tokens by non-production data contract should fail");
        } catch (error) {
        assert(error.message.includes("revert"), "Unexpected error: " + error);
        }
    });

    it("Should return correct bidder list", async () => {
        const bid = await Bid.deployed();
        const amount1 = web3.utils.toBN(2000);
        const amount2 = web3.utils.toBN(3000);
        await bid.bidTAT(amount1, { from: WELL.ACCOUNT });
        await bid.bidTAT(amount2, { from: accounts[1] });

        const [bidders, totalBid, startBlock] = await bid.bidderList();
        assert.equal(bidders.length, 2);
        assert.equal(bidders[0].bider, WELL.ACCOUNT);
        assert.equal(bidders[0].amount.toString(), amount1.toString());
        assert.equal(bidders[1].bider, accounts[1]);
        assert.equal(bidders[1].amount.toString(), amount2.toString());
        assert.equal(totalBid.toString(), amount1.add(amount2).toString());
        assert.equal(startBlock.toNumber(), 0);
    });

    it("should burn TAT tokens", async () => {
        const tat = await TAT.deployed();
        const amount = web3.utils.toBN(web3.utils.toWei('1', 'ether'));
    
        let tatBalance_before = await tat.balanceOf(WELL.ACCOUNT);
        tatBalance_before = web3.utils.toBN(tatBalance_before);
    
        // Assume faucet function exists to distribute tokens for testing
        await tat.faucet(WELL.ACCOUNT, web3.utils.toWei('5', 'ether'), { from: accounts[0] });
        let balance = await tat.balanceOf(WELL.ACCOUNT);
        balance = web3.utils.toBN(balance);
    
        await tat.burn(amount, { from: WELL.ACCOUNT });
    
        let tatBalance_after = await tat.balanceOf(WELL.ACCOUNT);
        tatBalance_after = web3.utils.toBN(tatBalance_after);
    
        assert(tatBalance_after.eq(tatBalance_before.add(web3.utils.toBN(web3.utils.toWei('5', 'ether'))).sub(amount)), "TAT tokens were not burned correctly");
    });

    it("should pause and unpause token transfers", async () => {
        const tat = await TAT.deployed();
        await tat.pause({from: accounts[0]});
        assert(await tat.paused(), "Token transfers were not paused");

        await tat.unpause({from: accounts[0]});
        assert(!(await tat.paused()), "Token transfers were not unpaused");
    });

    it("should stake and withdraw TAT tokens", async () => {
        const tat = await TAT.deployed();
        const amount = web3.utils.toBN(web3.utils.toWei('10', 'ether'));
    
        // transfer sufficient TAT balance to WELL.ACCOUNT users
        await tat.faucet(WELL.ACCOUNT, web3.utils.toWei('20', 'ether'), { from: accounts[1] });
    
        // check WELL Is the TAT balance of the ACCOUNT user sufficient
        let tatBalance = await tat.balanceOf(WELL.ACCOUNT);
        tatBalance = web3.utils.toBN(tatBalance);
        assert(tatBalance.gte(amount), "Insufficient TAT balance for staking");
    
        // authorization contract from WELL ACCOUNT deducts TAT tokens
        await tat.approve(tat.address, amount, { from: WELL.ACCOUNT });
    
        try {
            // use appropriate account addresses for calling
            await tat.stake(WELL.ACCOUNT, amount, { from: WELL.ACCOUNT });
        } catch (error) {
            console.error("Staking error:", error);
            assert.fail("Unexpected error: " + error);
        }
    
        const stakeAfterStake = await tat.stakeOf(WELL.ACCOUNT);
        assert(stakeAfterStake.eq(amount), "Staking TAT tokens failed");
    
        // recalculate balance before extraction
        let tatBalance_before = await tat.balanceOf(WELL.ACCOUNT);
        tatBalance_before = web3.utils.toBN(tatBalance_before);
    
        // ensure that no more than the pledged quantity can be extracted
        try {
            await tat.withdraw(WELL.ACCOUNT, amount.add(web3.utils.toBN(1)));
            assert.fail("Withdrawing more than staked should fail");
        } catch (error) {
            assert(error.message.includes("revert"), "Unexpected error: " + error);
            console.log("Expected revert on over-withdrawal");
        }
    
        // normal extraction
        await tat.withdraw(WELL.ACCOUNT, amount);
    
        const tatBalance_after = await tat.balanceOf(WELL.ACCOUNT);
        assert(tatBalance_after.eq(tatBalance_before), "Withdrawing TAT tokens failed");
    });

    it("should revert stake if staked amount exceeds balance", async () => {
        const tat = await TAT.deployed();
        const amount = 10000;
    
        try {
            await tat.stake(WELL.ACCOUNT, amount, {from: WELL.ACCOUNT});
            assert(false, "Staking more TAT tokens than balance should revert");
        } catch (error) {
            assert(error.message.includes("revert"), "Unexpected error: " + error);
        }
    });

    it("should revert withdraw if withdrawn amount exceeds staked amount", async () => {
        const tat = await TAT.deployed();
        const amount = 10000;

        await tat.stake(WELL.ACCOUNT, amount);
    
        try {
            await tat.withdraw(WELL.ACCOUNT, amount, {from: WELL.ACCOUNT});
            assert(false, "Withdrawing more TAT tokens than staked should revert");
        } catch (error) {
            assert(error.message.includes("revert"), "Unexpected error: " + error);
        }
    });
})
```

use the following command:

```bash
npm run test
```

Make sure all tests pass before submitting a pull request.

## FAQ

### What is staking in the TAT token contract?

Staking allows users to lock their TAT tokens in the contract in exchange for rewards or other benefits within the TreasureNet ecosystem.

