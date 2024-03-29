/**
 * Create with contracts
 * Author: ChrisChiu
 * Date: 2023/04/01
 * Desc
 */
const GasProducer = artifacts.require("GasProducer");
const GasData = artifacts.require("GasData");
const TAT = artifacts.require("TAT");

const WELL = {
    NICKNAME: "Well2",
    UNIQUE_ID: "0x4872484e4579694e575a65745956524879303873690000000000000000000001",
    REQUEST_ID: "",
    ACCOUNT: "",
    API: 0n,   //no used
    SULPHUR: 0n  //no used
}
const ASSETS = {
    KIND: "GAS",
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

contract("Treasure-Gas", async (accounts) => {

    it("Add gas producers and modify status.", async () => {
        const gasProducer = await GasProducer.deployed();


        WELL.ACCOUNT = accounts[2];

        const _producer = [WELL.NICKNAME, WELL.ACCOUNT, WELL.API.toString(), WELL.SULPHUR.toString(), '']
        const _uniqueId = WELL.UNIQUE_ID;

        /* Send the transaction and call the Add Producer function of the contract */
        const stepAddProducer = await gasProducer.addProducer(_uniqueId, _producer, {from: WELL.ACCOUNT});

        for (let i = 0; i < stepAddProducer.logs.length; i++) {
            if (stepAddProducer.logs[i].event === "AddProducer") {
                const eventArgs = stepAddProducer.logs[i].args;
                assert.equal(eventArgs.uniqueId, _uniqueId);
                assert.deepEqual([eventArgs.producer.nickname, eventArgs.producer.owner, eventArgs.producer.API, eventArgs.producer.sulphur, eventArgs.producer.account], _producer);
            }
        }

        const _newStatus = 1;
        /* Send the transaction and call the Set Producer Status function of the contract */
        const stepSetProducerStatus = await gasProducer.setProducerStatus(_uniqueId, _newStatus, {from: accounts[0]});

        for (let i = 0; i < stepSetProducerStatus.logs.length; i++) {
            if (stepSetProducerStatus.logs[i].event === "SetProducerStatus") {
                const eventArgs = stepSetProducerStatus.logs[i].args;
                assert.equal(eventArgs.uniqueId, _uniqueId);
                assert.equal(eventArgs.status, _newStatus.toString());
                WELL.REQUEST_ID = eventArgs.requestId;
            }
        }

        /* Call the getProducer function of the contract */
        const resultProducer = await gasProducer.getProducer.call(_uniqueId);

        assert.equal(resultProducer[0].toNumber(), 1);
        assert.deepEqual([resultProducer[1].nickname, resultProducer[1].owner, resultProducer[1].API, resultProducer[1].sulphur, resultProducer[1].account], _producer);
    })

    it("deposit expense", async () => {
        const gasData = await GasData.deployed();

        await gasData.prepay({from: WELL.ACCOUNT, value: EXPENSE_AMOUNT.toString()});
    })

    it("register asset value request", async () => {
        const gasData = await GasData.deployed();

        const stepRegisterAssetValueRequest = await gasData.registerAssetValueRequest({from: accounts[0]});

        /* Event test */
        for (let i = 0; i < stepRegisterAssetValueRequest.logs.length; i++) {
            if (stepRegisterAssetValueRequest.logs[i].event === "RegisterAssetValueRequest") {
                const eventArgs = stepRegisterAssetValueRequest.logs[i].args;
                assert.equal(eventArgs.kind, ASSETS.KIND);
                ASSETS.REQUEST_ID = eventArgs.requestid;
            }
        }
    })

    for (let i = 0; i < PRODUCTION_DATA.length; i++) {
        it("send Asset Price(" + PRODUCTION_DATA[i].DATE + ")", async () => {
            const gasData = await GasData.deployed();

            /* Data */
            const _date = PRODUCTION_DATA[i].DATE;
            const _assetPrice = PRODUCTION_DATA[i].PRICE;

            const stepReceiveAssetValue = await gasData.receiveAssetValue(ASSETS.REQUEST_ID, _date, _assetPrice.toString(), {from: accounts[0]});

            /* Event test */
            for (let j = 0; j < stepReceiveAssetValue.logs.length; j++) {
                if (stepReceiveAssetValue.logs[j].event === "ReceiveAssetValue") {
                    const eventArgs = stepReceiveAssetValue.logs[j].args;
                    assert.equal(eventArgs.treasureKind, ASSETS.KIND);
                    assert.equal(eventArgs.date, _date.toString());
                    assert.equal(eventArgs.value, _assetPrice.toString());
                }
            }

            /* query price */
            const resultPrice = await gasData.getAssetValue.call(_date);
            assert.equal(resultPrice.toNumber(), _assetPrice);
        })
        it("send production data(" + PRODUCTION_DATA[i].DATE + ")", async () => {
            const gasData = await GasData.deployed();

            /* Data */
            const _volume = PRODUCTION_DATA[i].VOLUME;
            const _date = PRODUCTION_DATA[i].DATE;
            const _month = PRODUCTION_DATA[i].DATE.substring(0, 4);
            const _productionData = [WELL.UNIQUE_ID, 0, WELL.ACCOUNT, _volume.toString(), 0, _date, _month, '', 0, 0, 0];


            const stepSetProductionData = await gasData.setProductionData(WELL.UNIQUE_ID, _productionData, {from: WELL.ACCOUNT})

            /* Event test */
            for(let i = 0; i < stepSetProductionData.logs.length; i++){
                if(stepSetProductionData.logs[i].event === "ProducerProductionData"){
                    const eventArgs = stepSetProductionData.logs[i].args;
                    assert.equal(eventArgs.treasureKind, ASSETS.KIND);
                    assert.equal(eventArgs.uniqueId, WELL.UNIQUE_ID);
                    assert.equal(eventArgs.month, _month.toString());
                    assert.equal(eventArgs.date, _date.toString());
                    assert.equal(eventArgs.amount, _volume.toString());
                }
            }
        })
    }

    it("set trusted production data", async () => {
        const gasData = await GasData.deployed();

        const _volume = TRUSTED_PRODUCTION_DATA.VOLUME;
        const _month = TRUSTED_PRODUCTION_DATA.MONTH;
        const _productionData = [WELL.UNIQUE_ID, 0, WELL.ACCOUNT, _volume.toString(), 0, 0, _month, '', 0, 0, 0];

        const stepReceiveTrustedProductionData = await gasData.receiveTrustedProductionData(WELL.REQUEST_ID, WELL.UNIQUE_ID, _productionData, {from: accounts[0]});

        /* Event test */
        for(let i = 0; i < stepReceiveTrustedProductionData.logs.length; i++){
            if(stepReceiveTrustedProductionData.logs[i].event === "TrustedProductionData"){
                const eventArgs = stepReceiveTrustedProductionData.logs[i].args;
                assert.equal(eventArgs.treasureKind, ASSETS.KIND);
                assert.equal(eventArgs.uniqueId, WELL.UNIQUE_ID);
                assert.equal(eventArgs.month, _month.toString());
                assert.equal(eventArgs.amount, _volume.toString());
            }
        }
    })

    it("clearing", async () => {
        const gasData = await GasData.deployed();
        const tat = await TAT.deployed();

        /* Data */
        const _month = TRUSTED_PRODUCTION_DATA.MONTH;

        /* Query TAT Balance */
        let tatBalance_before = await tat.balanceOf(WELL.ACCOUNT);
        tatBalance_before = tatBalance_before.toNumber();

        /* Calculate Discount */
        /*let discount = 9000n
        if (WELL.API > 3110n && WELL.SULPHUR >= 500n) discount = 8500n;
        if (WELL.API <= 3110n && WELL.SULPHUR < 500n) discount = 8000n;
        if (WELL.API <= 3110n && WELL.SULPHUR >= 500n) discount = 7500n;*/
        const discount = 10000n;  //No discounts on natural gas

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
        const resultProductionData = await gasData.getProductionData.call(WELL.UNIQUE_ID, _month);
        assert.equal(resultProductionData.uniqueId, WELL.UNIQUE_ID);
        assert.equal(resultProductionData.month, _month.toString());
        assert.equal(resultProductionData.price, _pAmount.toString());
        assert.equal(resultProductionData.amount, _pVolume.toString());

        /* Clearing */
        const stepClearing = await gasData.clearing(WELL.UNIQUE_ID, _month, {from: WELL.ACCOUNT});

        /* Event test */
        for (let i = 0; i < stepClearing.logs.length; i++) {
            if (stepClearing.logs[i].event === 'VerifiedProduction') {
                const eventArgs = stepClearing.logs[i].args;
                assert.equal(eventArgs._uniqueId, WELL.UNIQUE_ID);
                assert.equal(eventArgs.month, _month.toString());
                assert.equal(eventArgs.amount, _volume.toString());
            }
            if (stepClearing.logs[i].event === 'ClearingReward') {
                const eventArgs = stepClearing.logs[i].args;
                assert.equal(eventArgs.treasureKind, ASSETS.KIND);
                assert.equal(eventArgs._uniqueId, WELL.UNIQUE_ID);
                assert.equal(eventArgs._month, _month.toString());
                assert.equal(eventArgs.rewardAmount, _amount.toString());
            }
        }

        /* Get Expense balance */
        const resultExpense = await gasData.marginOf.call(WELL.ACCOUNT);
        assert.equal(resultExpense[0].toString(), (EXPENSE_AMOUNT - _expense).toString());

        /* Query TAT Balance */
        let tatBalance_after = await tat.balanceOf(WELL.ACCOUNT);
        tatBalance_after = tatBalance_after.toNumber();

        assert.equal(tatBalance_after - tatBalance_before, _amount);

        /* Withdraw remaining expense funds */
        await gasData.withdraw((EXPENSE_AMOUNT - _expense).toString(), {from: WELL.ACCOUNT});

        /* Output Results */
        console.log(`WELL ${WELL.UNIQUE_ID}: \n- DEVIATION: ${_deviation.toString()} \n- VOLUME: ${_volume.toString()} \n- AMOUNT: ${_amount.toString()} \n- EXPENSE: ${_expense.toString()} \n`)
    })
})