// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import "../util/ConcentratedLiquidityTestBase.sol";
import "../../util/TickMath.sol";

/**
 * @title Concentrated Liquidity Swap Properties
 * @author Crytic (Trail of Bits)
 * @notice Properties for swap execution and price impact
 * @dev Testing Mode: INTERNAL
 *
 * WHY THESE PROPERTIES MATTER:
 * Swaps are the primary mechanism for price discovery and trading in AMMs. In concentrated
 * liquidity pools, swaps must:
 * 1. Move price in the correct direction based on trade direction
 * 2. Respect price limits (slippage protection)
 * 3. Update liquidity when crossing tick boundaries
 * 4. Maintain conservation of value (x*y=k equivalent)
 *
 * Incorrect swap logic can lead to:
 * - Price manipulation
 * - Sandwich attacks with no slippage
 * - Liquidity not being updated (KyberSwap vulnerability)
 * - Arbitrage opportunities that drain the pool
 */
abstract contract CryticSwapProperties is ConcentratedLiquidityTestBase {
    using TickMath for int24;
    using TickMath for uint160;

    //////////////////////////////////////////////////////////////////////
    // PROPERTY 10: Swap Moves Price in Correct Direction
    //////////////////////////////////////////////////////////////////////

    /**
     * @notice Test that swapping moves the price in the correct direction
     * @dev Property ID: CL-SWAP-001
     * @custom:property-id CL-SWAP-001
     *
     * WHY THIS MUST BE TRUE:
     * The direction of a swap determines how the price changes:
     *
     * - zeroForOne = true: Selling token0 for token1
     *   → More token0 in pool, less token1 in pool
     *   → Price of token0 in terms of token1 DECREASES
     *   → sqrtPriceX96 DECREASES
     *   → tick DECREASES
     *
     * - zeroForOne = false: Selling token1 for token0
     *   → Less token0 in pool, more token1 in pool
     *   → Price of token0 in terms of token1 INCREASES
     *   → sqrtPriceX96 INCREASES
     *   → tick INCREASES
     *
     * MATHEMATICAL DEFINITION:
     * Price is defined as: price = (token1 / token0)
     * In Uniswap V3: sqrtPriceX96 = sqrt(token1/token0) * 2^96
     *
     * When selling token0 (adding it to pool):
     *   token1/token0 decreases → price decreases
     *
     * When selling token1 (adding it to pool):
     *   token1/token0 increases → price increases
     *
     * EXAMPLE:
     * Initial: sqrtPrice = 1000, tick = 100
     *
     * Swap zeroForOne = true (sell token0):
     *   → sqrtPrice = 900, tick = 90
     *   → Price went DOWN ✓
     *
     * Swap zeroForOne = false (sell token1):
     *   → sqrtPrice = 1100, tick = 110
     *   → Price went UP ✓
     *
     * WHAT BUG THIS CATCHES:
     * - Swap direction logic inverted
     * - Price moving opposite to trade direction
     * - Sign errors in price calculation
     * - Incorrect token pair ordering
     */
    function test_CL_swapMoviesPriceInCorrectDirection(
        bool zeroForOne,
        uint256 amountSpecified
    ) public virtual {
        // Constrain amount to reasonable range
        amountSpecified = clampBetween(amountSpecified, 1, type(uint64).max);

        uint160 sqrtPriceBefore = _getSqrtPriceX96();
        int24 tickBefore = _getCurrentTick();

        // Perform swap
        bool swapSucceeded = _trySwap(zeroForOne, amountSpecified);
        if (!swapSucceeded) return; // Skip if swap failed (e.g., insufficient liquidity)

        uint160 sqrtPriceAfter = _getSqrtPriceX96();
        int24 tickAfter = _getCurrentTick();

        // Check price direction
        if (zeroForOne) {
            // Selling token0 for token1 → price should decrease or stay same
            assertWithMsg(
                sqrtPriceAfter <= sqrtPriceBefore,
                "CL-SWAP-001: Swap zeroForOne=true increased price (should decrease)"
            );
            assertWithMsg(
                tickAfter <= tickBefore,
                "CL-SWAP-001: Swap zeroForOne=true increased tick (should decrease)"
            );
        } else {
            // Selling token1 for token0 → price should increase or stay same
            assertWithMsg(
                sqrtPriceAfter >= sqrtPriceBefore,
                "CL-SWAP-001: Swap zeroForOne=false decreased price (should increase)"
            );
            assertWithMsg(
                tickAfter >= tickBefore,
                "CL-SWAP-001: Swap zeroForOne=false decreased tick (should decrease)"
            );
        }
    }

    //////////////////////////////////////////////////////////////////////
    // PROPERTY 11: Swap Respects Price Limit
    //////////////////////////////////////////////////////////////////////

    /**
     * @notice Test that swap never moves price beyond the specified limit
     * @dev Property ID: CL-SWAP-002
     * @custom:property-id CL-SWAP-002
     *
     * WHY THIS MUST BE TRUE:
     * The sqrtPriceLimitX96 parameter provides slippage protection. The swap must
     * stop when the price reaches this limit, even if the full amountSpecified
     * hasn't been consumed.
     *
     * This prevents:
     * - Excessive slippage
     * - Sandwich attacks beyond acceptable limits
     * - Trades executing at worse prices than expected
     *
     * MATHEMATICAL DEFINITION:
     * If zeroForOne = true (price decreasing):
     *   sqrtPriceAfter >= sqrtPriceLimit
     *
     * If zeroForOne = false (price increasing):
     *   sqrtPriceAfter <= sqrtPriceLimit
     *
     * WHAT BUG THIS CATCHES:
     * - Price limit not enforced
     * - Swap continuing past limit
     * - Incorrect inequality direction
     */
    function test_CL_swapRespectsLimitPrice(
        bool zeroForOne,
        uint256 amountSpecified,
        uint160 sqrtPriceLimitX96
    ) public virtual {
        // Constrain inputs
        amountSpecified = clampBetween(amountSpecified, 1, type(uint64).max);
        sqrtPriceLimitX96 = uint160(clampBetween(sqrtPriceLimitX96, MIN_SQRT_RATIO + 1, MAX_SQRT_RATIO - 1));

        uint160 sqrtPriceBefore = _getSqrtPriceX96();

        // Ensure limit price is valid for the swap direction
        if (zeroForOne) {
            // Price is decreasing, limit must be below current price
            if (sqrtPriceLimitX96 >= sqrtPriceBefore) return;
        } else {
            // Price is increasing, limit must be above current price
            if (sqrtPriceLimitX96 <= sqrtPriceBefore) return;
        }

        // Perform swap with limit price
        bool swapSucceeded = _trySwapWithLimit(zeroForOne, amountSpecified, sqrtPriceLimitX96);
        if (!swapSucceeded) return;

        uint160 sqrtPriceAfter = _getSqrtPriceX96();

        // Verify price did not exceed limit
        if (zeroForOne) {
            assertWithMsg(
                sqrtPriceAfter >= sqrtPriceLimitX96,
                "CL-SWAP-002: Swap exceeded price limit when going down"
            );
        } else {
            assertWithMsg(
                sqrtPriceAfter <= sqrtPriceLimitX96,
                "CL-SWAP-002: Swap exceeded price limit when going up"
            );
        }
    }

    //////////////////////////////////////////////////////////////////////
    // PROPERTY 12: Swap Updates Liquidity When Crossing Ticks
    //////////////////////////////////////////////////////////////////////

    /**
     * @notice Test that liquidity is updated when swap crosses tick boundaries
     * @dev Property ID: CL-SWAP-003
     * @custom:property-id CL-SWAP-003
     *
     * WHY THIS MUST BE TRUE:
     * When a swap moves the price across a tick boundary, the current liquidity
     * must be updated by applying the liquidityNet at that tick. This is the
     * core mechanism for activating/deactivating positions.
     *
     * Failure to update liquidity when crossing ticks leads to:
     * - Using wrong liquidity for price calculation
     * - Positions not being activated/deactivated
     * - KyberSwap-style vulnerabilities (double-counting)
     *
     * MATHEMATICAL DEFINITION:
     * When crossing tick T in direction D:
     * If going up (zeroForOne = false):
     *   liquidity_new = liquidity_old + liquidityNet[T]
     * If going down (zeroForOne = true):
     *   liquidity_new = liquidity_old - liquidityNet[T]
     *
     * WHAT BUG THIS CATCHES:
     * - Tick crossing not detected
     * - Liquidity not updated when crossing
     * - Wrong direction applied to liquidityNet
     * - KyberSwap vulnerability (price overshoots tick)
     */
    function test_CL_swapUpdatesLiquidityWhenCrossingTicks(
        bool zeroForOne,
        uint256 amountSpecified
    ) public virtual {
        // Constrain amount to force tick crossing
        amountSpecified = clampBetween(amountSpecified, type(uint64).max / 2, type(uint64).max);

        int24 tickBefore = _getCurrentTick();
        uint128 liquidityBefore = _getCurrentLiquidity();

        // Perform swap
        bool swapSucceeded = _trySwap(zeroForOne, amountSpecified);
        if (!swapSucceeded) return;

        int24 tickAfter = _getCurrentTick();
        uint128 liquidityAfter = _getCurrentLiquidity();

        // If we crossed at least one tick, liquidity should have changed
        // (unless all crossed ticks have liquidityNet = 0, which is rare)
        if (tickAfter != tickBefore) {
            // Calculate expected liquidity by summing liquidityNet
            int256 expectedLiquidity = 0;
            for (uint256 i = 0; i < usedTicks.length; i++) {
                int24 tick = usedTicks[i];
                if (tick <= tickAfter) {
                    expectedLiquidity += int256(int128(_getLiquidityNetAtTick(tick)));
                }
            }

            // Liquidity must match the calculated value
            if (expectedLiquidity >= 0) {
                assertEq(
                    liquidityAfter,
                    uint128(uint256(expectedLiquidity)),
                    "CL-SWAP-003: Liquidity not correctly updated after crossing ticks"
                );
            }
        }
    }

    //////////////////////////////////////////////////////////////////////
    // PROPERTY 13: Swap Price Stays Within Valid Range
    //////////////////////////////////////////////////////////////////////

    /**
     * @notice Test that swap never moves price outside valid bounds
     * @dev Property ID: CL-SWAP-004
     * @custom:property-id CL-SWAP-004
     *
     * WHY THIS MUST BE TRUE:
     * There are mathematical limits to valid prices in Uniswap V3:
     * - MIN_SQRT_RATIO = 4295128739
     * - MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342
     *
     * These correspond to MIN_TICK and MAX_TICK. Price cannot go beyond these
     * bounds as it would cause overflow/underflow in the math library.
     *
     * WHAT BUG THIS CATCHES:
     * - Overflow/underflow in price calculation
     * - Swap allowing invalid price states
     * - Missing bounds checks
     */
    function test_CL_swapPriceStaysWithinBounds(
        bool zeroForOne,
        uint256 amountSpecified
    ) public virtual {
        amountSpecified = clampBetween(amountSpecified, 1, type(uint128).max);

        // Perform swap
        bool swapSucceeded = _trySwap(zeroForOne, amountSpecified);
        if (!swapSucceeded) return;

        uint160 sqrtPriceAfter = _getSqrtPriceX96();
        int24 tickAfter = _getCurrentTick();

        // Price must be within valid bounds
        assertWithMsg(
            sqrtPriceAfter >= MIN_SQRT_RATIO,
            "CL-SWAP-004: Swap resulted in price below MIN_SQRT_RATIO"
        );

        assertWithMsg(
            sqrtPriceAfter < MAX_SQRT_RATIO,
            "CL-SWAP-004: Swap resulted in price above MAX_SQRT_RATIO"
        );

        // Tick must be within valid bounds
        assertWithMsg(
            tickAfter >= MIN_TICK,
            "CL-SWAP-004: Swap resulted in tick below MIN_TICK"
        );

        assertWithMsg(
            tickAfter <= MAX_TICK,
            "CL-SWAP-004: Swap resulted in tick above MAX_TICK"
        );
    }

    //////////////////////////////////////////////////////////////////////
    // HELPER FUNCTIONS (to be overridden by inheriting contract)
    //////////////////////////////////////////////////////////////////////

    /**
     * @notice Get the current sqrt price
     */
    function _getSqrtPriceX96() internal view virtual returns (uint160);

    /**
     * @notice Get the current tick
     */
    function _getCurrentTick() internal view virtual returns (int24);

    /**
     * @notice Get the current liquidity
     */
    function _getCurrentLiquidity() internal view virtual returns (uint128);

    /**
     * @notice Get liquidityNet at a tick
     */
    function _getLiquidityNetAtTick(int24 tick) internal view virtual returns (int128);

    /**
     * @notice Try to perform a swap, return success status
     */
    function _trySwap(bool zeroForOne, uint256 amountSpecified) internal virtual returns (bool);

    /**
     * @notice Try to perform a swap with price limit, return success status
     */
    function _trySwapWithLimit(
        bool zeroForOne,
        uint256 amountSpecified,
        uint160 sqrtPriceLimitX96
    ) internal virtual returns (bool);
}
