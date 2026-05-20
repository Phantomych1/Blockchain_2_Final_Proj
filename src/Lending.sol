// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IAggregatorV3 {
    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);
}

contract Lending {
    using SafeERC20 for IERC20;

    IERC20 public collateralToken;
    IERC20 public borrowToken;
    IAggregatorV3 public priceFeed;

    mapping(address => uint256) public collateralBalance;
    mapping(address => uint256) public borrowBalance;

    uint256 public constant LTV_PERCENT = 80;

    error Undercollateralized();
    error InvalidPrice();

    constructor(address _collateralToken, address _borrowToken, address _priceFeed) {
        collateralToken = IERC20(_collateralToken);
        borrowToken = IERC20(_borrowToken);
        priceFeed = IAggregatorV3(_priceFeed);
    }

    function depositCollateral(uint256 amount) external {
        collateralToken.safeTransferFrom(msg.sender, address(this), amount);
        collateralBalance[msg.sender] += amount;
    }

    function withdrawCollateral(uint256 amount) external {
        collateralBalance[msg.sender] -= amount;
        if (!_isHealthy(msg.sender)) revert Undercollateralized();
        collateralToken.safeTransfer(msg.sender, amount);
    }

    function borrow(uint256 amount) external {
        borrowBalance[msg.sender] += amount;
        if (!_isHealthy(msg.sender)) revert Undercollateralized();
        borrowToken.safeTransfer(msg.sender, amount);
    }

    function repay(uint256 amount) external {
        borrowToken.safeTransferFrom(msg.sender, address(this), amount);
        borrowBalance[msg.sender] -= amount;
    }

    function _isHealthy(address user) internal view returns (bool) {
        uint256 borrowed = borrowBalance[user];
        if (borrowed == 0) return true;

        uint256 collateral = collateralBalance[user];
        
        (, int256 price, , , ) = priceFeed.latestRoundData();
        if (price <= 0) revert InvalidPrice();

        uint256 collateralValueUSD = (collateral * uint256(price)) / 1e8; 
        
        uint256 maxBorrow = (collateralValueUSD * LTV_PERCENT) / 100;

        return borrowed <= maxBorrow;
    }
}