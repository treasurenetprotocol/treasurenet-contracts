/**
 * Create with contracts
 * Author: ChrisChiu
 * Date: 2023/04/01
 * Desc
 */
const OilProducer = artifacts.require("OilProducer");

contract("treasure", async (accounts) => {
    //console.dir(accounts);
    it("Add oil producers and modify status.", async () => {
        /* get oilProducerDeployed */
        const oilProducer = await OilProducer.deployed();

        /* Data */
        const _producer = ["well1", accounts[1], 100, 100, '']
        const _uniqueId = "0x4872484e4579694e575a65745956524879303873690000000000000000000000";

        /* add producer */
        await oilProducer.addProducer(_uniqueId, _producer, {from: accounts[1]});
        /* set producer status */
        await oilProducer.setProducerStatus(_uniqueId, 1, {from: accounts[0]});
        /* get producer */
        const p = await oilProducer.getProducer.call(_uniqueId);

        const resultStatus = p[0].toNumber();
        const resultProducer = p[1];
        assert.equal(resultStatus, 1);
        assert.deepEqual([resultProducer.nickname, resultProducer.owner, +resultProducer.API, +resultProducer.sulphur, resultProducer.account], _producer);
    })
})