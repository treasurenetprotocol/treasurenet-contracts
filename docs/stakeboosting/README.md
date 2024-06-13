## Stake Boosting(Bid)

The bid contract aims to manage and record the bidding process of TAT tokens. Users can participate in bidding by pledging TAT tokens and recording their bidding information within a specific block range.

The main functions of this stake contract include:

- Staking Management: Allow users to pledge TAT tokens to participate in bidding and record relevant information.
- Staking round: Each round of bidding lasts for a certain number of blocks (ROUND-BLOCK), and after exceeding this, it enters a new bidding round.
- Staking query: Provides a method to query the user's bidding status and amount, as well as the start block of the current bidding round and other information.

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

## Defining the features

| Function                                                   | Description                                                  |
| ---------------------------------------------------------- | ------------------------------------------------------------ |
| `isTATBider(address account)` -> bool                      | Checks if an account is a TAT bidder.<br />`account`:  Address of the account to check. <br />`bool`: `true` if the account is a TAT bidder, `false` otherwise. |
| `bidTAT(uint256 amount)` -> bool                           | Allows an account to bid TAT.<br />`amount`: Amount of TAT to bid. <br />`bool`: `true` if the bid was successful. |
| `roundStartBlock()` -> uint256                             | Gets the start block of the current round.<br />`uint256`: Start block of the current round. |
| `mybidAmount()` -> uint256                                 | Gets the amount of TAT a user has bid.<br />`uint256`: Amount of TAT the sender has bid |
| `bidderList()` -> (BiderList\[\] memory, uint256, uint256) | Gets the list of TAT bidders.<br />`BiderList[]`: Array of bidders with their details. <br />`uint256`: Total amount of TAT bid. <br />`uint256`: Start block of the current round. |

### Initializing the Contract

First, deploy the contract and then initialize it with the required parameters. For example:

```solidity
Bid bid = new Bid();
bid.initialize(0x0DCd2F752394c41875e259e00bb44fd505297caF);
```

### Is TAT bider

```solidity
bid.isTATBider(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2);
```

### bid TAT

```solidity
bid.bidTAT(100);
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
const { assert } = require("chai");

const OilProducer = artifacts.require("OilProducer");
const OilData = artifacts.require("OilData");
const Governance = artifacts.require("Governance");
const TAT = artifacts.require("TAT");
const Bid = artifacts.require("Bid")

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
        console.log(`Initial balance: ${tatBalance.toString()}`);
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
        console.log(`Stake after staking: ${stakeAfterStake.toString()}`);
        assert(stakeAfterStake.eq(amount), "Staking TAT tokens failed");
    
        // recalculate balance before extraction
        let tatBalance_before = await tat.balanceOf(WELL.ACCOUNT);
        tatBalance_before = web3.utils.toBN(tatBalance_before);
        console.log(`Balance before withdraw: ${tatBalance_before.toString()}`);
    
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
        console.log(`Balance after withdraw: ${tatBalance_after.toString()}`);
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
