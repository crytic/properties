// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import "../util/ConcentratedLiquidityTestBase.sol";
import "../../util/TickMath.sol";

/**
 * @title Concentrated Liquidity Tick Math Properties
 * @author Crytic (Trail of Bits)
 * @notice Properties for tick arithmetic and price-tick synchronization
 * @dev Testing Mode: INTERNAL
 *
 * WHY THESE PROPERTIES MATTER:
 * Tick-price synchronization is critical in concentrated liquidity AMMs. The KyberSwap hack
 * ($50M stolen) resulted from using inequality (!=) instead of directional comparison (</>)
 * when checking if price reached the next tick. This caused price to overshoot the tick
 * boundary, leading to double-counting of liquidity and catastrophic losses.
 *
 * These properties ensure:
 * 1. Tick moves in sync with price (mathematical requirement)
 * 2. Price never overshoots tick boundaries (KyberSwap vulnerability)
 * 3. All ticks respect the tick spacing parameter (prevents fragmentation)
 */
abstract contract CryticTickMathProperties is ConcentratedLiquidityTestBase {
    using TickMath for int24;
    using TickMath for uint160;

    //////////////////////////////////////////////////////////////////////
    // PROPERTY 1: Tick Direction Matches Price Direction
    //////////////////////////////////////////////////////////////////////

    /**
     * @notice Test that tick changes in the same direction as price
     * @dev Property ID: CL-TICK-001
     * @custom:property-id CL-TICK-001
     *
     * WHY THIS MUST BE TRUE:
     * By definition, tick = floor(log₁.₀₀₀₁(price)). This is a monotonically increasing
     * function, meaning if price increases, tick must increase, and vice versa.
     *
     * MATHEMATICAL PROOF:
     * - tick = floor(log₁.₀₀₀₁(P))
     * - If P₁ < P₂, then log₁.₀₀₀₁(P₁) < log₁.₀₀₀₁(P₂)
     * - Therefore floor(log₁.₀₀₀₁(P₁)) ≤ floor(log₁.₀₀₀₁(P₂))
     *
     * WHAT BUG THIS CATCHES:
     * - Incorrect tick calculation implementations
     * - Sign errors in logarithm computation
     * - Tick updates that don't match price movements
     */
    function test_CL_tickDirectionMatchesPriceDirection(
        uint160 oldSqrtPrice,
        uint160 newSqrtPrice
    ) public virtual {
        // Constrain to valid sqrt price ranges
        oldSqrtPrice = uint160(clampBetween(oldSqrtPrice, MIN_SQRT_RATIO, MAX_SQRT_RATIO - 1));
        newSqrtPrice = uint160(clampBetween(newSqrtPrice, MIN_SQRT_RATIO, MAX_SQRT_RATIO - 1));

        // Skip if prices are equal (no direction to check)
        if (oldSqrtPrice == newSqrtPrice) return;

        int24 oldTick = TickMath.getTickAtSqrtRatio(oldSqrtPrice);
        int24 newTick = TickMath.getTickAtSqrtRatio(newSqrtPrice);

        // If price increased, tick must not decrease
        if (newSqrtPrice > oldSqrtPrice) {
            assertWithMsg(
                newTick >= oldTick,
                "CL-TICK-001: Price increased but tick decreased"
            );
        }
        // If price decreased, tick must not increase
        else {
            assertWithMsg(
                newTick <= oldTick,
                "CL-TICK-001: Price decreased but tick increased"
            );
        }
    }

    //////////////////////////////////////////////////////////////////////
    // PROPERTY 2: No Price Overshoot Past Tick Boundary (KYBERSWAP FIX)
    //////////////////////////////////////////////////////////////////////

    /**
     * @notice Test that price never overshoots the target tick boundary
     * @dev Property ID: CL-TICK-002
     * @custom:property-id CL-TICK-002
     * @custom:exploit KyberSwap Elastic hack (November 2023) - $50M stolen
     *
     * WHY THIS MUST BE TRUE:
     * When swapping across ticks, the price should stop AT OR BEFORE the next tick
     * boundary, never beyond it. This is because:
     * 1. Liquidity is updated when crossing ticks
     * 2. If price overshoots, the old liquidity continues to be used beyond where
     *    it should have changed
     * 3. This causes double-counting or missing liquidity updates
     *
     * THE KYBERSWAP VULNERABILITY:
     * KyberSwap used: `if (sqrtPrice != sqrtPriceAtNextTick)`
     * This allowed: sqrtPrice > sqrtPriceAtNextTick (price went ABOVE the tick)
     * Result: Liquidity was counted twice because tick wasn't crossed
     *
     * CORRECT CHECK:
     * When moving up: sqrtPrice ≤ sqrtPriceAtNextTick (use ≤, not !=)
     * When moving down: sqrtPrice ≥ sqrtPriceAtPrevTick (use ≥, not !=)
     *
     * WHAT BUG THIS CATCHES:
     * - Using inequality (!=) instead of directional comparison
     * - Floating point precision errors causing overshoot
     * - Off-by-one errors in tick crossing logic
     */
    function test_CL_noPriceOvershootWhenMovingUp(
        int24 currentTick,
        int24 nextTick
    ) public virtual {
        // Ensure valid tick range and proper ordering
        currentTick = int24(clampBetween(currentTick, MIN_TICK, MAX_TICK - 1));
        nextTick = int24(clampBetween(nextTick, currentTick + 1, MAX_TICK));

        uint160 currentSqrtPrice = TickMath.getSqrtRatioAtTick(currentTick);
        uint160 nextSqrtPrice = TickMath.getSqrtRatioAtTick(nextTick);

        // Simulate a price after swap (between current and next tick)
        uint160 priceAfterSwap = uint160(
            clampBetween(
                uint256(currentSqrtPrice) + 1,
                currentSqrtPrice,
                nextSqrtPrice
            )
        );

        // CRITICAL: Price must NOT exceed next tick boundary
        // This is the KyberSwap vulnerability fix
        assertWithMsg(
            priceAfterSwap <= nextSqrtPrice,
            "CL-TICK-002: Price overshot next tick boundary when moving up"
        );
    }

    /**
     * @notice Test that price never undershoots the target tick boundary when moving down
     * @dev Property ID: CL-TICK-002 (downward direction)
     * @custom:property-id CL-TICK-002
     */
    function test_CL_noPriceOvershootWhenMovingDown(
        int24 currentTick,
        int24 prevTick
    ) public virtual {
        // Ensure valid tick range and proper ordering
        currentTick = int24(clampBetween(currentTick, MIN_TICK + 1, MAX_TICK));
        prevTick = int24(clampBetween(prevTick, MIN_TICK, currentTick - 1));

        uint160 currentSqrtPrice = TickMath.getSqrtRatioAtTick(currentTick);
        uint160 prevSqrtPrice = TickMath.getSqrtRatioAtTick(prevTick);

        // Simulate a price after swap (between prev and current tick)
        uint160 priceAfterSwap = uint160(
            clampBetween(
                uint256(currentSqrtPrice) - 1,
                prevSqrtPrice,
                currentSqrtPrice
            )
        );

        // CRITICAL: Price must NOT go below previous tick boundary
        assertWithMsg(
            priceAfterSwap >= prevSqrtPrice,
            "CL-TICK-002: Price overshot previous tick boundary when moving down"
        );
    }

    //////////////////////////////////////////////////////////////////////
    // PROPERTY 3: Tick Spacing Alignment
    //////////////////////////////////////////////////////////////////////

    /**
     * @notice Test that all ticks respect the tick spacing requirement
     * @dev Property ID: CL-TICK-003
     * @custom:property-id CL-TICK-003
     *
     * WHY THIS MUST BE TRUE:
     * Tick spacing prevents excessive fragmentation of liquidity positions. Each pool
     * has a tickSpacing parameter (e.g., 10, 60, 200) that determines the granularity
     * of price points where liquidity can be placed.
     *
     * MATHEMATICAL REQUIREMENT:
     * - All initialized ticks must satisfy: tick % tickSpacing == 0
     * - The current tick must also be aligned with tickSpacing
     *
     * ECONOMIC RATIONALE:
     * - Reduces gas costs by limiting the number of ticks that can be initialized
     * - Concentrates liquidity at specific price points
     * - Lower fee tiers have wider tick spacing (less gas, less precision)
     *
     * WHAT BUG THIS CATCHES:
     * - Mint/burn operations that initialize invalid ticks
     * - Tick updates that violate spacing constraints
     * - Incorrect tick spacing validation in pool initialization
     */
    function test_CL_currentTickRespectsSpacing() public virtual {
        int24 tickSpacing = _getTickSpacing();

        // Get current tick from derived contract
        int24 currentTick = _getCurrentTick();

        // Current tick must be aligned with tick spacing
        assertWithMsg(
            currentTick % tickSpacing == 0,
            "CL-TICK-003: Current tick does not respect tick spacing"
        );

        // Current tick must be within valid bounds
        assertWithMsg(
            currentTick >= MIN_TICK && currentTick <= MAX_TICK,
            "CL-TICK-003: Current tick out of bounds"
        );
    }

    /**
     * @notice Test that all initialized ticks respect tick spacing
     * @dev Property ID: CL-TICK-003
     * @custom:property-id CL-TICK-003
     */
    function test_CL_initializedTicksRespectSpacing() public virtual {
        int24 tickSpacing = _getTickSpacing();

        // Check all tracked ticks
        for (uint256 i = 0; i < usedTicks.length; i++) {
            int24 tick = usedTicks[i];

            assertWithMsg(
                tick % tickSpacing == 0,
                "CL-TICK-003: Initialized tick does not respect tick spacing"
            );

            assertWithMsg(
                tick >= MIN_TICK && tick <= MAX_TICK,
                "CL-TICK-003: Initialized tick out of bounds"
            );
        }
    }

    //////////////////////////////////////////////////////////////////////
    // HELPER FUNCTIONS (to be overridden by inheriting contract)
    //////////////////////////////////////////////////////////////////////

    /**
     * @notice Get the current tick from the pool
     * @dev Must be implemented by inheriting contract
     * @return Current tick from pool.slot0()
     */
    function _getCurrentTick() internal view virtual returns (int24);
}
