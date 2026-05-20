// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {AMM} from "../src/AMM.sol";
import {MockERC20} from "../src/MockERC20.sol";

contract AMMTest is Test {
    AMM public pool;
    MockERC20 public token0;
    MockERC20 public token1;
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");

    function setUp() public {
        token0 = new MockERC20("Token A", "TKNA");
        token1 = new MockERC20("Token B", "TKNB");
        pool = new AMM(address(token0), address(token1));
        token0.mint(alice, 100000 ether);
        token1.mint(alice, 100000 ether);
        token0.mint(bob, 100000 ether);
        token1.mint(bob, 100000 ether);
    }

    function test_MintInitialLiquidity() public {
        vm.startPrank(alice);
        token0.transfer(address(pool), 100 ether);
        token1.transfer(address(pool), 100 ether);
        uint liquidity = pool.mint(alice);
        vm.stopPrank();

        assertEq(liquidity, 100 ether);
        assertEq(pool.balanceOf(alice), 100 ether);
    }

    function test_Swap() public {
        vm.startPrank(alice);
        token0.transfer(address(pool), 1000 ether);
        token1.transfer(address(pool), 1000 ether);
        pool.mint(alice);
        vm.stopPrank();

        vm.startPrank(bob);
        token0.transfer(address(pool), 10 ether);
        uint256 amountIn = 10 ether;
        uint256 expectedOut = (amountIn * 997 * 1000 ether) / ((1000 ether * 1000) + (amountIn * 997));        pool.swap(0, expectedOut, bob);
        vm.stopPrank();

        assertEq(token1.balanceOf(bob), 100000 ether + expectedOut);    }

    function test_BurnLiquidity() public {
        vm.startPrank(alice);
        token0.transfer(address(pool), 100 ether);
        token1.transfer(address(pool), 100 ether);
        uint liquidity = pool.mint(alice);

        pool.transfer(address(pool), liquidity);
        (uint amount0, uint amount1) = pool.burn(alice);
        vm.stopPrank();

        assertEq(amount0, 100 ether);
        assertEq(amount1, 100 ether);
    }

    function test_RevertInsufficientLiquidity() public {
        vm.startPrank(alice);
        token0.transfer(address(pool), 10 ether);
        token1.transfer(address(pool), 10 ether);
        pool.mint(alice);
        vm.stopPrank();

        vm.startPrank(bob);
        token0.transfer(address(pool), 1 ether);
        vm.expectRevert(AMM.InsufficientLiquidity.selector);
        pool.swap(0, 100 ether, bob);
        vm.stopPrank();
    }
}