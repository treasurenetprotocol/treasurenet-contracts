# AirDrop

The AirDrop smart contract is designed to facilitate the distribution of tokens to foundation members and VIP users in a controlled and structured manner. It includes mechanisms for claiming tokens based on roles, managing withdrawal stages, and updating VIP users and their respective token ratios through multi-signature proposals.

## Table of Contents
- [Installation](#installation)
- [Defining the features](#Defining the features)
- [Contributing](#contributing)
- [Code of Conduct](#code-of-conduct)
- [License](#license)
- [Tests](#tests)
- [FAQ](#faq)

## Installation

To install and set up the AirDrop smart contract for development, follow these steps:

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
| `deployedAt()`                                               | This public view function returns the timestamp at which the contract was deployed, as defined by `_startAt`. |
| `getRole(address account)`                                   | This function is a public view function that takes an address as a parameter and returns the role associated with that address. If the address equals `_foundation`, it returns `Role.FOUNDATION`. If the address exists in `_vips`, it returns `Role.VIP`. If neither of these conditions is true, it returns `Role.Unknown`. |
| `getVIPs()`                                                  | This function is a public view function that retrieves the VIP addresses along with their corresponding ratios. It requires the caller to have the role of Foundation Member (`onlyFM` modifier). It first initializes an array `ratios` with the same length as `_vipAccs`. Then, it iterates through `_vipAccs`, assigning each VIP's ratio to the corresponding index in the `ratios` array. Finally, it returns a tuple containing `_vipAccs` array and `ratios` array. |
| `getVIPInfo(address vip)`                                    | This function is a public view function that retrieves information about a specific VIP. |
| `remainedToVIPs()`                                           | This public view function simply returns the value of `_remainedToVips`, which likely represents the remaining tokens available to VIPs. |
| `claimable`()                                                | The `claimable()` function, a public view function, determines the claimable tokens and claim stage for the caller. It returns a tuple including the role of the caller, the amount of claimable tokens, the current claim stage, and additional information for Foundation members (claimed amount and stage). If the caller is the Foundation, it calculates the unclaimed amount and stage using `_foundationClaimable()`. Otherwise, for VIPs, it calculates the claimable amount and sets the stage to `Stage1` using `_vipClaimable(sender)`. |
| `claim`()                                                    | Claims the tokens for the caller.                            |
| `foundationWithdrawed`()                                     | This public view function, `foundationWithdrawed()`, returns the amount withdrawn by the Foundation for the current claim stage `Stage1`. It retrieves this value from the mapping `_toFoundation`, which likely tracks the amounts withdrawn by the Foundation for different claim stages. |
| `receiveIntermidiateFund`()                                  | The `receiveIntermidiateFund()` function is public and payable. It accepts funds and distributes them evenly across remaining months until the end of an airdrop. If the current month exceeds the designated end month, it takes no action. |
| `foundationClaimVIPs`()                                      | The `foundationClaimVIPs()` function is a public function accessible only by the Foundation. It ensures that the current month exceeds the total periods (typically a year or 12 months), and that there are remaining tokens available for VIPs. Then, it transfers all remaining tokens to the Foundation's address and emits an event to signify the claim. Finally, it resets the remaining tokens for VIPs to zero. |
| `propose(ProposalPurpose purpose,address[] memory vips,uint256[] memory ratios)` | The `propose()` function allows a user to create a proposal with specified purposes, VIP addresses, and their corresponding ratios. It ensures that the arrays of VIP addresses and ratios have the same length and that each VIP address is valid. The total ratio after the proposed changes must not exceed 100 million. After these validations, it generates a unique proposal ID, stores the proposal details, and emits an event to signify the proposal's submission. Finally, it returns the proposal ID. |
| `signTransaction(uint256 _proposalId)`                       | The `signTransaction()` function allows Foundation Managers or Board Directors to sign a proposal identified by its proposal ID. It verifies that the sender is either a Foundation Manager or a Board Director and that they haven't already signed the proposal. After a successful signature, it checks if the proposal has met the signature threshold. If the threshold is met, it sets the execution time (effective time) for the proposal. Events are emitted accordingly, and the function returns a boolean value indicating success. |
| `executeProposal(uint256 _proposalId)`                       | The `executeProposal()` function executes a proposal identified by its ID if it hasn't been executed already. It checks if the proposal meets the threshold requirement and if it's of type "ChangeVIP". If so, it updates the VIP ratios and records historical ratios. Finally, it marks the proposal as executed and emits an event signaling the execution. |

### Initializing the Contract

First, deploy the contract and then initialize it with the required parameters.

```solidity
address[] memory vips = 
[
0x17F6AD8Ef982297579C203069C1DbfFE4348c372, 
0x617F2E2fD72FD9D5503197092aC168c91465E7f2
];
uint256[] memory ratios = [50 * 1e6, 50 * 1e6];
address[] memory foundationManagers = 
[
0x1aE0EA34a72D944a8C7603FfB3eC30a6669E454C, 
0x03C6FcED478cBbC9a4FAB34eF9f40767739D1Ff7
];
address[] memory boardDirectors = 
[0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C, 
0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB, 
0x583031D1113aD414F02576BD6afaBfb302140225
];
AirDrop airDrop = new AirDrop();
airDrop.initialize(vips, ratios, foundationManagers, boardDirectors);
```

### Claiming Tokens

Foundation and VIP users can claim their tokens using the `claim` function.

```solidity
// Foundation claiming tokens
airDrop.claim({ from: foundationAddress });

// VIP claiming tokens
airDrop.claim({ from: vipAddress });
```

### Proposing Changes

Foundation managers or board directors can propose changes to VIP ratios.

```solidity
address[] memory newVIPs = [0x0A098Eda01Ce92ff4A4CCb7A4fFFb5A43EBC70DC];
uint256[] memory newRatios = [30 * 1e6];

uint256 proposalId = airDrop.propose(
    ProposalPurpose.ChangeVIP,
    newVIPs,
    newRatios
);
```

### Signing and Executing Proposals

Foundation managers or board directors can sign and execute proposals.

```solidity
// Signing a proposal
airDrop.signTransaction(proposalId, { from: fmOrBdAddress });

// Executing a proposal
airDrop.executeProposal(proposalId, { from: proposerAddress });
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

To run the tests for this project

```js
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
```

use the following command:

```bash
npm run test
```

Make sure all tests pass before submitting a pull request.

## FAQ

### What is the purpose of this contract?

The contract manages an airdrop of tokens to Foundation and VIP users, with features for managing multi-stage token releases and multi-signature proposals.

### How are the tokens distributed?

Tokens are distributed over time in multiple stages. The Foundation can claim tokens in two stages, while VIPs receive monthly airdrops.

### How do multi-signature proposals work?

Foundation managers and board directors can propose changes to VIP ratios. Proposals require multiple signatures and a timelock before execution.
