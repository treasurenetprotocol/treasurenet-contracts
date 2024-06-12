# Governance

The governance contract used to manage and coordinate the production and data management of various assets (such as oil,  gas, etc.) on the platform. This contract adopts OpenZeppelin's upgradable contract module, ensuring that the contract can be seamlessly upgraded in the future to adapt to constantly changing business needs.

The main functions of this governance contract include:

- Define and manage multiple types of assets (called Treasure).

- Maintain production management contracts and production data management contracts for assets.
- Add new asset types through a multi signature mechanism.
- Role based access control and permission management.

## Table of Contents

- [Installation](#installation)
- [Defining the features](#Defining the features)
- [Contributing](#contributing)
- [Code of Conduct](#code-of-conduct)
- [License](#license)
- [Tests](#tests)
- [Other contract API details](#Other contract API details)

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

| Function                                                     | Description                                                  |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| `addTreasure(string memory _treasureType,address _producer,address _productionData)` | Returns the addresses of the producer and production data contracts for a given treasure type.<br />`_treasureType`: Name of the asset.<br />`_producer`: Address of the producer contract.<br />`_productionData`: Address of the production data contract. |
| `getTreasureByKind(string memory _treasureType)`             | Returns the addresses of the producer and production data contracts for a given treasure type.<br />`_treasureType`: Name of the asset.<br />`address`: Address of the producer contract.<br />`address`: Address of the production data contract. |

### Initializing the Contract

First, deploy the contract and then initialize it with the required parameters. For example:

```solidity
Governance governance = new Governance();
governance.initialize(
	0x51c82973094FA6F23739D87a75B4B86Bf8034a7b,
    0x583031D1113aD414F02576BD6afaBfb302140225,
    0x1bB5bf909d1200fb4730d899BAd7Ab0aE8487B0b,
    0x5c4B3fC5B79c6cfeD886bc8BD0b6Fd72DA4165CF,
    ["OIL", "GAS"],
    [0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db, 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB],
    [0x617F2E2fD72FD9D5503197092aC168c91465E7f2, 0x17F6AD8Ef982297579C203069C1DbfFE4348c372],
);
```

### Add Treasure

Triggered when a new asset type is added, record the asset type, production management contract address, and production data management contract address.

```solidity
governance.addTreasure(
    "OIL", 
    0x4872484e4579694e575a65745956524879303873690000000000000000000000,
    0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db, 
    10
);
```

### get Treasure By Kind

A temporary function to mint tokens to a specified address. This is typically used for testing purposes.

```solidity
governance.getTreasureByKind("OIL");
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
const Governance = artifacts.require("Governance");
const ProducerContract = artifacts.require("OilProducer");
const ProductionDataContract = artifacts.require("OilData");
const MulSig = artifacts.require("MulSig");
const Roles = artifacts.require("Roles");

contract("Governance", async (accounts) => {
  const daoAddress = accounts[0];
  const mulSigAccount = accounts[1];

  let governance;

  before(async () => {
      governance = await Governance.deployed();
  });
  
  it("should initialize correctly", async () => {
      const roles = await Roles.deployed();
      const parameterInfoAddress = accounts[2];
      await governance.initialize(
          daoAddress,
          mulSigAccount,
          roles.address,
          parameterInfoAddress,
          ["OIL", "GAS"],
          [accounts[3], accounts[4]],
          [accounts[5], accounts[6]],
      );
  });

  it("should add a new treasure", async () => {
      const treasureType = "GOLD";
      const producerContract = accounts[7];
      const productionDataContract = accounts[8];
  
      const stepAddTreasure = await governance.addTreasure(
          treasureType,
          producerContract,
          productionDataContract,
          { from: accounts[1] }
      );

      for (let i = 0; i < stepAddTreasure.logs.length; i++) {
          if (stepAddTreasure.logs[i].event === "AddTreasure") {
              const eventArgs = stepAddTreasure.logs[i].args;
              assert.equal(eventArgs.treasureType, treasureType, "Incorrect treasureType emitted");
              assert.equal(eventArgs.producerContract, producerContract, "Incorrect producerContract emitted");
              assert.equal(eventArgs.produceDataContract, productionDataContract, "Incorrect productionDataContract emitted");
          }
      }

      await governance.getTreasureByKind(treasureType);
      
  });
});
```

use the following command:

```bash
npm run test
```

Make sure all tests pass before submitting a pull request.

## Other contract API details

[governance](D:\work\Treasurenet-contracts\fork\treasurenet-contracts\docs\governance\governance\README.md)

[IGovernance](D:\work\Treasurenet-contracts\fork\treasurenet-contracts\docs\governance\IGovernance\README.md)

[IParameterInfo](D:\work\Treasurenet-contracts\fork\treasurenet-contracts\docs\governance\IParameterInfo\README.md)

[IRoles](D:\work\Treasurenet-contracts\fork\treasurenet-contracts\docs\governance\IRoles\README.md)

[mulsig](D:\work\Treasurenet-contracts\fork\treasurenet-contracts\docs\governance\mulsig\README.md)

[parameterInfo](D:\work\Treasurenet-contracts\fork\treasurenet-contracts\docs\governance\parameterInfo\README.md)

[roles](D:\work\Treasurenet-contracts\fork\treasurenet-contracts\docs\governance\roles\README.md)