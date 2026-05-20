// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {GovernanceToken} from "../src/GovernanceToken.sol";
import {Timelock} from "../src/Timelock.sol";
import {ApexGovernor} from "../src/ApexGovernor.sol";
import {YieldVault} from "../src/Vault.sol";
import {MockERC20} from "../src/MockERC20.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        GovernanceToken govToken = new GovernanceToken();
        console.log("Gov Token deployed to:", address(govToken));

        address[] memory proposers = new address[](0);
        address[] memory executors = new address[](0);
        Timelock timelock = new Timelock(172800, proposers, executors, msg.sender);
        console.log("Timelock deployed to:", address(timelock));

        ApexGovernor governor = new ApexGovernor(govToken, timelock);
        console.log("Governor deployed to:", address(governor));

        timelock.grantRole(timelock.PROPOSER_ROLE(), address(governor));
        timelock.grantRole(timelock.EXECUTOR_ROLE(), address(0));

        MockERC20 assetToken = new MockERC20("Tether", "USDT");
        
        YieldVault vault = new YieldVault(assetToken, address(timelock));
        console.log("Yield Vault deployed to:", address(vault));

        vm.stopBroadcast();
    }
}