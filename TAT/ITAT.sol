// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IStake.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface ITAT is IERC20Upgradeable,IStake {
    function mint(
        string memory treasureKind,
        bytes32 uniqueId,
        address to,
        uint256 amount
    ) external;

    function burn(
        string memory treasureKind,
        address to,
        uint256 amount
    ) external;

    function paused() external returns (bool);
    function pause() external;
    function unpause() external;
}
