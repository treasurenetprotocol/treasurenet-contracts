// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/// @title 角色管理合约
/// @author bjwswang
contract Roles is Initializable, OwnableUpgradeable, AccessControlEnumerable {
    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public constant FOUNDATION_MANAGER = keccak256("FOUNDATION_MANAGER");
    bytes32 public constant AUCTION_MANAGER = keccak256("AUCTION_MANAGER");
    bytes32 public constant FEEDER = keccak256("FEEDER");

    address private _mulSig;

    /// @dev 初始化角色管理合约
    /// @param _mulSigContract 多签合约地址
    /// @param managers  管理员账户(FOUNDATION_MANAGER)
    /// @param feeders 预言机数据供应方(FEEDER)
    function initialize(
        address _mulSigContract,
        address[] memory managers, // initialize manager
        address[] memory auctionManagers,
        address[] memory feeders // feeders for oracle data
    ) public initializer {
        __Ownable_init();

        _mulSig = _mulSigContract;
        _setupRole(ADMIN, _mulSigContract);

        _setRoleAdmin(ADMIN, ADMIN);
        _setRoleAdmin(FOUNDATION_MANAGER, ADMIN);
        _setRoleAdmin(AUCTION_MANAGER,FOUNDATION_MANAGER);
        _setRoleAdmin(FEEDER, ADMIN);

        for (uint256 i = 0; i < managers.length; ++i) {
            _setupRole(FOUNDATION_MANAGER, managers[i]);
        }

        for (uint256 i = 0; i < auctionManagers.length; ++i) {
            _setupRole(AUCTION_MANAGER, auctionManagers[i]);
        }

        for (uint256 i = 0; i < feeders.length; ++i) {
            _setupRole(FEEDER, feeders[i]);
        }
    }

    modifier onlyMulSig() {
        require(_msgSender() == _mulSig, "");
        _;
    }

    function _msgSender()
        internal
        view
        virtual
        override(Context, ContextUpgradeable)
        returns (address)
    {
        return msg.sender;
    }

    function _msgData()
        internal
        view
        virtual
        override(Context, ContextUpgradeable)
        returns (bytes calldata)
    {
        return msg.data;
    }
}
