// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "properties/UniswapV2/internal/properties/UniswapV2BasicProperties.sol";
import "properties/UniswapV2/internal/properties/UniswapV2RemoveLiquidityProperties.sol";
import "properties/UniswapV2/internal/properties/UniswapV2SwapProperties.sol";
import "properties/UniswapV2/internal/properties/UniswapV2InvariantProperties.sol";
import "../src/SimplePair.sol";
import "../src/MockERC20.sol";

contract CryticUniswapV2InternalHarness is
    SimplePair,
    CryticUniswapV2BasicProperties,
    CryticUniswapV2RemoveLiquidityProperties,
    CryticUniswapV2SwapProperties,
    CryticUniswapV2InvariantProperties
{
    MockERC20 public tokenA;
    MockERC20 public tokenB;

    constructor() SimplePair(address(0), address(0)) {
        // Deploy mock tokens
        tokenA = new MockERC20("Token A", "TKA");
        tokenB = new MockERC20("Token B", "TKB");

        // Set token addresses
        token0 = address(tokenA);
        token1 = address(tokenB);

        // Mint initial tokens to test users
        tokenA.mint(USER1, INITIAL_BALANCE);
        tokenA.mint(USER2, INITIAL_BALANCE);
        tokenA.mint(USER3, INITIAL_BALANCE);

        tokenB.mint(USER1, INITIAL_BALANCE);
        tokenB.mint(USER2, INITIAL_BALANCE);
        tokenB.mint(USER3, INITIAL_BALANCE);

        // Initialize the pair with some liquidity
        tokenA.mint(address(this), 10000e18);
        tokenB.mint(address(this), 10000e18);
        this.mint(address(this));
    }
}
