// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {YieldVault} from "../src/Vault.sol";
import {MockERC20} from "../src/MockERC20.sol";

contract VaultTest is Test {
    YieldVault public vault;
    MockERC20 public asset;
    address public admin = makeAddr("admin");
    address public user = makeAddr("user");

    function setUp() public {
        asset = new MockERC20("Tether", "USDT");
        vault = new YieldVault(asset, admin);
        asset.mint(user, 1000 ether);
    }

    function test_DepositAndWithdraw() public {
        vm.startPrank(user);
        asset.approve(address(vault), 100 ether);
        uint256 shares = vault.deposit(100 ether, user);
        
        assertEq(shares, 100 ether);
        assertEq(vault.balanceOf(user), 100 ether);

        vault.withdraw(50 ether, user, user);
        assertEq(vault.balanceOf(user), 50 ether);
        assertEq(asset.balanceOf(user), 950 ether);
        vm.stopPrank();
    }

    function test_YieldAccrual() public {
        vm.startPrank(user);
        asset.approve(address(vault), 100 ether);
        vault.deposit(100 ether, user);
        vm.stopPrank();

        asset.mint(address(vault), 10 ether);

        vm.startPrank(user);
        uint256 withdrawn = vault.redeem(100 ether, user, user);
        vm.stopPrank();
        
        assertApproxEqAbs(withdrawn, 110 ether, 1);    
        }
}