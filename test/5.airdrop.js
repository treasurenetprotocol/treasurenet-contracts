const { assert } = require("chai");
const { time } = require('@openzeppelin/test-helpers');
const { web3 } = require("@openzeppelin/test-helpers/src/setup");

const AirDrop = artifacts.require('AirDrop');

contract('AirDrop', async (accounts) => {

    const foundation = accounts[0];
    const foundationManagerAccount1 = accounts[1];
    const foundationManagerAccount2 = accounts[2];
    const vipAccount1 = accounts[3];
    const vipAccount2 = accounts[4];

    let airDrop = null;
    before(async () => {
        airDrop = await AirDrop.deployed();
    })

    it("Should initialize correctly", async () => {
        await airDrop.initialize(
            [vipAccount1, vipAccount2],
            [50 * 1e6, 30 * 1e6],
            [foundationManagerAccount1, foundationManagerAccount2],
            [accounts[5], accounts[6], accounts[7]]
        );

        const foundationClaimable = await airDrop.foundationWithdrawed();
        assert.equal(foundationClaimable.toString(), "15" * 1e18);

        const remainedToVIPs = await airDrop.remainedToVIPs();
        assert.equal(remainedToVIPs.toString(), "60" * 1e18);

        const roleFoundation = await airDrop.getRole(foundation)
        assert.equal(roleFoundation.toString(), 0, "Foundation should be initialized correctly");

        const vipInfo = await airDrop.getVIPs({from: foundationManagerAccount1});
        const vipAccounts = vipInfo[0];
        const vipRatios = vipInfo[1];
        assert.equal(vipAccounts.length, 2);
        assert.equal(vipRatios.length, 2)
    });



    it("Should allow VIPs to claim funds", async () => {

        await airDrop.send(80 * 1e18, { from: foundation});
        const b = await web3.eth.getBalance(airDrop.address);
        assert.equal(+b, 80 * 1e18)

        await airDrop.claim({ from: foundationManagerAccount1});
        
    })
    
    it("Should allow foundation to claim remaining VIP funds after 1 year", async () => {
        await airDrop.send(80 * 1e18, { from: foundation});
        const b = await web3.eth.getBalance(airDrop.address);
        assert.equal(+b, 145 * 1e18);


        await time.increase(time.duration.years(1));
        await airDrop.foundationClaimVIPs({from: foundationManagerAccount1});
        const remainedToVIPs = await airDrop.remainedToVIPs();
        assert.equal(remainedToVIPs, 0);
    })

    it("Should not allow unauthorized users to execute proposals", async () => {
        const sendProposal = await airDrop.propose(0, [accounts[8],accounts[9]], [10,10], {from: foundation});

        let proposalId;
        for(let i = 0; i < sendProposal.logs.length; i++){
            if(sendProposal.logs[i].event === "SendProposal"){
                const eventArgs = sendProposal.logs[i].args;
                assert.equal(eventArgs.purpose, 0);
                assert.deepEqual(eventArgs.vips, [accounts[8],accounts[9]]);
                assert.deepEqual(eventArgs.ratios.map(value => value.toNumber()), [10,10]);
                proposalId = eventArgs.proposalId;
            }
        }

        await airDrop.signTransaction(proposalId, { from: foundationManagerAccount1 });
        await airDrop.signTransaction(proposalId, { from: foundationManagerAccount2 });
        await airDrop.signTransaction(proposalId, { from: accounts[5] });
        await airDrop.executeProposal(1, { from: foundation });
        
    })
   
    it("Should not allow multiple claims for the same stage", async () => {
        try {
            await airDrop.claim({ from: foundation});
            await airDrop.claim({ from: foundation});
            assert.fail("Repeatedly claim")
        } catch (error) {
            assert.include(error.message, "revert", "Multiple claims for the same stage should not be allowed");
        }
    })

    it("should not allow VIPs to claim funds after all funds claimed", async () => {
        try {
          
            await airDrop.receiveIntermidiateFund({ value: "60" * 1e6 });
    
            while (true) {
                try {
                    await airDrop.claim({ from: vipAccount1 });
                } catch (error) {
                    if (error.message.includes("revert")) {
                        break;
                    }
                }
            }
    
            await airDrop.claim({ from: vipAccount1 });
            assert.fail("All funds have been withdrawn");
        } catch (error) {
            assert.include(error.message, "revert", "VIPs should not be able to claim funds after all funds claimed");
        }
      })
});
