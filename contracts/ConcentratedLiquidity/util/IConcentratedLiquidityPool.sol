// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

/**
 * @title Concentrated Liquidity Pool Interface
 * @notice Minimal interface for concentrated liquidity AMM pools (Uniswap V3 style)
 * @dev This interface covers the core functions needed for property testing
 */
interface IConcentratedLiquidityPool {
    /// @notice The first of the two tokens of the pool, sorted by address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The currently in range liquidity available to the pool
    function liquidity() external view returns (uint128);

    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// @return tick The current tick of the pool
    /// @return observationIndex The index of the last oracle observation that was written
    /// @return observationCardinality The current maximum number of observations stored in the pool
    /// @return observationCardinalityNext The next maximum number of observations to store
    /// @return feeProtocol The protocol fee for both tokens of the pool
    /// @return unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice Returns information about a tick
    /// @param tick The tick to look up
    /// @return liquidityGross Total liquidity referencing this tick
    /// @return liquidityNet Change in liquidity when crossing this tick
    /// @return feeGrowthOutside0X128 Fee growth outside this tick for token0
    /// @return feeGrowthOutside1X128 Fee growth outside this tick for token1
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128
        );

    /// @notice Returns information about a position
    /// @param key The position's key (keccak256(owner, tickLower, tickUpper))
    /// @return liquidity The amount of liquidity in the position
    /// @return feeGrowthInside0LastX128 Fee growth inside the tick range as of the last action
    /// @return feeGrowthInside1LastX128 Fee growth inside the tick range as of the last action
    /// @return tokensOwed0 Tokens owed to the position owner in token0
    /// @return tokensOwed1 Tokens owed to the position owner in token1
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Removes liquidity from the sender and accounts tokens owed
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Collect tokens owed to a position
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}
