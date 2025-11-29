// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "properties/UniswapV2/internal/properties/UniswapV2BasicProperties.sol";
import "properties/UniswapV2/internal/properties/UniswapV2RemoveLiquidityProperties.sol";
import "properties/UniswapV2/internal/properties/UniswapV2SwapProperties.sol";
import "properties/UniswapV2/internal/properties/UniswapV2InvariantProperties.sol";
import "../src/SimplePair.sol";

contract TestToken {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function mint(address to, uint256 amount) external {
        totalSupply += amount;
        balanceOf[to] += amount;
    }
}

contract CryticUniswapV2InternalHarness is
    SimplePair,
    CryticUniswapV2BasicProperties,
    CryticUniswapV2RemoveLiquidityProperties,
    CryticUniswapV2SwapProperties,
    CryticUniswapV2InvariantProperties
{
    TestToken public tokenA;
    TestToken public tokenB;

    constructor() SimplePair(address(0), address(0)) {
        // Deploy test tokens
        tokenA = new TestToken("Token A", "TKA");
        tokenB = new TestToken("Token B", "TKB");

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
