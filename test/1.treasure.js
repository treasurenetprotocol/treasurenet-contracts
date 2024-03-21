/**
 * Create with contracts
 * Author: ChrisChiu
 * Date: 2023/04/01
 * Desc
 */
const OilProducer = artifacts.require("OilProducer");

const TEST_NICKNAME = "well1";
const TEST_UNIQUE_ID = "0x4872484e4579694e575a65745956524879303873690000000000000000000000";

contract("treasure", async (accounts) => {
    //console.dir(accounts);
    it("Add oil producers and modify status.", async () => {
        /* get oilProducerDeployed */
        const oilProducer = await OilProducer.deployed();

        /* Data */
        const _producer = [TEST_NICKNAME, accounts[1], 100, 100, '']
        const _uniqueId = TEST_UNIQUE_ID;

        /* Stringification of parameters */
        const __producer = _producer.map(i => typeof (i) === 'number' ? i.toString() : i);

        /* add producer */
        const stepAddProducer = await oilProducer.addProducer(_uniqueId, _producer, {from: accounts[1]});

        /* Event test */
        {
            const eventName = stepAddProducer.logs[0].event;
            const eventArgs = stepAddProducer.logs[0].args;
            assert.equal(eventName, "AddProducer");
            assert.equal(eventArgs.uniqueId, _uniqueId);
            assert.deepEqual([eventArgs.producer.nickname, eventArgs.producer.owner, eventArgs.producer.API, eventArgs.producer.sulphur, eventArgs.producer.account], __producer);
        }
        /* set producer status */
        const _newStatus = 1;
        const stepSetProducerStatys = await oilProducer.setProducerStatus(_uniqueId, _newStatus, {from: accounts[0]});

        /* Event test */
        {
            const eventName = stepSetProducerStatys.logs[0].event;
            const eventArgs = stepSetProducerStatys.logs[0].args;
            assert.equal(eventName, "SetProducerStatus");
            assert.equal(eventArgs.uniqueId, _uniqueId);
            assert.equal(eventArgs.status, _newStatus.toString());
        }

        /* get producer */
        const resultProducer = await oilProducer.getProducer.call(_uniqueId);

        /* Query Producer test */
        assert.equal(resultProducer[0].toNumber(), 1);
        assert.deepEqual([resultProducer[1].nickname, resultProducer[1].owner, resultProducer[1].API, resultProducer[1].sulphur, resultProducer[1].account], __producer);
    })
})