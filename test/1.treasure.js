const DAO = artifacts.require("DAO");
const OilProducer = artifacts.require("OilProducer");

contract("treasure", async () => {
    it("添加石油生产商并修改状态", async () => {
        /* get oilProducerDeployed */
        const oilProducer = await OilProducer.deployed();

        /* Data */
        const _producer = ["well1", "0x9bc3dE918a455E0f5FE741515FA98f1FB5130602", 100, 100, '']
        const _uniqueId = "0x4872484e4579694e575a65745956524879303873690000000000000000000000";

        /* add producer */
        await oilProducer.addProducer(_uniqueId, _producer);
        /* set producer status */
        await oilProducer.setProducerStatus(_uniqueId, 1);
        /* get producer */
        const p = await oilProducer.getProducer.call(_uniqueId);

        const resultStatus = p[0].toNumber();
        const resultProducer = p[1];
        assert.equal(resultStatus, 1);
        assert.equal([resultProducer.nickname, resultProducer.owner, +resultProducer.API, +resultProducer.sulphur, resultProducer.account], _producer);
    })
})