// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IShare.sol";

interface IProducer is IShare {
    event AddProducer(bytes32 uniqueId, ProducerCore producer);
    event SetProducerStatus(bytes32 uniqueId, bytes32 requestId, ProducerStatus status);

    event Link(
        bytes32 key,
        bytes32[] uniqueIds,
        uint256[] ratios,
        string[] nicknames,
        bytes32 dappId
    );

    // TODO: customize based on different asset
    // unique id == hash(location_id,location,UWI)
    struct ProducerCore {
        string nickname;
        address owner;
        // Only for OIL & GAS
        uint256 API;
        uint256 sulphur;
        // Only for ETH
        string account;
    }

    enum ProducerStatus {
        // OIL&GAS
        NotSet,
        Active,
        Deactive
    }

    function addProducer(
        bytes32 uniqueId,
        ProducerCore memory _producer
    ) external;

    function getProducer(
        bytes32 _uniqueId
    ) external view returns (ProducerStatus, ProducerCore memory);

    function setProducerStatus(
        bytes32 _uniqueId,
        ProducerStatus _newStatus
    ) external;

    function producerStatus(
        bytes32 uniqueId
    ) external view returns (ProducerStatus);

    function updateProdcuer(
        bytes32 uniqueId,
        ProducerCore memory _producer
    ) external;

    function registerDAppConnect(
        string memory dapp,
        address payee
    ) external returns (bytes32);

    function getDAppPayee(bytes32 _dappId) external returns (address);

    function link(
        bytes32[] memory _uniqueIds,
        bytes32 _key,
        bytes32 _dappId
    ) external;
}
