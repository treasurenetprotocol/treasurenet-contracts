// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "../interfaces/IProducer.sol";
import "../ProductionData.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract EthData is ProductionData {
    using Counters for Counters.Counter;

    event TrustedDigitalProductionData(
        string treasureKind,
        bytes32 uniqueId,
        uint256 blockNumber,
        uint256 blockReward,
        uint256 price,
        uint256 amount,
        string miner
    );

    function initialize(
        string memory _treasureKind,
        address _oracleContract,
        address _rolesContract,
        address _parameterInfoContract,
        address _producerContract,
        address _tatContract
    ) public initializer {
        __ProductionDataInitialize(
            _treasureKind,
            _oracleContract,
            _rolesContract,
            _parameterInfoContract,
            _producerContract,
            _tatContract
        );
    }

    function receiveTrustedProductionData(
        bytes32 _requestId,
        bytes32 _uniqueId,
        ProduceData memory _produceData
    ) external override onlyFeeder onlyWhenActive(_uniqueId) {
        require(
            _requestId == _requestIdsToPullTrustedData[_uniqueId],
            "invalid oracle request id,not for production data"
        );
        require(_produceData.blockNumber != 0, "production block number cant be zero");
        require(_produceData.blockReward != 0, "production block reward cant be zero");
        /*require(_produceData.miner != address(0), "production miner cant be zero");*/

        IProducer.ProducerCore memory thisProducer = _getProducer(_uniqueId);

        // set produce data with block number
        _trustedProduceData[_produceData.blockNumber][_uniqueId] = _produceData;

        require(
            keccak256(abi.encodePacked(_produceData.miner)) == keccak256(abi.encodePacked(thisProducer.account)),
            "miner is not the same of producer account"
        );


        _trustedProduceData[_produceData.blockNumber][_uniqueId].amount = _produceData.amount;

        emit TrustedDigitalProductionData(
            TREASURE_KIND,
            _uniqueId,
            _produceData.blockNumber,
            _produceData.blockReward,
            _produceData.price,
            _produceData.amount,
            _produceData.miner
        );
    }

    // _month is block number
    function _clearing(bytes32 _uniqueId, uint256 blockNumber) internal override returns (bool) {
        ProduceData storage trusted = _trustedProduceData[blockNumber][_uniqueId];
        /*require(
            trusted.account != address(0),
            "cleared or product data not found at this blockNumber"
        );*/
        require(trusted.status == ProduceDataStatus.UNAUDITED, "trusted data already audited");

        emit VerifiedProduction(_uniqueId, blockNumber, trusted.amount);

        require(
            _rewardByShare(_uniqueId, trusted.amount) == trusted.amount,
            "total minted must equal to trusted.amount"
        );
        emit ClearingReward(TREASURE_KIND, _uniqueId, blockNumber, trusted.price);

        trusted.status = ProduceDataStatus.FINISHED;
        _trustedProduceData[blockNumber][_uniqueId] = trusted;

        return true;
    }

    function _afterClearing(bytes32 _uniqueId, uint256 blockNumber) internal override {}

    function _rewardByShare(bytes32 uniqueId, uint256 total) internal returns (uint256) {
        (address[] memory accounts, uint256[] memory amounts) = _producer.calculateRewards(
            uniqueId,
            total
        );
        return _reward(uniqueId, accounts, amounts);
    }
}
