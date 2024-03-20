// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IShare {
    enum Flag {
        NotHolder,
        Holder
    }

    struct Holder {
        uint256 index;
        uint256 ratio;
        Flag flag;
    }

    event SetHolder(
        bytes32 uniqueId,
        address holder,
        uint256 ratio,
        uint256 currentTotalHolders,
        uint256 currentTotalShared
    );
    event SplitHolder(
        bytes32 uniqueId,
        address from,
        address to,
        uint256 ratio
    );
    event DeleteHolder(bytes32 uniqueId, address holder);

    // Share management
    function maxShares() external returns (uint256);

    function totalHolders(bytes32 _uniqueId) external view returns (uint256);

    function totalShared(bytes32 _uniqueId) external view returns (uint256);

    function holder(
        bytes32 _uniqueId,
        address _holder
    ) external view returns (Holder memory);

    function isHolder(
        bytes32 _uniqueId,
        address _holder
    ) external view returns (bool);

    function setHolders(
        bytes32 _uniqueId,
        address[] memory _holders,
        uint256[] memory _ratios
    ) external;

    function splitHolder(
        bytes32 _uniqueId,
        address _toHolder,
        uint256 _ratio
    ) external returns (uint256, uint256);

    function deleteHolder(bytes32 _uniqueId, address _holder) external;

    function calculateRewards(
        bytes32 _uniqueId,
        uint256 total
    ) external returns (address[] memory, uint256[] memory);
}
