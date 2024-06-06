# gravity

The Gravity contract is basically a multisig with a few tweaks. Even though it is designed to be used with a consensus process on Tendermint, the Gravity contract itself encodes nothing about this consensus process. There are three main operations- updateValset, submitBatch, and sendToCosmos. 

- updateValset updates the signers on the multisig, and their relative powers. This mirrors the validator set on the Tendermint chain, so that all the Tendermint validators are signers, in proportion to their staking power on the Tendermint chain. An updateValset transaction must be signed by 2/3's of the current valset to be accepted.
- submitBatch is used to submit a batch of transactions unlocking and transferring tokens to Ethereum addresses. It is used to send tokens from Treasurenet to Ethereum. The batch must be signed by 2/3's of the current valset.
- sendToCosmos is used to send tokens onto the Tendermint chain. It simply locks the tokens in the contract and emits an event which is picked up by the Tendermint validators.

## Table of Contents

- [Installation](#installation)
- [Defining the features](#Defining the features)
- [Detailed description of function](#Detailed description of function)
- [Detailed description of event](#Detailed description of event)
- [Contributing](#contributing)
- [Code of Conduct](#code-of-conduct)
- [License](#license)
- [Tests](#tests)

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
| `updateValset(ValsetArgs calldata _newValset,ValsetArgs calldata _currentValset,Signature[] calldata _sigs)` | This updates the valset by checking that the validators in the current valset have signed off on the new valset. The signatures supplied are the signatures of the current valset over the checkpoint hash generated from the new valset.<br />Anyone can call this function, but they must supply valid signatures of constant_powerThreshold of the current valset over the new valset. It takes three parameters:<br />`_newValset`: The new version of the validator set.<br />`_currentValset`: The current validators that approve the change.<br />`_sigs`: These are arrays of the parts of the current validator's signatures. |
| `submitBatch(ValsetArgs calldata _currentValset,Signature[] calldata _sigs,uint256[] calldata _amounts,address[] calldata _destinations,uint256[] calldata _fees,uint256 _batchNonce,address _tokenContract,uint256 _batchTimeout)` | SubmitBatch processes a batch of Treasurenet -> Ethereum transactions by sending the tokens in the transactions to the destination addresses. It is approved by the current Treasurenet validator set.<br />Anyone can call this function, but they must supply valid signatures of constant_powerThreshold of the current valset over the batch. It takes nine parameters:<br />`_currentValset`: The validators that approve the batch. <br />`_sigs`: These are arrays of the parts of the validators signatures<br />`_amounts`: Array of transfer amounts <br />`_destinations`: Array of destination addresses <br />`_fees`: Array of fee amounts <br />`_batchNonce`: Batch nonce <br />`_tokenContract`: Address of the ERC20 token contract<br />`_batchTimeout`: Timeout block height. |
| `sendToCosmos(address _tokenContract,string calldata _destination,uint256 _amount)` | This function facilitates the transfer of tokens to a Treasurenet network address. It takes three parameters:<br />`_tokenContract`: The address of the token contract. `_destination`: The Treasurenet network destination address. `_amount`: The amount of tokens to send.<br />The function first snapshots the current balance of the token contract held by the sender. It then attempts to transfer the specified amount of tokens from the sender to the contract. After the transfer. If the balance doesn't increase as expected, it reverts the transaction. |

## Detailed description of function

### **updateValset**

A valset consists of a list of validator's Ethereum addresses, their voting power, and a nonce for the entire valset. UpdateValset takes a new valset, the current valset, and the signatures of the current valset over the new valset. The valsets and the signatures are currently broken into separate arrays because it is not possible to pass arrays of structs into Solidity external functions. Because of this, UpdateValset first does a few checks to make sure that all the arrays that make up a valset are the same length.

Then, it checks the supplied current valset against the saved checkpoint. This requires some explanation. Because valsets contain over 100 validators, storing these all on the Ethereum blockchain each time would be quite expensive. Because of this, we only store a hash of the current valset, then let the caller supply the actual addresses, powers, and nonce of the valset. We call this hash the checkpoint. This is done with the function makeCheckpoint.

Once we are sure that the valset supplied by the caller is the correct one, we check that the new valset nonce is higher than current valset nonce. This ensures that old valsets cannot be submitted because their nonce is too low. Note: the only thing we check from the new valset is the nonce. The rest of the new valset is passed in the arguments to this method, but it is only used recreate the checkpoint of the new valset. If we didn't check the nonce, it would be possible to pass in the checkpoint directly.

Now, we make a checkpoint from the submitted new valset, using makeCheckpoint again. In addition to be used as a checkpoint later on, we first use it as a digest to check the current valset's signature over the new valset. We use checkValidatorSignatures to do this.

CheckValidatorSignatures takes a valset, an array of signatures, a hash, and a power threshold. It checks that the powers of all the validators that have signed the hash add up to the threshold. This is how we know that the new valset has been approved by at least 2/3s of the current valset. We iterate over the current valset and the array of signatures, which should be the same length. For each validator, we first check if the signature is all zeros. This signifies that it was not possible to obtain the signature of a given validator. If this is the case, we just skip to the next validator in the list. Since we only need 2/3s of the signatures, it is not required that every validator sign every time, and skipping them stops any validator from being able to stop the bridge.

If we have a signature for a validator, we verify it, throwing an error if there is something wrong. We also increment a cumulativePower counter with the validator's power. Once this is over the threshold, we break out of the loop, and the signatures have been verified! If the loop ends without the threshold being met, we throw an error. Because of the way we break out of the loop once the threshold has been met, if the valset is sorted by descending power, we can usually skip evaluating the majority of signatures. To take advantage of this gas savings, it is important that valsets be produced by the validators in descending order of power.

At this point, all of the checks are complete, and it's time to update the valset! This is a bit anticlimactic, since all we do is save the new checkpoint over the old one. An event is also emitted.

### **submitBatch**

This is how the bridge transfers tokens from addresses on the Tendermint chain to addresses on the Ethereum chain. The Treasurenet validators sign batches of transactions that are submitted to the contract. Each transaction has a destination address, an amount, a nonce, and a fee for whoever submitted the batch.

We start with some of the same checks that are done in UpdateValset- checking that the lengths of the arrays match up, and checking the supplied current valset against the checkpoint.

We also check the batches nonce against the state_lastBatchNonces mapping. This stores a nonce for each ERC20 handled by Gravity. The purpose of this nonce is to ensure that old batches cannot be submitted. It is also used on the Tendermint chain to clean up old batches that were never submitted and whose nonce is now too low to ever submit.

We check the current validator's signatures over the hash of the transaction batch, using the same method used above to check their signatures over a new valset.

Now we are ready to make the transfers. We iterate over all the transactions in the batch and do the transfers. We also add up the fees and transfer them to msg.sender.

### **sendToCosmos**

This is used to transfer tokens from an Ethereum address to a Tendermint address. It is extremely simple, because everything really happens on the Tendermint side. The transferred tokens are locked in the contract, then an event is emitted. The Tendermint validators see this event and mint tokens on the Tendermint side.

## Detailed description of Event

### **TransactionBatchExecutedEvent**

This contains information about a batch that has been successfully processed. It contains the batch nonce and the ERC20 token. The Tendermint chain can identify the batch from this information. It also contains the _eventNonce.

### **SendToCosmosEvent**

This is emitted every time someone sends tokens to the contract to be bridged to the Tendermint chain. It contains all information necessary to credit the tokens to the correct Treasurenet account, as well as the _eventNonce.

### **ValsetUpdatedEvent**

This is emitted whenever the valset is updated. It does not contain the _eventNonce, since it is never brought into the Tendermint state. It is used by relayers when they call submitBatch or updateValset, so that they can include the correct validator signatures with the transaction.

## Code of Conduct

We expect all contributors to adhere to our [Code of Conduct](link-to-code-of-conduct). Please read it to understand the expected behavior.

## License

This project is licensed under the MIT License. See the [LICENSE](link-to-license) file for details.

## Tests

To run the tests for this project, taking OIL as an example, it is as follows

```solidity
function testMakeCheckpoint(ValsetArgs calldata _valsetArgs, bytes32 _gravityId) external pure {
        makeCheckpoint(_valsetArgs, _gravityId);
    }

    function testCheckValidatorSignatures(
        ValsetArgs calldata _currentValset,
        Signature[] calldata _sigs,
        bytes32 _theHash,
        uint256 _powerThreshold
    ) external pure {
        checkValidatorSignatures(_currentValset, _sigs, _theHash, _powerThreshold);
    }
```

use the following command:

```bash
npm run test
```

Make sure all tests pass before submitting a pull request.