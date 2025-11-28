// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "../../../util/PropertiesConstants.sol";
import "../../../util/PropertiesAsserts.sol";

abstract contract CryticUniswapV2Base is
    PropertiesAsserts,
    PropertiesConstants
{
    // Minimum liquidity locked forever (Uniswap V2 constant)
    uint256 internal constant MINIMUM_LIQUIDITY = 1000;

    constructor() {}

    ////////////////////////////////////////
    // Abstract functions to be implemented by inheriting contract

    function token0() public view virtual returns (address);
    function token1() public view virtual returns (address);
    function getReserves() public view virtual returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() public view virtual returns (uint256);
    function price1CumulativeLast() public view virtual returns (uint256);
    function kLast() public view virtual returns (uint256);
    function totalSupply() public view virtual returns (uint256);
    function balanceOf(address account) public view virtual returns (uint256);

    function mint(address to) public virtual returns (uint256 liquidity);
    function burn(address to) public virtual returns (uint256 amount0, uint256 amount1);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) public virtual;
    function skim(address to) public virtual;
    function sync() public virtual;

    ////////////////////////////////////////
    // Helper functions

    function _getK() internal view returns (uint256) {
        (uint112 reserve0, uint112 reserve1,) = getReserves();
        return uint256(reserve0) * uint256(reserve1);
    }

    function _getLPTokenValue() internal view returns (uint256) {
        uint256 supply = totalSupply();
        if (supply == 0) return 0;

        (uint112 reserve0, uint112 reserve1,) = getReserves();
        // Value per LP token = (reserve0 + reserve1) / totalSupply
        // Simplified assuming token0 and token1 have same value
        return (uint256(reserve0) + uint256(reserve1)) / supply;
    }

    function _getPrice0() internal view returns (uint256) {
        (uint112 reserve0, uint112 reserve1,) = getReserves();
        if (reserve0 == 0) return 0;
        return (uint256(reserve1) * 1e18) / uint256(reserve0);
    }

    function _getPrice1() internal view returns (uint256) {
        (uint112 reserve0, uint112 reserve1,) = getReserves();
        if (reserve1 == 0) return 0;
        return (uint256(reserve0) * 1e18) / uint256(reserve1);
    }
}
