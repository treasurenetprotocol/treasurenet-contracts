<p align="center">
  <a href="https://treasurenet.io">
    <img alt="treasurenetLogo" src="https://raw.githubusercontent.com/treasurenetprotocol/docs/feature/1.0.3/static/img/logo_tn_github.png" width="600" />
  </a>
</p>


# Treasurenet

Treasurenet proposes a solution for the critical lack of sustaining and tangible value in the crypto world. Our goal is the combine real world economic drivers and distributed ledger scalability. As a layer 1 protocol, TN will become a model for sustaining value in the fiat world and the digital world.

# Treasurenet Contracts

<a href="https://github.com/treasurenetprotocol/treasurenet-js-libs/blob/master/LICENSE"><img alt="License: Apache-2.0" src="https://img.shields.io/badge/license-Apache_2.0-blue" /></a>  <img alt="npm: v9.5.1" src="https://img.shields.io/badge/solc-0.8.10-yellow" />  ![Treasurenet CI](https://img.shields.io/badge/TreasureNet_CI-passing-brightgreen)  [![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)](code_of_conduct.md)

This contains almost all contracts officially developed and maintained by Treasurenet Foundation.

- [Installation](#installation)
- [Usage](#usage)
- [Contributing](#contributing)
- [Code of Conduct](#code-of-conduct)
- [License](#license)
- [Tests](#tests)
- [FAQ](#faq)
- [Acknowledgements](#acknowledgements)
- [Contact Information](#contact-information)

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

## Usage and Example

To run the tests for this project,use the following command:

### run a ganache test network

```shell
npm run ganache
```

### run tests

```shell
npm run test
```

Make sure all tests pass before submitting a pull request.

## Introduction and APIs

[module documentation](

## Contributing

We welcome contributions to the project! Please follow these steps to contribute:

1. Fork the repository.
2. Create a new branch (`git checkout -b feature-branch`).
3. Commit your changes (`git commit -am 'Add new feature'`).
4. Push to the branch (`git push origin feature-branch`).
5. Create a new Pull Request.

Please ensure your code adheres to our coding standards and includes relevant tests.

## Code of Conduct

We expect all contributors to adhere to our [Code of Conduct](code_of_conduct.md). Please read it to understand the expected behavior.

## License

This project is licensed under the Apache License 2.0 \- see the [LICENSE](LICENSE) file for details.

(https://github.com/treasurenetprotocol/treasurenet-js-libs/blob/master/LICENSE)

## FAQ

### What is a producer?

Producers are economic contributors in the real world, providing production records of physical or digital assets to Treasury for auditing and on chain recording.

### What is the purpose of this contract?

The contract manages an airdrop of tokens to Foundation and VIP users, with features for managing multi-stage token releases and multi-signature proposals.

### How are the tokens distributed?

Tokens are distributed over time in multiple stages. The Foundation can claim tokens in two stages, while VIPs receive monthly airdrops.

### How do multi-signature proposals work?

Foundation managers and board directors can propose changes to VIP ratios. Proposals require multiple signatures and a timelock before execution.

## Acknowledgements

We would like to thank the developers and contributors of OpenZeppelin for their excellent upgradable contract library.

## Contact Information

For questions or collaboration, please contact:

- **Name:** Treasurenet team
- **Email:** 
- **GitHub:** https://github.com/treasurenetprotocol/treasurenet-contracts

-----
_Treasurenet Foundation 2024_
