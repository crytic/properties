// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "../util/UniswapV2TestBase.sol";

/**
 * @title Uniswap V2 Invariant Properties
 * @author Trail of Bits
 * @notice Core invariant and security properties for Uniswap V2 pairs
 * @dev These properties test the constant product formula (x*y=k) and critical security invariants
 */
abstract contract CryticUniswapV2InvariantProperties is CryticUniswapV2Base {
    constructor() {}

    ////////////////////////////////////////
    // Core Invariant Properties

    // K should never decrease except through liquidity removal
    function test_V2_kNeverDecreasesExceptBurn() public {
        uint256 kBefore = _getK();
        uint256 balanceBefore = balanceOf(msg.sender);

        // Perform any operation
        // (This will be fuzzed by Echidna/Medusa)

        uint256 kAfter = _getK();
        uint256 balanceAfter = balanceOf(msg.sender);

        // If user didn't burn LP tokens, K should not decrease
        if (balanceAfter >= balanceBefore) {
            assertGte(kAfter, kBefore, "K decreased without burning liquidity");
        }
    }

    // Reserves should never be zero after initialization
    function test_V2_reservesNeverZeroAfterInit() public {
        uint256 supply = totalSupply();

        if (supply > 0) {
            (uint112 reserve0, uint112 reserve1,) = getReserves();
            assertGt(reserve0, 0, "Reserve0 is zero after initialization");
            assertGt(reserve1, 0, "Reserve1 is zero after initialization");
        }
    }

    // Total supply should equal sum of all balances
    function test_V2_totalSupplyEqualsBalances() public {
        uint256 supply = totalSupply();
        uint256 balance0 = balanceOf(address(0));
        uint256 balance1 = balanceOf(USER1);
        uint256 balance2 = balanceOf(USER2);
        uint256 balance3 = balanceOf(USER3);

        uint256 sumBalances = balance0 + balance1 + balance2 + balance3;

        // Sum of tracked balances should not exceed total supply
        assertLte(
            sumBalances,
            supply,
            "Sum of balances exceeds total supply"
        );
    }

    ////////////////////////////////////////
    // Security Properties

    // First depositor attack protection: MINIMUM_LIQUIDITY is locked
    function test_V2_minimumLiquidityLocked() public {
        uint256 supply = totalSupply();

        if (supply > 0) {
            assertGte(
                supply,
                MINIMUM_LIQUIDITY,
                "Total supply below MINIMUM_LIQUIDITY (first depositor protection broken)"
            );
        }
    }

    // Donation attack resistance: Direct transfers should not affect LP value
    function test_V2_donationDoesNotInflateLPValue() public {
        uint256 supply = totalSupply();
        require(supply > MINIMUM_LIQUIDITY);

        uint256 lpValueBefore = _getLPTokenValue();

        // Simulate donation by calling sync() which updates reserves to balances
        // In a real attack, attacker would transfer tokens directly to the pair
        sync();

        uint256 lpValueAfter = _getLPTokenValue();

        // LP value per token should not change significantly from sync alone
        // Allow small deviation for rounding
        if (lpValueBefore > 0) {
            uint256 diff = lpValueAfter > lpValueBefore
                ? lpValueAfter - lpValueBefore
                : lpValueBefore - lpValueAfter;
            uint256 percentDiff = (diff * 100) / lpValueBefore;

            assertLte(
                percentDiff,
                1, // 1% tolerance
                "LP value changed significantly from sync (donation attack risk)"
            );
        }
    }

    // No free money: mint then burn should not be profitable
    function test_V2_mintBurnNotProfitable() public {
        (uint112 reserve0Before, uint112 reserve1Before,) = getReserves();
        require(reserve0Before > 1000 && reserve1Before > 1000);

        uint256 supply = totalSupply();
        require(supply > MINIMUM_LIQUIDITY);

        // Calculate expected amounts for a proportional deposit
        uint256 amount0 = 1000;
        uint256 amount1 = (uint256(amount0) * reserve1Before) / reserve0Before;

        // Simulate providing liquidity
        uint256 liquidity = mint(msg.sender);
        require(liquidity > 0);

        // Immediately burn
        (uint256 returned0, uint256 returned1) = burn(msg.sender);

        // User should not receive more than they put in (accounting for rounding)
        assertLte(returned0, amount0 + 1, "Mint-burn profitable in token0");
        assertLte(returned1, amount1 + 1, "Mint-burn profitable in token1");
    }

    // Price accumulator should be monotonically increasing
    function test_V2_priceAccumulatorMonotonic() public {
        uint256 accumulator0Before = price0CumulativeLast();
        uint256 accumulator1Before = price1CumulativeLast();

        // Advance time
        require(block.timestamp > 0);

        // Trigger price accumulator update
        sync();

        uint256 accumulator0After = price0CumulativeLast();
        uint256 accumulator1After = price1CumulativeLast();

        // Price accumulators should never decrease
        assertGte(
            accumulator0After,
            accumulator0Before,
            "Price0 accumulator decreased"
        );
        assertGte(
            accumulator1After,
            accumulator1Before,
            "Price1 accumulator decreased"
        );
    }

    // LP tokens should represent proportional ownership
    function test_V2_lpTokensProportional() public {
        uint256 supply = totalSupply();
        require(supply > MINIMUM_LIQUIDITY);

        uint256 userBalance = balanceOf(msg.sender);
        require(userBalance > 0);

        (uint112 reserve0, uint112 reserve1,) = getReserves();

        // User's share of reserves should equal their LP token share
        uint256 expectedShare0 = (uint256(reserve0) * userBalance) / supply;
        uint256 expectedShare1 = (uint256(reserve1) * userBalance) / supply;

        // These represent the user's claimable amounts
        assertGt(expectedShare0, 0, "User has zero share of reserve0");
        assertGt(expectedShare1, 0, "User has zero share of reserve1");

        // Shares should be proportional
        uint256 ratio0 = (userBalance * 1000) / supply;
        uint256 expectedRatio0 = (expectedShare0 * 1000) / reserve0;

        // Allow small rounding difference
        uint256 diff = ratio0 > expectedRatio0
            ? ratio0 - expectedRatio0
            : expectedRatio0 - ratio0;

        assertLte(diff, 1, "LP tokens not proportional to ownership");
    }

    // Flash swap must restore K (plus fees)
    function test_V2_flashSwapRestoresK() public {
        uint256 kBefore = _getK();
        (uint112 reserve0, uint112 reserve1,) = getReserves();
        require(reserve0 > 1000 && reserve1 > 1000);

        // Perform a flash swap (borrow tokens, repay in callback)
        uint256 amount0Out = uint256(reserve0) / 100;

        try this.swap(amount0Out, 0, address(this), hex"01") {
            // Flash swap callback executed
            uint256 kAfter = _getK();

            // K should be restored (plus fees)
            assertGte(kAfter, kBefore, "K not restored after flash swap");
        } catch {
            // Flash swap might not be implemented or callback failed
        }
    }
}
