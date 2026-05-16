// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// forge-lint: disable-next-line(unaliased-plain-import)
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
// forge-lint: disable-next-line(unaliased-plain-import)
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// forge-lint: disable-next-line(unaliased-plain-import)
import "@openzeppelin/contracts/access/Ownable.sol";

contract YieldVault is ERC4626, Ownable {
    constructor(IERC20 asset_, address initialOwner) 
        ERC4626(asset_) 
        ERC20("Yield Vault Share", "vTKN") 
        Ownable(initialOwner) 
    {}

    function addYield(uint256 amount) external onlyOwner {
        SafeERC20.safeTransferFrom(IERC20(asset()), msg.sender, address(this), amount);
    }
}