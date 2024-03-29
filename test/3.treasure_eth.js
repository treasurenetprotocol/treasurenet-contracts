/**
 * Create with contracts
 * Author: ChrisChiu
 * Date: 2024/3/29
 * Desc
 */
const EthProducer = artifacts.require("EthProducer");
const EthData = artifacts.require("EthData");
const TAT = artifacts.require("TAT");

const WELL = {
    NICKNAME: 'Treasure-Eth',
    UNIQUE_ID: "0x4872484e4579694e575a65745956524879303873690000000000000000000002",
    MINTING_ACCOUNT:"0xF13cd65b2A8E8Cd433249Ca08083ad683b0d29e3",
    REQUEST_ID: "",
    ACCOUNT: "",
}

const ASSETS = {
    KIND: "ETH",
    REQUEST_ID: "",
}

const PRODUCTION_DATA = {
    AMOUNT:1000n,
    PRICE:10n,
    BLOCKNUMBER:180,
    BLOCKREWARD:100
}
contract("Treasure-Eth", async (accounts) => {

    it("Add eth producers and modify status.", async () => {
        const ethProducer = await EthProducer.deployed();

        WELL.ACCOUNT = accounts[3];

        const _producer = [WELL.NICKNAME, WELL.ACCOUNT, "0", "0", WELL.MINTING_ACCOUNT]
        const _uniqueId = WELL.UNIQUE_ID;
        const stepAddProducer = await ethProducer.addProducer(_uniqueId, _producer, {from: WELL.ACCOUNT});

        for (let i = 0; i < stepAddProducer.logs.length; i++) {
            if (stepAddProducer.logs[i].event === "AddProducer") {
                const eventArgs = stepAddProducer.logs[i].args;
                assert.equal(eventArgs.uniqueId, _uniqueId);
                assert.deepEqual([eventArgs.producer.nickname, eventArgs.producer.owner, eventArgs.producer.API, eventArgs.producer.sulphur, eventArgs.producer.account], _producer);
            }
        }

        const _newStatus = 1;
        /* Send the transaction and call the Set Producer Status function of the contract */
        const stepSetProducerStatus = await ethProducer.setProducerStatus(_uniqueId, _newStatus, {from: accounts[0]});

        for (let i = 0; i < stepSetProducerStatus.logs.length; i++) {
            if (stepSetProducerStatus.logs[i].event === "SetProducerStatus") {
                const eventArgs = stepSetProducerStatus.logs[i].args;
                assert.equal(eventArgs.uniqueId, _uniqueId);
                assert.equal(eventArgs.status, _newStatus.toString());
                WELL.REQUEST_ID = eventArgs.requestId;
            }
        }

        /* Call the getProducer function of the contract */
        const resultProducer = await ethProducer.getProducer.call(_uniqueId);

        assert.equal(resultProducer[0].toNumber(), _newStatus);
        assert.deepEqual([resultProducer[1].nickname, resultProducer[1].owner, resultProducer[1].API, resultProducer[1].sulphur, resultProducer[1].account], _producer);

    })

    it("register asset value request", async () => {
        const ethData = await EthData.deployed();

        const stepRegisterAssetValueRequest = await ethData.registerAssetValueRequest({from: accounts[0]});

        /* Event test */
        for (let i = 0; i < stepRegisterAssetValueRequest.logs.length; i++) {
            if (stepRegisterAssetValueRequest.logs[i].event === "RegisterAssetValueRequest") {
                const eventArgs = stepRegisterAssetValueRequest.logs[i].args;
                assert.equal(eventArgs.kind, ASSETS.KIND);
                ASSETS.REQUEST_ID = eventArgs.requestid;
            }
        }
    })

    it("set trusted production data", async () => {
        const ethData = await EthData.deployed();

        const _productionData = [WELL.UNIQUE_ID, 0, WELL.ACCOUNT, PRODUCTION_DATA.AMOUNT.toString() , PRODUCTION_DATA.PRICE.toString(), 0, 0, WELL.MINTING_ACCOUNT, PRODUCTION_DATA.BLOCKNUMBER.toString(), PRODUCTION_DATA.BLOCKREWARD.toString(), 0];

        const stepReceiveTrustedProductionData = await ethData.receiveTrustedProductionData(WELL.REQUEST_ID, WELL.UNIQUE_ID, _productionData, {from: accounts[0]});

        /* Event test */
        for(let i = 0; i < stepReceiveTrustedProductionData.logs.length; i++){
            if(stepReceiveTrustedProductionData.logs[i].event === "TrustedProductionData"){
                const eventArgs = stepReceiveTrustedProductionData.logs[i].args;
                assert.equal(eventArgs.treasureKind, ASSETS.KIND);
                assert.equal(eventArgs.uniqueId, WELL.UNIQUE_ID);
                assert.equal(eventArgs.amount, PRODUCTION_DATA.AMOUNT.toString());
            }
        }
    })

    it("clearing", async () => {
        const ethData = await EthData.deployed();
        const tat = await TAT.deployed();

        const _blocknumber = PRODUCTION_DATA.BLOCKNUMBER.toString();

        /* Query TAT Balance */
        let tatBalance_before = await tat.balanceOf(WELL.ACCOUNT);

        /* Clearing */
        const stepClearing = await ethData.clearing(WELL.UNIQUE_ID, _blocknumber, {from: WELL.ACCOUNT});

        /* Event test */
        for (let i = 0; i < stepClearing.logs.length; i++) {
            if (stepClearing.logs[i].event === 'ClearingReward') {
                const eventArgs = stepClearing.logs[i].args;
                assert.equal(eventArgs.treasureKind, ASSETS.KIND);
                assert.equal(eventArgs._uniqueId, WELL.UNIQUE_ID);
                assert.equal(eventArgs.rewardAmount,PRODUCTION_DATA.AMOUNT.toString());
            }
        }


        /* Query TAT Balance */
        let tatBalance_after = await tat.balanceOf(WELL.ACCOUNT);

        assert.equal(tatBalance_after - tatBalance_before, PRODUCTION_DATA.AMOUNT);

    })
})