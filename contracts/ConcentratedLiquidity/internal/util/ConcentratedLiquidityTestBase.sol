// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import "../../../util/PropertiesConstants.sol";
import "../../../util/PropertiesAsserts.sol";
import "../../../util/IHevm.sol";

/**
 * @title Concentrated Liquidity Test Base
 * @notice Base contract for testing concentrated liquidity pools
 * @dev Provides common utilities and tracking for property tests
 */
abstract contract ConcentratedLiquidityTestBase is
    PropertiesAsserts,
    PropertiesConstants
{
    // Minimum and maximum tick values (Uniswap V3 standard)
    int24 internal constant MIN_TICK = -887272;
    int24 internal constant MAX_TICK = 887272;

    // Minimum and maximum sqrt price values
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    // Track all ticks that have been initialized
    int24[] internal usedTicks;
    mapping(int24 => bool) internal tickExists;

    /**
     * @notice Add a tick to the tracking array
     * @param tick The tick to add
     */
    function _addTick(int24 tick) internal {
        if (!tickExists[tick]) {
            usedTicks.push(tick);
            tickExists[tick] = true;
        }
    }

    /**
     * @notice Remove a tick from tracking
     * @param tick The tick to remove
     */
    function _removeTick(int24 tick) internal {
        if (tickExists[tick]) {
            for (uint256 i = 0; i < usedTicks.length; i++) {
                if (usedTicks[i] == tick) {
                    usedTicks[i] = usedTicks[usedTicks.length - 1];
                    usedTicks.pop();
                    break;
                }
            }
            tickExists[tick] = false;
        }
    }

    /**
     * @notice Get tick spacing for the pool
     * @dev Must be implemented by inheriting contract
     */
    function _getTickSpacing() internal view virtual returns (int24);

    /**
     * @notice Check if a tick is valid given tick spacing
     */
    function _isValidTick(int24 tick) internal view returns (bool) {
        int24 tickSpacing = _getTickSpacing();
        return tick % tickSpacing == 0 && tick >= MIN_TICK && tick <= MAX_TICK;
    }
}
