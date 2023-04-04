// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IGovernance {
    function addTreasure(
        string memory _treasureType,
        address _producer,
        address _productionData
    ) external;

    function fmThreshold() external returns (uint256);

    function getTreasureByKind(string memory _treasureType)
        external
        view
        returns (address, address);
}
