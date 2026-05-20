// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Lending} from "../src/Lending.sol";
import {MockERC20} from "../src/MockERC20.sol";
import {MockV3Aggregator} from "../src/MockV3Aggregator.sol";

contract LendingTest is Test {
    Lending public lending;
    MockERC20 public weth;
    MockERC20 public usdc;
    MockV3Aggregator public oracle;
    address public user = makeAddr("user");

    function setUp() public {
        weth = new MockERC20("Wrapped ETH", "WETH");
        usdc = new MockERC20("USD Coin", "USDC");
        oracle = new MockV3Aggregator(8, 2000 * 10**8); // 1 ETH = 2000$
        
        lending = new Lending(address(weth), address(usdc), address(oracle));
        usdc.mint(address(lending), 100000 ether);
        weth.mint(user, 10 ether);
        usdc.mint(user, 10000 ether);
    }

    function test_DepositAndBorrow() public {
        vm.startPrank(user);
        weth.approve(address(lending), 1 ether);
        lending.depositCollateral(1 ether);

        lending.borrow(1000 ether); // 1000$ < 1600$ (80% от 2000$)
        assertEq(lending.borrowBalance(user), 1000 ether);
        vm.stopPrank();
    }

    function test_RevertUndercollateralizedBorrow() public {
        vm.startPrank(user);
        weth.approve(address(lending), 1 ether);
        lending.depositCollateral(1 ether);

        vm.expectRevert(Lending.Undercollateralized.selector);
        lending.borrow(1601 ether); 
        vm.stopPrank();
    }

    function test_RepayAndWithdraw() public {
        vm.startPrank(user);
        weth.approve(address(lending), 1 ether);
        lending.depositCollateral(1 ether);
        lending.borrow(1000 ether);

        usdc.approve(address(lending), 1000 ether);
        lending.repay(1000 ether);
        assertEq(lending.borrowBalance(user), 0);

        lending.withdrawCollateral(1 ether);
        assertEq(weth.balanceOf(user), 10 ether);
        vm.stopPrank();
    }
}