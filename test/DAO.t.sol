// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {GovernanceToken} from "../src/GovernanceToken.sol";
import {Timelock} from "../src/Timelock.sol";
import {ApexGovernor} from "../src/ApexGovernor.sol";
import {MockERC20} from "../src/MockERC20.sol";

contract DAOTest is Test {
    GovernanceToken public govToken;
    Timelock public timelock;
    ApexGovernor public governor;
    MockERC20 public treasury;

    address public voter = makeAddr("voter");

    function setUp() public {
        govToken = new GovernanceToken();
        govToken.transfer(voter, 100000 ether);

        address[] memory empty = new address[](0);
        timelock = new Timelock(2 days, empty, empty, address(this));
        governor = new ApexGovernor(govToken, timelock);

        timelock.grantRole(timelock.PROPOSER_ROLE(), address(governor));
        timelock.grantRole(timelock.EXECUTOR_ROLE(), address(0));

        treasury = new MockERC20("Treasury", "TRS");
        treasury.mint(address(timelock), 10000 ether);

        vm.prank(voter);
        govToken.delegate(voter); // Активация права голоса
    }

    function test_FullDAOLifecycle() public {
        address[] memory targets = new address[](1);
        targets[0] = address(treasury);
        
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSignature("transfer(address,uint256)", voter, 1000 ether);
        
        string memory description = "Send funds";
        bytes32 descHash = keccak256(bytes(description));

        vm.prank(voter);
        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        // 1. Ждем начала голосования (1 days = 86400)
        // Мотаем с запасом на 86405 и блоков, и секунд
        vm.roll(block.number + 86405);
        vm.warp(block.timestamp + 86405);
        
        vm.prank(voter);
        governor.castVote(proposalId, 1);

        // 2. Ждем окончания голосования (1 weeks = 604800)
        vm.roll(block.number + 604805);
        vm.warp(block.timestamp + 604805);
        
        governor.queue(targets, values, calldatas, descHash);
        
        // 3. Ждем разблокировки Timelock (2 days = 172800 секунд)
        vm.warp(block.timestamp + 172805);
        vm.roll(block.number + 172805);
        
        governor.execute(targets, values, calldatas, descHash);

        assertEq(treasury.balanceOf(voter), 1000 ether);
    }
}