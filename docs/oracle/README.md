# Oracle

Oracle contract serves as the core oracle system, implementing functionalities such as:

- Initiating/Canceling Oracle requests
- Uploading Oracle data (Role: Feeder)

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
| `createOracleRequest(address _callbackAddress,bytes4 _callbackFunctionId,uint256 _nonce)` | The `createOracleRequest` function generates a unique request ID for an oracle request. It takes in a callback address, a callback function ID, and a nonce as parameters. The function ensures the request ID is unique by hashing the sender's address and the nonce, then checks if this ID has already been used. If not, it stores a commitment hash composed of the callback address and function ID. Finally, it emits an `OracleRequest` event with the sender's address, the request ID, the callback address, and the callback function ID, and returns the request ID. |
| `cancelOracleRequest(bytes32 _requestId,address _callbackAddress,bytes4 _callbackFuncId)` | The cancelOracleRequest function is used to cancel an oracle request. It takes in a request ID, a callback address, and a callback function ID as parameters. |
| `setCurrencyValue(bytes32 _currencyKind,uint256 _currencyValue)` | The `setCurrencyValue` function sets the value of a specific currency type. It takes a currency identifier (`_currencyKind`) and the corresponding value (`_currencyValue`) as parameters. Only addresses with the `Feeder` role can call this function. |
| `getCurrencyValue(bytes32 _currencyKind)`                    | The `getCurrencyValue` function retrieves the value of a specific currency type. It takes a currency identifier (`_currencyKind`) as a parameter and returns the associated currency value. |

### Initializing the Contract

First, deploy the contract and then initialize it with the required parameters. For example:

```solidity
Oracle oracle = new Oracle();
oracle.initialize(0x7EF2e0048f5bAeDe046f6BF797943daF4ED8CB47);
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
const { assert } = require("chai");

const Oracle = artifacts.require("Oracle");
const Roles = artifacts.require("Roles");

contract('Oracle', (accounts) => {
    let oracle;
    let roles;

    before(async () => {
        roles = await Roles.new();  // Deploy a new instance of Roles
        oracle = await Oracle.new();  // Deploy a new instance of Oracle
    });

    it("should initialize correctly", async () => {
        await oracle.initialize(roles.address, { from: accounts[0] });

        // Assuming FEEDER is a constant in your Oracle contract
        const FEEDER = await oracle.FEEDER();
        assert.equal(FEEDER.toString(), web3.utils.asciiToHex("FEEDER"));

        // Fetch the currency value
        const getCurrencyValue = await oracle.getCurrencyValue(web3.utils.asciiToHex("UNIT"));
        assert.equal(getCurrencyValue.toString(), "0");
    });

    it("should allow feeders to set currency values", async () => {
        const currencyKind = web3.utils.keccak256("USD");
        const currencyValue = 100;
    
        await oracle.setCurrencyValue(currencyKind, currencyValue, { from: feeder });
    
        const storedValue = await oracle.getCurrencyValue(currencyKind);
        assert.equal(storedValue, currencyValue);
      });
    
      it("should not allow non-feeders to set currency values", async () => {
        const currencyKind = web3.utils.keccak256("USD");
        const currencyValue = 100;
    
        await expectRevert(
          oracle.setCurrencyValue(currencyKind, currencyValue, { from: other }),
          "Only Feeder can push data"
        );
      });
    
      it("should create an Oracle request", async () => {
        const callbackAddress = other;
        const callbackFunctionId = web3.utils.keccak256("callback()").substring(0, 10); // First 4 bytes
        const nonce = 1;
    
        const requestId = await oracle.createOracleRequest(callbackAddress, callbackFunctionId, nonce, { from: owner });
    
        assert(requestId);
      });
    
      it("should cancel an Oracle request", async () => {
        const callbackAddress = other;
        const callbackFunctionId = web3.utils.keccak256("callback()").substring(0, 10); // First 4 bytes
        const nonce = 2;
    
        const requestId = await oracle.createOracleRequest(callbackAddress, callbackFunctionId, nonce, { from: owner });
    
        await oracle.cancelOracleRequest(requestId, callbackAddress, callbackFunctionId, { from: owner });
      });
});

```

use the following command:

```bash
npm run test
```

Make sure all tests pass before submitting a pull request.

## Other contract API details

[Oracle](D:\work\Treasurenet-contracts\fork\treasurenet-contracts\docs\oracle\oracle\README.md)

[IOracle](D:\work\Treasurenet-contracts\fork\treasurenet-contracts\docs\oracle\IOracle\README.md)

[oracleClient](D:\work\Treasurenet-contracts\fork\treasurenet-contracts\docs\oracle\oracleClient\README.md)

[simpleClient](D:\work\Treasurenet-contracts\fork\treasurenet-contracts\docs\oracle\simpleClient\README.md)