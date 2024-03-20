require('dotenv').config();

const DAO = artifacts.require("DAO");
const OilProducer = artifacts.require("OilProducer");
const OilData = artifacts.require("OilData");
const GasProducer = artifacts.require("GasProducer");
const GasData = artifacts.require("GasData");
const EthProducer = artifacts.require("EthProducer");
const EthData = artifacts.require("EthData");
const BtcProducer = artifacts.require("BtcProducer");
const BtcData = artifacts.require("BtcData");
const MulSig = artifacts.require("MulSig");
const Roles = artifacts.require("Roles");
const ParameterInfo = artifacts.require("ParameterInfo");
const Governance = artifacts.require("Governance");
const Oracle = artifacts.require("Oracle");
const TAT = artifacts.require("TAT");

const {deployProxy} = require('@openzeppelin/truffle-upgrades');

module.exports = async function (deployer, network, accounts) {
    try {
        if (process.env.ACTION === "upgrade") {
            /* TODO:更新 */
        }
        else {
            const dao = await deployProxy(DAO, ["DAO", 2, 10], {deployer});
            const oilProducer = await deployProxy(OilProducer, {initializer: false}, {deployer});
            const oilData = await deployProxy(OilData, {initializer: false}, {deployer});
            const gasProducer = await deployProxy(GasProducer, {initializer: false}, {deployer});
            const gasData = await deployProxy(GasData, {initializer: false}, {deployer});
            const ethProducer = await deployProxy(EthProducer, {initializer: false}, {deployer});
            const ethData = await deployProxy(EthData, {initializer: false}, {deployer});
            const btcProducer = await deployProxy(BtcProducer, {initializer: false}, {deployer});
            const btcData = await deployProxy(BtcData, {initializer: false}, {deployer});

            const mulSig = await deployProxy(MulSig, {initializer: false}, {deployer});
            const roles = await deployProxy(Roles, {initializer: false}, {deployer});
            const parameterInfo = await deployProxy(ParameterInfo, [mulSig.address], {deployer});
            const gov = await deployProxy(Governance, [
                dao.address,
                mulSig.address,
                roles.address,
                parameterInfo.address,
                ["OIL", "GAS", "ETH", "BTC"],
                [oilProducer.address, gasProducer.address, ethProducer.address, btcProducer.address],
                [oilData.address, gasData.address, ethData.address, btcData.address],
            ], {deployer});
            const oracle = await deployProxy(Oracle, [roles.address], {deployer});
            const mulSigInstance = await MulSig.deployed();
            await mulSigInstance.initialize(dao.address, gov.address, roles.address, parameterInfo.address, 2);
            const rolesInstance = await Roles.deployed();
            await rolesInstance.initialize(mulSig.address, [deployer.options.from], [deployer.options.from], [oracle.address, deployer.options.from])

            const tat = await deployProxy(TAT, ["TAT Token", "TAT", gov.address], {deployer});

            await oilProducer.initialize(mulSig.address, roles.address, "OIL", oilData.address, [], []);
            await oilData.initialize("OIL", oracle.address, roles.address, parameterInfo.address, oilProducer.address, tat.address);

            await gasProducer.initialize(mulSig.address, roles.address, "GAS", gasData.address, [], []);
            await gasData.initialize("GAS", oracle.address, roles.address, parameterInfo.address, gasProducer.address, tat.address);

            await ethProducer.initialize(mulSig.address, roles.address, "ETH", ethData.address, [], []);
            await ethData.initialize("ETH", oracle.address, roles.address, parameterInfo.address, ethProducer.address, tat.address);

            await btcProducer.initialize(mulSig.address, roles.address, "BTC", btcData.address, [], []);
            await btcData.initialize("BTC", oracle.address, roles.address, parameterInfo.address, btcProducer.address, tat.address);

        }

    } catch (e) {
        console.error(e)
    }
};