// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "../util/UniswapV2TestBase.sol";

/**
 * @title Uniswap V2 Swap Properties
 * @author Trail of Bits
 * @notice Properties for testing token swaps in Uniswap V2 pairs
 */
abstract contract CryticUniswapV2SwapProperties is CryticUniswapV2Base {
    constructor() {}

    ////////////////////////////////////////
    // Properties

    // Swapping should not decrease K (should increase due to fees)
    function test_V2_swapDoesNotDecreaseK() public {
        uint256 kBefore = _getK();
        (uint112 reserve0Before, uint112 reserve1Before,) = getReserves();
        require(reserve0Before > 0 && reserve1Before > 0);

        // Perform a swap (amount0Out > 0 means buying token0)
        uint256 amount0Out = uint256(reserve0Before) / 100; // 1% of reserves
        require(amount0Out > 0);

        swap(amount0Out, 0, msg.sender, "");

        uint256 kAfter = _getK();
        assertGte(kAfter, kBefore, "K decreased after swap");
    }

    // Swapping should move price in correct direction
    function test_V2_swapMovesPriceCorrectly() public {
        (uint112 reserve0Before, uint112 reserve1Before,) = getReserves();
        require(reserve0Before > 0 && reserve1Before > 0);

        uint256 price0Before = _getPrice0();

        // Buy token0 (sell token1)
        uint256 amount0Out = uint256(reserve0Before) / 100;
        require(amount0Out > 0 && amount0Out < reserve0Before);

        swap(amount0Out, 0, msg.sender, "");

        uint256 price0After = _getPrice0();

        // Buying token0 should increase its price (decrease reserve0, increase reserve1)
        assertGt(
            price0After,
            price0Before,
            "Price did not move correctly after swap"
        );
    }

    // Swapping should not decrease LP token balance (unless fees are on)
    function test_V2_swapDoesNotDecreaseLPBalance() public {
        uint256 balanceBefore = balanceOf(msg.sender);
        (uint112 reserve0Before, uint112 reserve1Before,) = getReserves();
        require(reserve0Before > 0 && reserve1Before > 0);

        uint256 amount0Out = uint256(reserve0Before) / 100;
        require(amount0Out > 0 && amount0Out < reserve0Before);

        swap(amount0Out, 0, msg.sender, "");

        uint256 balanceAfter = balanceOf(msg.sender);

        // LP balance should not decrease from a swap (might increase if protocol fees are on)
        assertGte(
            balanceAfter,
            balanceBefore,
            "LP balance decreased after swap"
        );
    }

    // Swapping zero amounts should not change reserves
    function test_V2_swapZeroAmountNoEffect() public {
        (uint112 reserve0Before, uint112 reserve1Before,) = getReserves();

        // Swap zero amounts
        swap(0, 0, msg.sender, "");

        (uint112 reserve0After, uint112 reserve1After,) = getReserves();

        assertEq(reserve0After, reserve0Before, "Reserve0 changed after zero swap");
        assertEq(reserve1After, reserve1Before, "Reserve1 changed after zero swap");
    }

    // Swapping with insufficient liquidity should fail
    function test_V2_swapInsufficientLiquidityFails() public {
        (uint112 reserve0, uint112 reserve1,) = getReserves();
        require(reserve0 > 0 && reserve1 > 0);

        // Try to swap more than available reserves
        try this.swap(uint256(reserve0) + 1, 0, msg.sender, "") {
            assertWithMsg(false, "Swap with insufficient liquidity did not fail");
        } catch {
            // Expected to fail
        }
    }

    // Swapping both directions simultaneously should fail
    function test_V2_swapBothDirectionsFails() public {
        (uint112 reserve0, uint112 reserve1,) = getReserves();
        require(reserve0 > 0 && reserve1 > 0);

        uint256 amount0Out = uint256(reserve0) / 100;
        uint256 amount1Out = uint256(reserve1) / 100;
        require(amount0Out > 0 && amount1Out > 0);

        // Swapping both tokens out should fail
        try this.swap(amount0Out, amount1Out, msg.sender, "") {
            assertWithMsg(false, "Swap in both directions did not fail");
        } catch {
            // Expected to fail
        }
    }

    // Swap output should be positive if input is provided
    function test_V2_swapPositiveOutput() public {
        (uint112 reserve0Before, uint112 reserve1Before,) = getReserves();
        require(reserve0Before > 1000 && reserve1Before > 1000);

        uint256 amount1Out = 100; // Request small amount of token1

        // The swap should succeed if we provide enough token0
        try this.swap(0, amount1Out, msg.sender, "") {
            (uint112 reserve0After, uint112 reserve1After,) = getReserves();

            // Reserve1 should have decreased (we received token1)
            assertLt(reserve1After, reserve1Before, "Reserve1 did not decrease");

            // Reserve0 should have increased (we paid token0)
            assertGt(reserve0After, reserve0Before, "Reserve0 did not increase");
        } catch {
            // Might fail if we didn't provide enough input tokens
        }
    }

    // K should increase by at least the fee amount (0.3%)
    function test_V2_swapIncreasesKByFee() public {
        uint256 kBefore = _getK();
        (uint112 reserve0Before, uint112 reserve1Before,) = getReserves();
        require(reserve0Before > 10000 && reserve1Before > 10000);

        uint256 amount0Out = uint256(reserve0Before) / 100;
        require(amount0Out > 0 && amount0Out < reserve0Before);

        swap(amount0Out, 0, msg.sender, "");

        uint256 kAfter = _getK();

        // K should increase (fees accumulate in the pool)
        // Due to 0.3% fee, K_after > K_before
        assertGt(kAfter, kBefore, "K did not increase after swap (fee not collected)");
    }
}
