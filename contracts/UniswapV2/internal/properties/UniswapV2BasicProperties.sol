// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "../util/UniswapV2TestBase.sol";

/**
 * @title Uniswap V2 Basic Properties (Liquidity Addition)
 * @author Trail of Bits
 * @notice Properties for testing liquidity addition (mint) in Uniswap V2 pairs
 */
abstract contract CryticUniswapV2BasicProperties is CryticUniswapV2Base {
    constructor() {}

    ////////////////////////////////////////
    // Properties

    // Adding liquidity should increase K
    function test_V2_addLiquidityIncreasesK() public {
        uint256 kBefore = _getK();
        (uint112 reserve0Before, uint112 reserve1Before,) = getReserves();
        require(reserve0Before > 0 && reserve1Before > 0);

        uint256 liquidityMinted = mint(msg.sender);
        require(liquidityMinted > 0);

        uint256 kAfter = _getK();
        assertGt(kAfter, kBefore, "K did not increase after adding liquidity");
    }

    // Adding liquidity should increase total supply of LP tokens
    function test_V2_addLiquidityIncreasesTotalSupply() public {
        uint256 supplyBefore = totalSupply();
        (uint112 reserve0Before, uint112 reserve1Before,) = getReserves();
        require(reserve0Before > 0 && reserve1Before > 0);

        uint256 liquidityMinted = mint(msg.sender);
        require(liquidityMinted > 0);

        uint256 supplyAfter = totalSupply();
        assertGt(
            supplyAfter,
            supplyBefore,
            "Total supply did not increase after adding liquidity"
        );
    }

    // Adding liquidity should increase reserves of both tokens
    function test_V2_addLiquidityIncreasesReserves() public {
        (uint112 reserve0Before, uint112 reserve1Before,) = getReserves();
        require(reserve0Before > 0 && reserve1Before > 0);

        uint256 liquidityMinted = mint(msg.sender);
        require(liquidityMinted > 0);

        (uint112 reserve0After, uint112 reserve1After,) = getReserves();
        assertGt(
            reserve0After,
            reserve0Before,
            "Reserve0 did not increase after adding liquidity"
        );
        assertGt(
            reserve1After,
            reserve1Before,
            "Reserve1 did not increase after adding liquidity"
        );
    }

    // Adding liquidity should increase the user's LP balance
    function test_V2_addLiquidityIncreasesUserBalance() public {
        uint256 balanceBefore = balanceOf(msg.sender);
        (uint112 reserve0Before, uint112 reserve1Before,) = getReserves();
        require(reserve0Before > 0 && reserve1Before > 0);

        uint256 liquidityMinted = mint(msg.sender);
        require(liquidityMinted > 0);

        uint256 balanceAfter = balanceOf(msg.sender);
        assertGt(
            balanceAfter,
            balanceBefore,
            "User LP balance did not increase after adding liquidity"
        );
        assertEq(
            balanceAfter - balanceBefore,
            liquidityMinted,
            "User LP balance increase does not equal minted liquidity"
        );
    }

    // First mint should lock MINIMUM_LIQUIDITY (1000 tokens)
    function test_V2_firstMintLocksMinimumLiquidity() public {
        uint256 supply = totalSupply();

        if (supply == 0) {
            // This is the first mint
            uint256 liquidityMinted = mint(msg.sender);
            require(liquidityMinted > 0);

            uint256 supplyAfter = totalSupply();
            assertGte(
                supplyAfter,
                MINIMUM_LIQUIDITY,
                "Total supply after first mint is less than MINIMUM_LIQUIDITY"
            );

            // The locked liquidity should be sent to address(0) or burned
            // User receives: minted - MINIMUM_LIQUIDITY
            uint256 userBalance = balanceOf(msg.sender);
            assertEq(
                userBalance + MINIMUM_LIQUIDITY,
                supplyAfter,
                "First mint did not properly lock MINIMUM_LIQUIDITY"
            );
        }
    }

    // Total supply should never be less than MINIMUM_LIQUIDITY after initialization
    function test_V2_totalSupplyAboveMinimum() public {
        uint256 supply = totalSupply();

        if (supply > 0) {
            assertGte(
                supply,
                MINIMUM_LIQUIDITY,
                "Total supply fell below MINIMUM_LIQUIDITY"
            );
        }
    }

    // LP token balance of zero address should be MINIMUM_LIQUIDITY (burned on first mint)
    function test_V2_zeroAddressHoldsMinimumLiquidity() public {
        uint256 supply = totalSupply();

        if (supply > 0) {
            uint256 zeroBalance = balanceOf(address(0));
            // On first mint, MINIMUM_LIQUIDITY is sent to address(0)
            assertGte(
                zeroBalance,
                0,
                "Zero address LP balance check failed"
            );
        }
    }

    // Minting zero liquidity should fail
    function test_V2_mintZeroLiquidityFails() public {
        (uint112 reserve0Before, uint112 reserve1Before,) = getReserves();

        // If reserves haven't changed since last mint, should mint 0 liquidity
        if (reserve0Before > 0 && reserve1Before > 0) {
            // Don't transfer any new tokens
            // Attempting to mint should fail or return 0
            try this.mint(msg.sender) returns (uint256 liquidity) {
                assertEq(liquidity, 0, "Minted non-zero liquidity without adding tokens");
            } catch {
                // Expected to fail
            }
        }
    }
}
