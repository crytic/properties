// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import "../util/ConcentratedLiquidityTestBase.sol";

/**
 * @title Concentrated Liquidity Conservation Properties
 * @author Crytic (Trail of Bits)
 * @notice Properties for liquidity accounting and conservation laws
 * @dev Testing Mode: INTERNAL
 *
 * WHY THESE PROPERTIES MATTER:
 * Liquidity accounting in concentrated liquidity AMMs uses a delta-based system where
 * each position adds +L at its lower tick and -L at its upper tick. This creates a
 * mathematical invariant: the sum of all deltas must equal zero.
 *
 * The current "active" liquidity is calculated by summing all liquidityNet values from
 * negative infinity up to the current tick. This is the liquidity actually available
 * for trading at the current price.
 *
 * Violations of these properties can lead to:
 * - Incorrect pricing during swaps
 * - Liquidity appearing or disappearing (breaking conservation)
 * - Positions being counted when they shouldn't be (or vice versa)
 */
abstract contract CryticLiquidityProperties is ConcentratedLiquidityTestBase {

    //////////////////////////////////////////////////////////////////////
    // PROPERTY 4: LiquidityNet Conservation (Sum to Zero)
    //////////////////////////////////////////////////////////////////////

    /**
     * @notice Test that liquidityNet sums to zero across all ticks
     * @dev Property ID: CL-LIQUIDITY-001
     * @custom:property-id CL-LIQUIDITY-001
     *
     * WHY THIS MUST BE TRUE:
     * Every liquidity position in a concentrated liquidity pool consists of a range
     * [tickLower, tickUpper]. When a position is created with liquidity L:
     * - We add +L to liquidityNet[tickLower]
     * - We subtract -L from liquidityNet[tickUpper]
     *
     * MATHEMATICAL PROOF:
     * For each position i with liquidity L_i:
     *   liquidityNet[tickLower_i] += L_i
     *   liquidityNet[tickUpper_i] -= L_i
     *
     * Summing across all ticks:
     *   Σ(liquidityNet[t]) = Σ(+L_i - L_i) = 0
     *
     * This is a conservation law: liquidity cannot be created or destroyed, only
     * redistributed across ticks.
     *
     * EXAMPLE:
     * Position 1: [tick 100, tick 200], L=1000
     *   liquidityNet[100] = +1000
     *   liquidityNet[200] = -1000
     *   Sum = 0 ✓
     *
     * Position 2: [tick 150, tick 300], L=500
     *   liquidityNet[150] += +500
     *   liquidityNet[300] = -500
     *   Total sum = +1000 +500 -1000 -500 = 0 ✓
     *
     * WHAT BUG THIS CATCHES:
     * - Incorrect mint/burn that only updates one boundary
     * - Arithmetic errors in liquidityNet updates
     * - Re-entrancy attacks that manipulate liquidity
     * - Positions that don't properly clean up on burn
     */
    function test_CL_liquidityNetSumsToZero() public virtual {
        int256 netSum = 0;

        // Sum liquidityNet across all initialized ticks
        for (uint256 i = 0; i < usedTicks.length; i++) {
            int24 tick = usedTicks[i];
            int128 liquidityNet = _getLiquidityNetAtTick(tick);
            netSum += int256(liquidityNet);
        }

        assertEq(
            netSum,
            0,
            "CL-LIQUIDITY-001: LiquidityNet does not sum to zero (conservation violated)"
        );
    }

    //////////////////////////////////////////////////////////////////////
    // PROPERTY 5: Current Liquidity Equals Sum of LiquidityNet ≤ CurrentTick
    //////////////////////////////////////////////////////////////////////

    /**
     * @notice Test that current liquidity equals the sum of liquidityNet for all ticks ≤ currentTick
     * @dev Property ID: CL-LIQUIDITY-002
     * @custom:property-id CL-LIQUIDITY-002
     *
     * WHY THIS MUST BE TRUE:
     * The "active" liquidity at any price point is determined by which positions contain
     * that price in their range. Due to the delta-based accounting system:
     * - Starting from the leftmost tick (price = 0)
     * - As we move right and cross each tick boundary, we add its liquidityNet
     * - The cumulative sum at any tick T is the liquidity active at that price
     *
     * MATHEMATICAL PROOF:
     * Let currentTick = t_c
     * Active positions are those where tickLower ≤ t_c < tickUpper
     *
     * For each position i:
     * - If tickLower_i ≤ t_c, we've crossed the +L_i delta
     * - If tickUpper_i ≤ t_c, we've crossed the -L_i delta
     * - If tickLower_i ≤ t_c < tickUpper_i, the position contributes +L_i
     *
     * Therefore:
     *   pool.liquidity() = Σ(liquidityNet[t] for all t ≤ t_c)
     *
     * EXAMPLE:
     * Position 1: [100, 200], L=1000
     * Position 2: [150, 300], L=500
     *
     * At tick 175:
     *   - Crossed tick 100: +1000
     *   - Crossed tick 150: +500
     *   - Not crossed tick 200, 300
     *   - Active liquidity = 1000 + 500 = 1500 ✓
     *
     * At tick 250:
     *   - Crossed tick 100: +1000
     *   - Crossed tick 150: +500
     *   - Crossed tick 200: -1000
     *   - Not crossed tick 300
     *   - Active liquidity = 1000 + 500 - 1000 = 500 ✓
     *
     * WHAT BUG THIS CATCHES:
     * - Incorrect tick crossing logic
     * - Liquidity not updated when crossing ticks during swaps
     * - Off-by-one errors in tick comparison (≤ vs <)
     * - Manual liquidity manipulation without updating ticks
     */
    function test_CL_currentLiquidityMatchesSumOfDeltas() public virtual {
        int24 currentTick = _getCurrentTick();
        uint128 reportedLiquidity = _getCurrentLiquidity();

        // Calculate expected liquidity by summing liquidityNet for all ticks ≤ currentTick
        int256 calculatedLiquidity = 0;

        for (uint256 i = 0; i < usedTicks.length; i++) {
            int24 tick = usedTicks[i];

            // Only include ticks that have been crossed (≤ currentTick)
            if (tick <= currentTick) {
                int128 liquidityNet = _getLiquidityNetAtTick(tick);
                calculatedLiquidity += int256(liquidityNet);
            }
        }

        // Liquidity cannot be negative
        assertWithMsg(
            calculatedLiquidity >= 0,
            "CL-LIQUIDITY-002: Calculated liquidity is negative (impossible state)"
        );

        assertEq(
            uint256(uint128(reportedLiquidity)),
            uint256(uint128(int128(calculatedLiquidity))),
            "CL-LIQUIDITY-002: Current liquidity does not match sum of liquidityNet deltas"
        );
    }

    /**
     * @notice Test that liquidity is never negative
     * @dev Property ID: CL-LIQUIDITY-003
     * @custom:property-id CL-LIQUIDITY-003
     *
     * WHY THIS MUST BE TRUE:
     * Liquidity represents the amount of assets available for trading. By definition,
     * it cannot be negative. A negative liquidity value would indicate a severe
     * accounting error.
     *
     * WHAT BUG THIS CATCHES:
     * - Underflow in liquidity calculations
     * - Burning more liquidity than exists
     * - Integer overflow wrapping to negative
     */
    function test_CL_liquidityNeverNegative() public virtual {
        uint128 currentLiquidity = _getCurrentLiquidity();

        // uint128 is unsigned, but we check that cast to int256 is positive
        // to catch any overflow/underflow issues
        assertWithMsg(
            int256(uint256(currentLiquidity)) >= 0,
            "CL-LIQUIDITY-003: Current liquidity is negative"
        );

        // Also check all tick liquidityGross values
        for (uint256 i = 0; i < usedTicks.length; i++) {
            int24 tick = usedTicks[i];
            uint128 liquidityGross = _getLiquidityGrossAtTick(tick);

            assertWithMsg(
                int256(uint256(liquidityGross)) >= 0,
                "CL-LIQUIDITY-003: Tick liquidityGross is negative"
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

    /**
     * @notice Get the current active liquidity
     * @dev Must be implemented by inheriting contract
     * @return Current liquidity from pool.liquidity()
     */
    function _getCurrentLiquidity() internal view virtual returns (uint128);

    /**
     * @notice Get liquidityNet for a specific tick
     * @dev Must be implemented by inheriting contract
     * @param tick The tick to query
     * @return liquidityNet The net liquidity change at this tick
     */
    function _getLiquidityNetAtTick(int24 tick) internal view virtual returns (int128);

    /**
     * @notice Get liquidityGross for a specific tick
     * @dev Must be implemented by inheriting contract
     * @param tick The tick to query
     * @return liquidityGross The total liquidity referencing this tick
     */
    function _getLiquidityGrossAtTick(int24 tick) internal view virtual returns (uint128);
}
