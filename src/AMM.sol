// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// forge-lint: disable-next-line(unaliased-plain-import)
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// forge-lint: disable-next-line(unaliased-plain-import)
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// forge-lint: disable-next-line(unaliased-plain-import)
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// forge-lint: disable-next-line(unaliased-plain-import)
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
// forge-lint: disable-next-line(unaliased-plain-import)
import {IAMM} from "./interfaces/IAMM.sol";

contract AMM is ERC20, IAMM, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable TOKEN0;
    IERC20 public immutable TOKEN1;

    uint112 private reserve0;
    uint112 private reserve1;
    uint32 private blockTimestampLast;

    error InsufficientLiquidityMinted();
    error InsufficientLiquidityBurned();
    error InsufficientOutputAmount();
    error InsufficientLiquidity();
    error InvalidTo();
    error KInvariantError();
    error Overflow();

    constructor(address _token0, address _token1) ERC20("LP Token", "LP") {
        TOKEN0 = IERC20(_token0);
        TOKEN1 = IERC20(_token1);
    }

    function getReserves() public view override returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _update(uint balance0, uint balance1) private {
        if (balance0 > type(uint112).max || balance1 > type(uint112).max) revert Overflow();
        
        // forge-lint: disable-next-line(unsafe-typecast)
        reserve0 = uint112(balance0);
        // forge-lint: disable-next-line(unsafe-typecast)
        reserve1 = uint112(balance1);
        blockTimestampLast = uint32(block.timestamp);
    }

    function mint(address to) external override nonReentrant returns (uint liquidity) {
        uint balance0 = TOKEN0.balanceOf(address(this));
        uint balance1 = TOKEN1.balanceOf(address(this));
        uint amount0 = balance0 - reserve0;
        uint amount1 = balance1 - reserve1;

        uint _totalSupply = totalSupply();
        if (_totalSupply == 0) {
            liquidity = sqrt(amount0 * amount1);
        } else {
            liquidity = min((amount0 * _totalSupply) / reserve0, (amount1 * _totalSupply) / reserve1);
        }

        if (liquidity == 0) revert InsufficientLiquidityMinted();
        
        _mint(to, liquidity);
        _update(balance0, balance1);
    }

    function burn(address to) external override nonReentrant returns (uint amount0, uint amount1) {
        uint balance0 = TOKEN0.balanceOf(address(this));
        uint balance1 = TOKEN1.balanceOf(address(this));
        uint liquidity = balanceOf(address(this));

        uint _totalSupply = totalSupply();
        amount0 = (liquidity * balance0) / _totalSupply;
        amount1 = (liquidity * balance1) / _totalSupply;

        if (amount0 == 0 || amount1 == 0) revert InsufficientLiquidityBurned();
        
        _burn(address(this), liquidity);
        
        TOKEN0.safeTransfer(to, amount0);
        TOKEN1.safeTransfer(to, amount1);
        
        balance0 = TOKEN0.balanceOf(address(this));
        balance1 = TOKEN1.balanceOf(address(this));
        _update(balance0, balance1);
    }

    function swap(uint amount0Out, uint amount1Out, address to) external override nonReentrant {
        if (amount0Out == 0 && amount1Out == 0) revert InsufficientOutputAmount();
        if (amount0Out > reserve0 || amount1Out > reserve1) revert InsufficientLiquidity();
        if (to == address(TOKEN0) || to == address(TOKEN1)) revert InvalidTo();

        if (amount0Out > 0) TOKEN0.safeTransfer(to, amount0Out);
        if (amount1Out > 0) TOKEN1.safeTransfer(to, amount1Out);

        uint balance0 = TOKEN0.balanceOf(address(this));
        uint balance1 = TOKEN1.balanceOf(address(this));

        uint amount0In = balance0 > reserve0 - amount0Out ? balance0 - (reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > reserve1 - amount1Out ? balance1 - (reserve1 - amount1Out) : 0;

        uint balance0Adjusted = balance0 * 1000 - amount0In * 3;
        uint balance1Adjusted = balance1 * 1000 - amount1In * 3;

        if (balance0Adjusted * balance1Adjusted < uint(reserve0) * uint(reserve1) * (1000**2)) {
            revert KInvariantError();
        }

        _update(balance0, balance1);
    }

    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        return z;
    }

    function min(uint x, uint y) internal pure returns (uint) {
        return x < y ? x : y;
    }
}