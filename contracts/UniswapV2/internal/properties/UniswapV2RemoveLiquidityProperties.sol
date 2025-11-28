// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "../util/UniswapV2TestBase.sol";

/**
 * @title Uniswap V2 Remove Liquidity Properties
 * @author Trail of Bits
 * @notice Properties for testing liquidity removal (burn) in Uniswap V2 pairs
 */
abstract contract CryticUniswapV2RemoveLiquidityProperties is CryticUniswapV2Base {
    constructor() {}

    ////////////////////////////////////////
    // Properties

    // Removing liquidity should decrease K
    function test_V2_removeLiquidityDecreasesK() public {
        uint256 kBefore = _getK();
        uint256 userBalance = balanceOf(msg.sender);
        require(userBalance > 0);
        require(kBefore > 0);

        (uint256 amount0, uint256 amount1) = burn(msg.sender);
        require(amount0 > 0 || amount1 > 0);

        uint256 kAfter = _getK();
        assertLt(kAfter, kBefore, "K did not decrease after removing liquidity");
    }

    // Removing liquidity should decrease total supply of LP tokens
    function test_V2_removeLiquidityDecreasesTotalSupply() public {
        uint256 supplyBefore = totalSupply();
        uint256 userBalance = balanceOf(msg.sender);
        require(userBalance > 0);

        (uint256 amount0, uint256 amount1) = burn(msg.sender);
        require(amount0 > 0 || amount1 > 0);

        uint256 supplyAfter = totalSupply();
        assertLt(
            supplyAfter,
            supplyBefore,
            "Total supply did not decrease after removing liquidity"
        );
    }

    // Removing liquidity should decrease reserves of both tokens
    function test_V2_removeLiquidityDecreasesReserves() public {
        (uint112 reserve0Before, uint112 reserve1Before,) = getReserves();
        uint256 userBalance = balanceOf(msg.sender);
        require(userBalance > 0);
        require(reserve0Before > 0 && reserve1Before > 0);

        (uint256 amount0, uint256 amount1) = burn(msg.sender);
        require(amount0 > 0 && amount1 > 0);

        (uint112 reserve0After, uint112 reserve1After,) = getReserves();
        assertLt(
            reserve0After,
            reserve0Before,
            "Reserve0 did not decrease after removing liquidity"
        );
        assertLt(
            reserve1After,
            reserve1Before,
            "Reserve1 did not decrease after removing liquidity"
        );
    }

    // Removing liquidity should decrease the user's LP balance
    function test_V2_removeLiquidityDecreasesUserBalance() public {
        uint256 balanceBefore = balanceOf(msg.sender);
        require(balanceBefore > 0);

        (uint256 amount0, uint256 amount1) = burn(msg.sender);
        require(amount0 > 0 || amount1 > 0);

        uint256 balanceAfter = balanceOf(msg.sender);
        assertLt(
            balanceAfter,
            balanceBefore,
            "User LP balance did not decrease after removing liquidity"
        );
    }

    // Burning zero liquidity should return zero amounts
    function test_V2_burnZeroLiquidity() public {
        uint256 userBalance = balanceOf(msg.sender);

        if (userBalance == 0) {
            (uint256 amount0, uint256 amount1) = burn(msg.sender);
            assertEq(amount0, 0, "Burning zero liquidity returned non-zero amount0");
            assertEq(amount1, 0, "Burning zero liquidity returned non-zero amount1");
        }
    }

    // Burning should return proportional amounts
    function test_V2_burnReturnsProportionalAmounts() public {
        (uint112 reserve0, uint112 reserve1,) = getReserves();
        uint256 supply = totalSupply();
        uint256 userBalance = balanceOf(msg.sender);

        require(userBalance > 0);
        require(supply > 0);
        require(reserve0 > 0 && reserve1 > 0);

        (uint256 amount0, uint256 amount1) = burn(msg.sender);

        if (amount0 > 0 && amount1 > 0) {
            // Check proportionality: amount0/reserve0 ≈ amount1/reserve1
            // Allow 1% deviation for rounding
            uint256 ratio0 = (amount0 * 1000) / reserve0;
            uint256 ratio1 = (amount1 * 1000) / reserve1;

            uint256 diff = ratio0 > ratio1 ? ratio0 - ratio1 : ratio1 - ratio0;
            assertLte(
                diff,
                10, // 1% tolerance
                "Burn did not return proportional amounts"
            );
        }
    }

    // Total supply should never fall below MINIMUM_LIQUIDITY
    function test_V2_totalSupplyNeverBelowMinimum() public {
        uint256 supply = totalSupply();
        uint256 userBalance = balanceOf(msg.sender);

        if (userBalance > 0 && supply > MINIMUM_LIQUIDITY) {
            burn(msg.sender);

            uint256 supplyAfter = totalSupply();
            assertGte(
                supplyAfter,
                MINIMUM_LIQUIDITY,
                "Total supply fell below MINIMUM_LIQUIDITY after burn"
            );
        }
    }
}
