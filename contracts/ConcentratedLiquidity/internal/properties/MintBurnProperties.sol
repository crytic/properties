// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import "../util/ConcentratedLiquidityTestBase.sol";

/**
 * @title Concentrated Liquidity Mint and Burn Properties
 * @author Crytic (Trail of Bits)
 * @notice Properties for liquidity position management
 * @dev Testing Mode: INTERNAL
 *
 * WHY THESE PROPERTIES MATTER:
 * Mint and burn operations are the core mechanisms for providing and removing liquidity
 * in concentrated liquidity AMMs. These operations update three critical data structures:
 * 1. liquidityGross[tick] - Total liquidity referencing this tick (for initialization)
 * 2. liquidityNet[tick] - Delta applied when crossing this tick
 * 3. pool.liquidity() - Currently active liquidity (only if position is in range)
 *
 * The asymmetric update pattern (+L at lower, -L at upper) is fundamental to how
 * concentrated liquidity tracking works. Violations can lead to liquidity being
 * counted incorrectly, positions not being properly activated/deactivated, or
 * accounting inconsistencies that can be exploited.
 */
abstract contract CryticMintBurnProperties is ConcentratedLiquidityTestBase {

    //////////////////////////////////////////////////////////////////////
    // PROPERTY 6: Mint Increases Current Liquidity When In Range
    //////////////////////////////////////////////////////////////////////

    /**
     * @notice Test that minting increases current liquidity if position is in range
     * @dev Property ID: CL-MINT-001
     * @custom:property-id CL-MINT-001
     *
     * WHY THIS MUST BE TRUE:
     * A position is "in range" (active) when: tickLower ≤ currentTick < tickUpper
     * Only in-range positions contribute to the liquidity available for swaps.
     *
     * When minting a position:
     * - If in range: pool.liquidity() must increase by the minted amount
     * - If out of range: pool.liquidity() should NOT change (position is inactive)
     *
     * MATHEMATICAL DEFINITION:
     * Let L be the amount minted, t_c be the current tick
     * If tickLower ≤ t_c < tickUpper:
     *   pool.liquidity_after = pool.liquidity_before + L
     * Else:
     *   pool.liquidity_after = pool.liquidity_before
     *
     * EXAMPLE:
     * Current tick = 150
     * Mint position [100, 200] with L=1000
     *   → 100 ≤ 150 < 200, position is IN RANGE
     *   → pool.liquidity increases by 1000 ✓
     *
     * Mint position [200, 300] with L=500
     *   → NOT (200 ≤ 150 < 300), position is OUT OF RANGE
     *   → pool.liquidity unchanged ✓
     *
     * WHAT BUG THIS CATCHES:
     * - Position activated when it shouldn't be
     * - Incorrect range check (wrong inequality direction)
     * - Liquidity updated regardless of tick position
     * - Off-by-one errors in tick comparison
     */
    function test_CL_mintIncreasesCurrentLiquidityWhenInRange(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidityDelta
    ) public virtual {
        // Setup: Constrain to valid values
        tickLower = int24(clampBetween(tickLower, MIN_TICK, MAX_TICK - 1));
        tickUpper = int24(clampBetween(tickUpper, tickLower + 1, MAX_TICK));
        liquidityDelta = uint128(clampBetween(liquidityDelta, 1, type(uint64).max));

        // Ensure ticks respect spacing
        int24 tickSpacing = _getTickSpacing();
        tickLower = (tickLower / tickSpacing) * tickSpacing;
        tickUpper = (tickUpper / tickSpacing) * tickSpacing;
        if (tickLower >= tickUpper) return;

        int24 currentTick = _getCurrentTick();
        uint128 liquidityBefore = _getCurrentLiquidity();

        // Perform mint
        _mintPosition(USER1, tickLower, tickUpper, liquidityDelta);

        uint128 liquidityAfter = _getCurrentLiquidity();

        // Check if position is in range
        bool inRange = (tickLower <= currentTick) && (currentTick < tickUpper);

        if (inRange) {
            assertEq(
                liquidityAfter,
                liquidityBefore + liquidityDelta,
                "CL-MINT-001: Minting in-range position did not increase current liquidity"
            );
        } else {
            assertEq(
                liquidityAfter,
                liquidityBefore,
                "CL-MINT-001: Minting out-of-range position changed current liquidity"
            );
        }
    }

    //////////////////////////////////////////////////////////////////////
    // PROPERTY 7: Mint Always Increases LiquidityGross
    //////////////////////////////////////////////////////////////////////

    /**
     * @notice Test that minting always increases liquidityGross at both ticks
     * @dev Property ID: CL-MINT-002
     * @custom:property-id CL-MINT-002
     *
     * WHY THIS MUST BE TRUE:
     * liquidityGross[tick] represents the total absolute amount of liquidity that
     * references this tick as either a lower or upper boundary. It is used to:
     * 1. Track whether a tick is initialized (liquidityGross > 0)
     * 2. Determine when a tick can be deleted (liquidityGross == 0)
     *
     * Unlike liquidityNet (which can be positive or negative), liquidityGross only
     * increases when adding liquidity and only decreases when removing liquidity.
     *
     * MATHEMATICAL DEFINITION:
     * When minting L at [tickLower, tickUpper]:
     *   liquidityGross[tickLower] += L
     *   liquidityGross[tickUpper] += L
     *
     * Both ticks get the FULL amount added to their gross, regardless of whether
     * the liquidityNet is +L or -L.
     *
     * EXAMPLE:
     * Initial state: liquidityGross[100] = 500
     * Mint position [100, 200] with L=1000
     *   → liquidityGross[100] = 500 + 1000 = 1500 ✓
     *   → liquidityGross[200] = 0 + 1000 = 1000 ✓
     *
     * WHAT BUG THIS CATCHES:
     * - Tick not initialized when it should be
     * - liquidityGross decreasing on mint (impossible)
     * - Only one boundary updated
     * - Incorrect gross calculation
     */
    function test_CL_mintIncreasesLiquidityGross(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidityDelta
    ) public virtual {
        // Setup: Constrain to valid values
        tickLower = int24(clampBetween(tickLower, MIN_TICK, MAX_TICK - 1));
        tickUpper = int24(clampBetween(tickUpper, tickLower + 1, MAX_TICK));
        liquidityDelta = uint128(clampBetween(liquidityDelta, 1, type(uint64).max));

        // Ensure ticks respect spacing
        int24 tickSpacing = _getTickSpacing();
        tickLower = (tickLower / tickSpacing) * tickSpacing;
        tickUpper = (tickUpper / tickSpacing) * tickSpacing;
        if (tickLower >= tickUpper) return;

        uint128 grossLowerBefore = _getLiquidityGrossAtTick(tickLower);
        uint128 grossUpperBefore = _getLiquidityGrossAtTick(tickUpper);

        // Perform mint
        _mintPosition(USER1, tickLower, tickUpper, liquidityDelta);

        uint128 grossLowerAfter = _getLiquidityGrossAtTick(tickLower);
        uint128 grossUpperAfter = _getLiquidityGrossAtTick(tickUpper);

        assertEq(
            grossLowerAfter,
            grossLowerBefore + liquidityDelta,
            "CL-MINT-002: Minting did not increase liquidityGross at tickLower"
        );

        assertEq(
            grossUpperAfter,
            grossUpperBefore + liquidityDelta,
            "CL-MINT-002: Minting did not increase liquidityGross at tickUpper"
        );
    }

    //////////////////////////////////////////////////////////////////////
    // PROPERTY 8: Mint Updates LiquidityNet Asymmetrically
    //////////////////////////////////////////////////////////////////////

    /**
     * @notice Test that minting updates liquidityNet asymmetrically (+L at lower, -L at upper)
     * @dev Property ID: CL-MINT-003
     * @custom:property-id CL-MINT-003
     *
     * WHY THIS MUST BE TRUE:
     * The asymmetric update pattern is the foundation of concentrated liquidity accounting.
     * When you provide liquidity in range [tickLower, tickUpper]:
     *
     * - At tickLower: Add +L to liquidityNet
     *   → When price crosses UP through this tick, activate the position
     *
     * - At tickUpper: Add -L to liquidityNet
     *   → When price crosses UP through this tick, deactivate the position
     *
     * This creates a "wave" where liquidity is added when entering the range and
     * removed when exiting it, as the price moves.
     *
     * MATHEMATICAL DEFINITION:
     * When minting L at [tickLower, tickUpper]:
     *   liquidityNet[tickLower] += L
     *   liquidityNet[tickUpper] -= L
     *
     * The signs MUST be opposite and equal in magnitude.
     *
     * DETAILED EXAMPLE:
     * Mint position [100, 200] with L=1000
     *
     * Before:
     *   liquidityNet[100] = 0
     *   liquidityNet[200] = 0
     *
     * After:
     *   liquidityNet[100] = +1000
     *   liquidityNet[200] = -1000
     *
     * Price sweep simulation:
     * - Start at tick 50, liquidity = 0
     * - Cross tick 100 going up: liquidity += 1000 → liquidity = 1000 ✓
     * - Cross tick 200 going up: liquidity -= 1000 → liquidity = 0 ✓
     *
     * WHY THE ASYMMETRY EXISTS:
     * When price is BELOW the range: position is inactive (all token0)
     * When price is IN the range: position is active (mixed token0/token1)
     * When price is ABOVE the range: position is inactive (all token1)
     *
     * WHAT BUG THIS CATCHES:
     * - Both ticks updated with same sign (symmetric update - WRONG)
     * - Only one tick updated
     * - Wrong magnitude (+L at one, -2L at other)
     * - Sign flipped (would cause inverse behavior)
     */
    function test_CL_mintUpdatesLiquidityNetAsymmetrically(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidityDelta
    ) public virtual {
        // Setup: Constrain to valid values
        tickLower = int24(clampBetween(tickLower, MIN_TICK, MAX_TICK - 1));
        tickUpper = int24(clampBetween(tickUpper, tickLower + 1, MAX_TICK));
        liquidityDelta = uint128(clampBetween(liquidityDelta, 1, type(uint64).max));

        // Ensure ticks respect spacing
        int24 tickSpacing = _getTickSpacing();
        tickLower = (tickLower / tickSpacing) * tickSpacing;
        tickUpper = (tickUpper / tickSpacing) * tickSpacing;
        if (tickLower >= tickUpper) return;

        int128 netLowerBefore = _getLiquidityNetAtTick(tickLower);
        int128 netUpperBefore = _getLiquidityNetAtTick(tickUpper);

        // Perform mint
        _mintPosition(USER1, tickLower, tickUpper, liquidityDelta);

        int128 netLowerAfter = _getLiquidityNetAtTick(tickLower);
        int128 netUpperAfter = _getLiquidityNetAtTick(tickUpper);

        // Check asymmetric update
        int128 netLowerDelta = netLowerAfter - netLowerBefore;
        int128 netUpperDelta = netUpperAfter - netUpperBefore;

        assertEq(
            netLowerDelta,
            int128(liquidityDelta),
            "CL-MINT-003: LiquidityNet at tickLower did not increase by +L"
        );

        assertEq(
            netUpperDelta,
            -int128(liquidityDelta),
            "CL-MINT-003: LiquidityNet at tickUpper did not decrease by -L"
        );

        // Verify asymmetry: the deltas must be equal and opposite
        assertEq(
            netLowerDelta,
            -netUpperDelta,
            "CL-MINT-003: LiquidityNet deltas are not equal and opposite (asymmetry violated)"
        );
    }

    //////////////////////////////////////////////////////////////////////
    // PROPERTY 9: Burn Reverses Mint
    //////////////////////////////////////////////////////////////////////

    /**
     * @notice Test that burning liquidity reverses the effects of minting
     * @dev Property ID: CL-BURN-001
     * @custom:property-id CL-BURN-001
     *
     * WHY THIS MUST BE TRUE:
     * Burning (removing) liquidity must be the exact inverse of minting (adding) liquidity.
     * All state changes must be reversed:
     * 1. liquidityGross[tickLower] decreases by L
     * 2. liquidityGross[tickUpper] decreases by L
     * 3. liquidityNet[tickLower] decreases by L
     * 4. liquidityNet[tickUpper] increases by L (removing -L)
     * 5. pool.liquidity() decreases by L (only if position is in range)
     *
     * MATHEMATICAL DEFINITION:
     * If mint(L) followed by burn(L) on the same position:
     *   Final state = Initial state
     *
     * EXAMPLE:
     * Initial: liquidityGross[100] = 1000, liquidityNet[100] = +500, liquidity = 2000
     * Mint [100, 200] with L=1000:
     *   → liquidityGross[100] = 2000
     *   → liquidityNet[100] = +1500
     *   → liquidity = 3000 (if in range)
     * Burn [100, 200] with L=1000:
     *   → liquidityGross[100] = 1000 (back to original)
     *   → liquidityNet[100] = +500 (back to original)
     *   → liquidity = 2000 (back to original)
     *
     * WHAT BUG THIS CATCHES:
     * - Burn not properly reversing mint
     * - Asymmetric burn (different logic than mint)
     * - Liquidity leak (mint adds X, burn removes Y where Y ≠ X)
     * - Tick not cleaned up when liquidityGross reaches 0
     */
    function test_CL_burnReversesMint(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidityDelta
    ) public virtual {
        // Setup: Constrain to valid values
        tickLower = int24(clampBetween(tickLower, MIN_TICK, MAX_TICK - 1));
        tickUpper = int24(clampBetween(tickUpper, tickLower + 1, MAX_TICK));
        liquidityDelta = uint128(clampBetween(liquidityDelta, 1, type(uint64).max));

        // Ensure ticks respect spacing
        int24 tickSpacing = _getTickSpacing();
        tickLower = (tickLower / tickSpacing) * tickSpacing;
        tickUpper = (tickUpper / tickSpacing) * tickSpacing;
        if (tickLower >= tickUpper) return;

        // Capture initial state
        uint128 liquidityBefore = _getCurrentLiquidity();
        uint128 grossLowerBefore = _getLiquidityGrossAtTick(tickLower);
        uint128 grossUpperBefore = _getLiquidityGrossAtTick(tickUpper);
        int128 netLowerBefore = _getLiquidityNetAtTick(tickLower);
        int128 netUpperBefore = _getLiquidityNetAtTick(tickUpper);

        // Perform mint then burn
        _mintPosition(USER1, tickLower, tickUpper, liquidityDelta);
        _burnPosition(USER1, tickLower, tickUpper, liquidityDelta);

        // Capture final state
        uint128 liquidityAfter = _getCurrentLiquidity();
        uint128 grossLowerAfter = _getLiquidityGrossAtTick(tickLower);
        uint128 grossUpperAfter = _getLiquidityGrossAtTick(tickUpper);
        int128 netLowerAfter = _getLiquidityNetAtTick(tickLower);
        int128 netUpperAfter = _getLiquidityNetAtTick(tickUpper);

        // All state should be back to initial values
        assertEq(
            liquidityAfter,
            liquidityBefore,
            "CL-BURN-001: Burn did not reverse mint (current liquidity)"
        );

        assertEq(
            grossLowerAfter,
            grossLowerBefore,
            "CL-BURN-001: Burn did not reverse mint (liquidityGross at tickLower)"
        );

        assertEq(
            grossUpperAfter,
            grossUpperBefore,
            "CL-BURN-001: Burn did not reverse mint (liquidityGross at tickUpper)"
        );

        assertEq(
            netLowerAfter,
            netLowerBefore,
            "CL-BURN-001: Burn did not reverse mint (liquidityNet at tickLower)"
        );

        assertEq(
            netUpperAfter,
            netUpperBefore,
            "CL-BURN-001: Burn did not reverse mint (liquidityNet at tickUpper)"
        );
    }

    //////////////////////////////////////////////////////////////////////
    // HELPER FUNCTIONS (to be overridden by inheriting contract)
    //////////////////////////////////////////////////////////////////////

    /**
     * @notice Get the current tick from the pool
     */
    function _getCurrentTick() internal view virtual returns (int24);

    /**
     * @notice Get the current active liquidity
     */
    function _getCurrentLiquidity() internal view virtual returns (uint128);

    /**
     * @notice Get liquidityGross for a specific tick
     */
    function _getLiquidityGrossAtTick(int24 tick) internal view virtual returns (uint128);

    /**
     * @notice Get liquidityNet for a specific tick
     */
    function _getLiquidityNetAtTick(int24 tick) internal view virtual returns (int128);

    /**
     * @notice Get tick spacing from the pool
     */
    function _getTickSpacing() internal view virtual returns (int24);

    /**
     * @notice Mint a liquidity position
     */
    function _mintPosition(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) internal virtual;

    /**
     * @notice Burn a liquidity position
     */
    function _burnPosition(
        address owner,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) internal virtual;
}
