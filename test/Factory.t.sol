// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Factory} from "../src/Factory.sol";
import {MockERC20} from "../src/MockERC20.sol";

contract FactoryTest is Test {
    Factory public factory;
    MockERC20 public tokenA;
    MockERC20 public tokenB;

    function setUp() public {
        factory = new Factory();
        tokenA = new MockERC20("Token A", "TKNA");
        tokenB = new MockERC20("Token B", "TKNB");
    }

    function test_CreatePair() public {
        address pair = factory.createPair(address(tokenA), address(tokenB));
        assertTrue(pair != address(0));
        assertEq(factory.getPair(address(tokenA), address(tokenB)), pair);
        assertEq(factory.allPairsLength(), 1);
    }

    function test_RevertIdenticalTokens() public {
        vm.expectRevert(Factory.IdenticalAddresses.selector);
        factory.createPair(address(tokenA), address(tokenA));
    }

    function test_RevertZeroAddress() public {
        vm.expectRevert(Factory.ZeroAddress.selector);
        factory.createPair(address(0), address(tokenA));
    }

    function test_RevertPairExists() public {
        factory.createPair(address(tokenA), address(tokenB));
        vm.expectRevert(Factory.PairExists.selector);
        factory.createPair(address(tokenA), address(tokenB));
    }
}