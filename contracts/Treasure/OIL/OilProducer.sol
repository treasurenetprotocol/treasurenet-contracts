// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "../Producer.sol";
import "../interfaces/IProductionData.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/Timers.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract OilProducer is Producer {
    function initialize(
        address _mulSigContract,
        address _roleContract,
        string memory _treasureKind,
        address _productionDataContract,
        string[] memory _dappNames,
        address[] memory _payees
    ) public initializer {
        __ProducerInitialize(
            _mulSigContract,
            _roleContract,
            _treasureKind,
            _productionDataContract,
            _dappNames,
            _payees
        );
    }

    function _beforeAddProducer(bytes32 _uniqueId, ProducerCore memory _producer)
        internal
        override
    {
        super._beforeAddProducer(_uniqueId, _producer);

        require(_producer.owner != address(0), "zero producer owner address");
        require(keccak256(bytes(_producer.nickname)) != keccak256(bytes("")), "empty nickname");
        require(_producer.API != 0 && _producer.sulphur != 0, "API & sulphur cant be zero");

        // initialize `Share`
        _setOwner(_uniqueId, _producer.owner);
    }

    function _afterAddProducer(bytes32 _uniqueId) internal override {
        super._afterAddProducer(_uniqueId);
    }
}
