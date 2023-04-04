// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IParameterInfo.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/// @title 平台配置信息管理合约
/// @author bjwswang
contract ParameterInfo is Context, Initializable, OwnableUpgradeable, IParameterInfo {
    // OIL/GAS required
    PriceDiscountConfig private _priceDiscountConfig;
    mapping(string => uint256) private _platformConfig;

    uint256 private warnRatio;
    uint256 private liquidationRatio;

    address private _mulSig;

    /// @dev 合约初始化
    /// @param _mulSigContract 多签合约地址
    function initialize(address _mulSigContract) public initializer {
        __Ownable_init();

        _mulSig = _mulSigContract;

        warnRatio = 9900;
        liquidationRatio = 9000;

        _platformConfig["marginRatio"] = 100;
        _platformConfig["reserveRatio"] = 1000;
        _platformConfig["loanInterestRate"] = 5;
        _platformConfig["loanPledgeRate"] = 15000;

        _priceDiscountConfig.API = 3110;
        _priceDiscountConfig.sulphur = 500;
        _priceDiscountConfig.discount = [9000, 8500, 8000, 7500];
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

    /// @dev 设置平台参数
    /// @param key 参数名称
    ///    - marginRatio
    ///    - reserveRatio
    ///    - loanInterestRate
    ///    - loanPledgeRate
    ///    - liquidationRatio
    /// @param amount 参数值
    /// @return bool 是否设置成功
    function setPlatformConfig(string memory key, uint256 amount)
    external override
    onlyMulSig
    returns (bool)
    {
        if (keccak256(bytes(key)) == keccak256(bytes("marginRatio"))) {
            require(0 <= amount && amount <= 10000, "overflow");
            _platformConfig[key] = amount;
        } else if (keccak256(bytes(key)) == keccak256(bytes("reserveRatio"))) {
            require(0 <= amount && amount <= 10000, "overflow");
            _platformConfig[key] = amount;
        } else if (keccak256(bytes(key)) == keccak256(bytes("loanInterestRate"))) {
            require(0 <= amount && amount <= 100, "overflow");
            _platformConfig[key] = amount;
        } else if (keccak256(bytes(key)) == keccak256(bytes("loanPledgeRate"))) {
            require(12000 <= amount && amount <= 66600, "overflow");
            _platformConfig[key] = amount;
        } else if (keccak256(bytes(key)) == keccak256(bytes("liquidationRatio"))) {
            require(9000 <= amount && amount <= 9900, "overflow");
            liquidationRatio = amount;
        } else {
            revert("not support");
        }

        return true;
    }

    /// @dev 查询平台参数
    /// @param key 参数名称
    /// @return uint256  参数当前值
    function getPlatformConfig(string memory key) public view override returns (uint256) {
        return _platformConfig[key];
    }

    function getUSTNLoanPledgeRateWarningValue() public view override returns (uint amount){
        return _platformConfig["loanPledgeRate"] * warnRatio / 10000;
    }

    // get USTN loan liquidation rate
    function getUSTNLoanLiquidationRate() public view override returns (uint amount){
        return _platformConfig["loanPledgeRate"] * liquidationRatio / 10000;
    }

    // 补两个用于前端查询比例的接口
    function getUSTNLoanPledgeRate() public view returns (uint256){
        return _platformConfig["loanPledgeRate"];
    }
    function getUSTNLoanInterestRate() public view returns (uint256){
        return _platformConfig["loanInterestRate"];
    }

    /// @dev 设置资产折扣配置信息
    /// @param API API值
    /// @param sulphur  酸度
    /// @param discount1 折扣参数1
    /// @param discount2 折扣参数2
    /// @param discount3 折扣参数3
    /// @param discount4 折扣参数4
    /// @return bool 是否设置成功
    function setPriceDiscountConfig(
        uint256 API,
        uint256 sulphur,
        uint256 discount1,
        uint256 discount2,
        uint256 discount3,
        uint256 discount4
    ) external override onlyMulSig returns (bool) {
        require(0 <= API && API <= 10000, "overflow");
        require(0 <= sulphur && sulphur <= 10000, "overflow");
        require(0 <= discount1 && discount1 <= 10000, "overflow");
        require(
            discount1 > discount2 && discount2 > discount3 && discount3 > discount4,
            "overflow"
        );
        _priceDiscountConfig.API = API;
        _priceDiscountConfig.sulphur = sulphur;
        _priceDiscountConfig.discount = [discount1, discount2, discount3, discount4];

        return true;
    }

    /// @dev 查询折扣信息
    /// @param _API API值
    /// @param _sulphur  酸度
    /// @return uint256 折扣参数
    function getPriceDiscountConfig(uint256 _API, uint256 _sulphur) public view override returns (uint256) {
        uint256 discount;
        require(_API != 0 && _sulphur != 0, "this mine data is error or not exist this mine.");
        if (_API > _priceDiscountConfig.API && _sulphur < _priceDiscountConfig.sulphur) {
            discount = _priceDiscountConfig.discount[0];
        }
        if (_API > _priceDiscountConfig.API && _sulphur >= _priceDiscountConfig.sulphur) {
            discount = _priceDiscountConfig.discount[1];
        }
        if (_API <= _priceDiscountConfig.API && _sulphur < _priceDiscountConfig.sulphur) {
            discount = _priceDiscountConfig.discount[2];
        }
        if (_API <= _priceDiscountConfig.API && _sulphur >= _priceDiscountConfig.sulphur) {
            discount = _priceDiscountConfig.discount[3];
        }
        return discount;
    }
}
