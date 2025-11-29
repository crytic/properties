// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import "properties/ConcentratedLiquidity/internal/properties/TickMathProperties.sol";
import "properties/ConcentratedLiquidity/internal/properties/LiquidityProperties.sol";
import "properties/ConcentratedLiquidity/internal/properties/MintBurnProperties.sol";
import "properties/ConcentratedLiquidity/internal/properties/SwapProperties.sol";
import "../src/SimpleMockPool.sol";

/**
 * @title Crytic Concentrated Liquidity Internal Test Harness
 * @notice Test harness combining SimpleMockPool with all concentrated liquidity properties
 * @dev This demonstrates internal testing mode where the harness inherits from the pool
 */
contract CryticConcentratedLiquidityInternalHarness is
    SimpleMockPool,
    CryticTickMathProperties,
    CryticLiquidityProperties,
    CryticMintBurnProperties,
    CryticSwapProperties
{
    // Track all initialized ticks for property checks
    int24[] private allTicks;
    mapping(int24 => uint256) private tickToIndex;

    constructor() SimpleMockPool(60) {
        // Initialize pool with some liquidity around current price
        // Current tick is 0, create positions around it
        _mintPosition(USER1, -600, 600, 1000000e18);
        _mintPosition(USER2, -1200, 1200, 500000e18);
        _mintPosition(USER3, -300, 300, 2000000e18);
    }

    //////////////////////////////////////////////////////////////////////
    // IMPLEMENT REQUIRED VIRTUAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////

    function _getCurrentTick() internal view override(
        CryticTickMathProperties,
        CryticLiquidityProperties,
        CryticMintBurnProperties,
        CryticSwapProperties
    ) returns (int24) {
        return tick;
    }

    function _getCurrentLiquidity() internal view override(
        CryticLiquidityProperties,
        CryticMintBurnProperties
    ) returns (uint128) {
        return liquidity;
    }

    function _getSqrtPriceX96() internal view override returns (uint160) {
        return sqrtPriceX96;
    }

    function _getTickSpacing() internal view override returns (int24) {
        return tickSpacing;
    }

    function _getLiquidityNetAtTick(int24 _tick) internal view override(
        CryticLiquidityProperties,
        CryticSwapProperties
    ) returns (int128) {
        (,int128 liquidityNet,) = ticks(_tick);
        return liquidityNet;
    }

    function _getLiquidityGrossAtTick(int24 _tick) internal view override(
        CryticLiquidityProperties,
        CryticMintBurnProperties
    ) returns (uint128) {
        (uint128 liquidityGross,,) = ticks(_tick);
        return liquidityGross;
    }

    function _mintPosition(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) internal override {
        // Track ticks
        _addTickToTracking(tickLower);
        _addTickToTracking(tickUpper);

        // Call the pool's mint function
        this.mint(recipient, tickLower, tickUpper, amount, "");

        // Update base class tracking
        _addTick(tickLower);
        _addTick(tickUpper);
    }

    function _burnPosition(
        address /* owner */,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) internal override {
        // Call the pool's burn function
        this.burn(tickLower, tickUpper, amount);

        // If ticks are no longer initialized, remove from tracking
        (uint128 grossLower,,) = ticks(tickLower);
        (uint128 grossUpper,,) = ticks(tickUpper);

        if (grossLower == 0) {
            _removeTick(tickLower);
            _removeTickFromTracking(tickLower);
        }
        if (grossUpper == 0) {
            _removeTick(tickUpper);
            _removeTickFromTracking(tickUpper);
        }
    }

    function _trySwap(bool zeroForOne, uint256 amountSpecified) internal override returns (bool) {
        try this.swap(
            address(this),
            zeroForOne,
            int256(amountSpecified),
            0, // No price limit
            ""
        ) {
            return true;
        } catch {
            return false;
        }
    }

    function _trySwapWithLimit(
        bool zeroForOne,
        uint256 amountSpecified,
        uint160 sqrtPriceLimitX96
    ) internal override returns (bool) {
        try this.swap(
            address(this),
            zeroForOne,
            int256(amountSpecified),
            sqrtPriceLimitX96,
            ""
        ) {
            return true;
        } catch {
            return false;
        }
    }

    //////////////////////////////////////////////////////////////////////
    // HELPER FUNCTIONS FOR TICK TRACKING
    //////////////////////////////////////////////////////////////////////

    function _addTickToTracking(int24 _tick) private {
        if (tickToIndex[_tick] == 0 && (allTicks.length == 0 || allTicks[0] != _tick)) {
            allTicks.push(_tick);
            tickToIndex[_tick] = allTicks.length; // 1-based index
        }
    }

    function _removeTickFromTracking(int24 _tick) private {
        uint256 index = tickToIndex[_tick];
        if (index > 0) {
            index--; // Convert to 0-based
            if (index < allTicks.length - 1) {
                allTicks[index] = allTicks[allTicks.length - 1];
                tickToIndex[allTicks[index]] = index + 1;
            }
            allTicks.pop();
            delete tickToIndex[_tick];
        }
    }

    //////////////////////////////////////////////////////////////////////
    // PUBLIC FUNCTIONS FOR FUZZING
    //////////////////////////////////////////////////////////////////////

    /**
     * @notice Fuzz target: mint a random position
     */
    function fuzz_mint(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) public {
        // Constrain inputs
        tickLower = int24(clampBetween(tickLower, MIN_TICK, MAX_TICK - tickSpacing));
        tickUpper = int24(clampBetween(tickUpper, tickLower + tickSpacing, MAX_TICK));
        amount = uint128(clampBetween(amount, 1e18, 1000000e18));

        // Align to tick spacing
        tickLower = (tickLower / tickSpacing) * tickSpacing;
        tickUpper = (tickUpper / tickSpacing) * tickSpacing;

        if (tickLower >= tickUpper) return;

        try this.mint(msg.sender, tickLower, tickUpper, amount, "") {
            _addTick(tickLower);
            _addTick(tickUpper);
            _addTickToTracking(tickLower);
            _addTickToTracking(tickUpper);
        } catch {
            // Mint failed, continue fuzzing
        }
    }

    /**
     * @notice Fuzz target: burn a position
     */
    function fuzz_burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) public {
        // Constrain inputs
        tickLower = int24(clampBetween(tickLower, MIN_TICK, MAX_TICK - tickSpacing));
        tickUpper = int24(clampBetween(tickUpper, tickLower + tickSpacing, MAX_TICK));
        amount = uint128(clampBetween(amount, 1e18, 1000000e18));

        // Align to tick spacing
        tickLower = (tickLower / tickSpacing) * tickSpacing;
        tickUpper = (tickUpper / tickSpacing) * tickSpacing;

        if (tickLower >= tickUpper) return;

        try this.burn(tickLower, tickUpper, amount) {
            // Update tracking if ticks are no longer initialized
            (uint128 grossLower,,) = ticks(tickLower);
            (uint128 grossUpper,,) = ticks(tickUpper);

            if (grossLower == 0) {
                _removeTick(tickLower);
                _removeTickFromTracking(tickLower);
            }
            if (grossUpper == 0) {
                _removeTick(tickUpper);
                _removeTickFromTracking(tickUpper);
            }
        } catch {
            // Burn failed, continue fuzzing
        }
    }

    /**
     * @notice Fuzz target: perform a swap
     */
    function fuzz_swap(bool zeroForOne, uint256 amount) public {
        amount = clampBetween(amount, 1e18, 1000000e18);

        try this.swap(
            msg.sender,
            zeroForOne,
            int256(amount),
            0, // No price limit
            ""
        ) {
            // Swap succeeded
        } catch {
            // Swap failed, continue fuzzing
        }
    }
}
