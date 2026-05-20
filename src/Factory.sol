// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AMM} from "./AMM.sol";

contract Factory {
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    error IdenticalAddresses();
    error ZeroAddress();
    error PairExists();

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        if (tokenA == tokenB) revert IdenticalAddresses();
        
        // Сортируем адреса, чтобы пара A-B и B-A была одним и тем же пулом
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        
        if (token0 == address(0)) revert ZeroAddress();
        if (getPair[token0][token1] != address(0)) revert PairExists();

        bytes memory bytecode = type(AMM).creationCode;
        bytes memory initCode = abi.encodePacked(bytecode, abi.encode(token0, token1));
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));

        assembly {
            pair := create2(0, add(initCode, 32), mload(initCode), salt)
            if iszero(extcodesize(pair)) {
                revert(0, 0)
            }
        }

        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // Записываем в обе стороны
        allPairs.push(pair);

        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }
}