# Concentrated Liquidity Properties

This directory contains property tests for concentrated liquidity AMM protocols (Uniswap V3 style) that can be used with [Echidna](https://github.com/crytic/echidna) or [Medusa](https://github.com/crytic/medusa) for fuzzing.

## Overview

Concentrated liquidity AMMs allow liquidity providers to concentrate their capital within specific price ranges, enabling greater capital efficiency compared to traditional constant product AMMs (Uniswap V2 style). This mechanism uses tick-based accounting where:

- **Ticks** represent discrete price points: `tick = log₁.₀₀₀₁(price)`
- **Positions** are bounded by a lower and upper tick `[tickLower, tickUpper]`
- **Active liquidity** only includes positions whose range contains the current price
- **LiquidityNet** tracks the delta change when crossing each tick boundary

## Architecture

### Testing Modes

#### Internal Testing
Test contracts inherit from both the pool implementation and property contracts. Properties access internal state directly. Best for:
- White-box testing of pool implementations
- Testing custom pool variants
- Accessing internal variables and state

#### External Testing
Test harnesses interact with pools through their external interface. Requires `allContracts: true` in Echidna config. Best for:
- Black-box testing of deployed contracts
- Testing third-party pools
- Integration testing

### Directory Structure

```
ConcentratedLiquidity/
├── util/
│   ├── IConcentratedLiquidityPool.sol  # Minimal pool interface
│   └── TickMath.sol                    # Tick <-> Price conversion library
├── internal/
│   ├── util/
│   │   └── ConcentratedLiquidityTestBase.sol  # Base contract with tick tracking
│   └── properties/
│       ├── TickMathProperties.sol       # Tick-price synchronization (Props 1-3)
│       ├── LiquidityProperties.sol      # Conservation laws (Props 4-5)
│       ├── MintBurnProperties.sol       # Position management (Props 6-9)
│       └── SwapProperties.sol           # Swap execution (Props 10-13)
└── external/
    └── (To be implemented)
```

## Properties

### Tick Math Properties (3 properties)

These properties ensure correct synchronization between ticks and prices, including protection against the **KyberSwap vulnerability** ($50M exploit).

| ID | Name | Invariant |
|---|---|---|
| CL-TICK-001 | [test_CL_tickDirectionMatchesPriceDirection](internal/properties/TickMathProperties.sol#L58) | Tick must change in the same direction as price (monotonicity) |
| CL-TICK-002 | [test_CL_noPriceOvershootWhenMovingUp](internal/properties/TickMathProperties.sol#L126) | Price must never overshoot tick boundary upward (KyberSwap fix) |
| CL-TICK-002 | [test_CL_noPriceOvershootWhenMovingDown](internal/properties/TickMathProperties.sol#L157) | Price must never overshoot tick boundary downward (KyberSwap fix) |
| CL-TICK-003 | [test_CL_currentTickRespectsSpacing](internal/properties/TickMathProperties.sol#L189) | Current tick must be aligned with tickSpacing |
| CL-TICK-003 | [test_CL_initializedTicksRespectSpacing](internal/properties/TickMathProperties.sol#L208) | All initialized ticks must respect tickSpacing |

**Why Property CL-TICK-002 Matters:**

The KyberSwap Elastic hack (November 2023) exploited a critical flaw where price was allowed to **overshoot** the next tick boundary. The vulnerable code used:

```solidity
if (sqrtPrice != sqrtPriceAtNextTick) {
    // continue using current liquidity
}
```

This allowed `sqrtPrice > sqrtPriceAtNextTick` to occur, causing liquidity to be **double-counted** because the tick was never crossed and liquidityNet was never applied. The fix uses **directional comparison**:

```solidity
// When moving up: price must be ≤ next tick (not !=)
if (sqrtPrice <= sqrtPriceAtNextTick) {
    // cross the tick and update liquidity
}
```

### Liquidity Conservation Properties (3 properties)

These properties verify the fundamental conservation laws of liquidity accounting.

| ID | Name | Invariant |
|---|---|---|
| CL-LIQUIDITY-001 | [test_CL_liquidityNetSumsToZero](internal/properties/LiquidityProperties.sol#L57) | Sum of liquidityNet across all ticks must equal zero |
| CL-LIQUIDITY-002 | [test_CL_currentLiquidityMatchesSumOfDeltas](internal/properties/LiquidityProperties.sol#L137) | Current liquidity must equal sum of liquidityNet ≤ currentTick |
| CL-LIQUIDITY-003 | [test_CL_liquidityNeverNegative](internal/properties/LiquidityProperties.sol#L178) | Liquidity values cannot be negative |

**Why CL-LIQUIDITY-001 Must Be True:**

Every position adds `+L` at `tickLower` and `-L` at `tickUpper`. Therefore:

```
Σ(liquidityNet[tick]) = Σ(+L_i - L_i) = 0
```

This is a **conservation law** - liquidity cannot be created or destroyed. Violations indicate:
- Mint/burn only updating one boundary
- Arithmetic errors in updates
- Positions not cleaning up properly

**Why CL-LIQUIDITY-002 Must Be True:**

Active liquidity is calculated by summing all deltas from negative infinity up to the current tick:

```
pool.liquidity() = Σ(liquidityNet[t] for all t ≤ currentTick)
```

This determines which positions are "in range" and contribute to trading liquidity.

### Mint/Burn Properties (4 properties)

These properties verify position creation and removal mechanics.

| ID | Name | Invariant |
|---|---|---|
| CL-MINT-001 | [test_CL_mintIncreasesCurrentLiquidityWhenInRange](internal/properties/MintBurnProperties.sol#L61) | Minting in-range increases pool.liquidity(), out-of-range doesn't |
| CL-MINT-002 | [test_CL_mintIncreasesLiquidityGross](internal/properties/MintBurnProperties.sol#L127) | Minting always increases liquidityGross at both ticks |
| CL-MINT-003 | [test_CL_mintUpdatesLiquidityNetAsymmetrically](internal/properties/MintBurnProperties.sol#L233) | Minting adds +L at tickLower, -L at tickUpper (asymmetric) |
| CL-BURN-001 | [test_CL_burnReversesMint](internal/properties/MintBurnProperties.sol#L302) | Burn must exactly reverse mint's state changes |

**Why CL-MINT-003 is Critical:**

The **asymmetric update pattern** is the foundation of concentrated liquidity:

```solidity
// When minting position [tickLower, tickUpper] with liquidity L:
liquidityNet[tickLower] += L   // Activate when crossing up
liquidityNet[tickUpper] -= L   // Deactivate when crossing up
```

This creates a "wave" where:
- Price crossing **up through tickLower**: Add L to active liquidity
- Price crossing **up through tickUpper**: Remove L from active liquidity
- Price between the ticks: Position contributes L to pool

Using symmetric updates (same sign) would cause positions to never deactivate or incorrectly accumulate liquidity.

### Swap Properties (4 properties)

These properties verify correct swap execution and price updates.

| ID | Name | Invariant |
|---|---|---|
| CL-SWAP-001 | [test_CL_swapMoviesPriceInCorrectDirection](internal/properties/SwapProperties.sol#L79) | Selling token0 decreases price, selling token1 increases price |
| CL-SWAP-002 | [test_CL_swapRespectsLimitPrice](internal/properties/SwapProperties.sol#L145) | Swap must stop at or before sqrtPriceLimitX96 |
| CL-SWAP-003 | [test_CL_swapUpdatesLiquidityWhenCrossingTicks](internal/properties/SwapProperties.sol#L202) | Liquidity must be updated when crossing tick boundaries |
| CL-SWAP-004 | [test_CL_swapPriceStaysWithinBounds](internal/properties/SwapProperties.sol#L255) | Price must stay within [MIN_SQRT_RATIO, MAX_SQRT_RATIO] |

**Why CL-SWAP-003 is Critical:**

When a swap crosses a tick boundary, the active liquidity MUST be updated:

```solidity
// When crossing tick T going up:
liquidity += liquidityNet[T]

// When crossing tick T going down:
liquidity -= liquidityNet[T]
```

Failure to update liquidity leads to:
- Using wrong liquidity for price calculations
- Positions not being activated/deactivated
- **KyberSwap-style vulnerabilities** where liquidity is double-counted

## Usage

### Basic Implementation

```solidity
// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "./ConcentratedLiquidity/internal/properties/TickMathProperties.sol";
import "./ConcentratedLiquidity/internal/properties/LiquidityProperties.sol";
import "./ConcentratedLiquidity/internal/properties/MintBurnProperties.sol";
import "./ConcentratedLiquidity/internal/properties/SwapProperties.sol";

contract MyPoolHarness is
    CryticTickMathProperties,
    CryticLiquidityProperties,
    CryticMintBurnProperties,
    CryticSwapProperties
{
    MyConcentratedPool pool;

    constructor() {
        pool = new MyConcentratedPool(
            address(token0),
            address(token1),
            FEE,
            TICK_SPACING
        );

        // Initialize pool with some liquidity
        pool.mint(address(this), -1000, 1000, 1000000e18, "");
    }

    // Implement required virtual functions
    function _getCurrentTick() internal view override returns (int24) {
        (,int24 tick,,,,,) = pool.slot0();
        return tick;
    }

    function _getCurrentLiquidity() internal view override returns (uint128) {
        return pool.liquidity();
    }

    function _getSqrtPriceX96() internal view override returns (uint160) {
        (uint160 sqrtPrice,,,,,,,) = pool.slot0();
        return sqrtPrice;
    }

    // ... implement other required functions
}
```

### Running with Echidna

```bash
echidna . --contract MyPoolHarness --config echidna-config.yaml
```

**echidna-config.yaml:**
```yaml
testMode: assertion
deployer: "0x10000"
workers: 10
testLimit: 100000
```

### Running with Medusa

```bash
forge build --build-info
medusa fuzz --target-contracts MyPoolHarness
```

## Real-World Vulnerabilities Caught

### 1. KyberSwap Elastic ($50M - November 2023)

**Vulnerability:** Price overshoot past tick boundary
- **Code:** Used `!=` instead of `<` or `>` for tick boundary check
- **Impact:** Liquidity double-counted when price exceeded next tick
- **Properties:** CL-TICK-002, CL-SWAP-003

**Vulnerable Code:**
```solidity
if (state.sqrtP != nextSqrtP) {
    // BUG: This is true when sqrtP > nextSqrtP
    // Should use: if (state.sqrtP < nextSqrtP)
    state.baseL = willUpTick ? baseL + nextLiquidity : baseL - nextLiquidity;
}
```

The fuzzer would find a sequence like:
1. Create position [tick 100, tick 200] with large liquidity
2. Swap that pushes price slightly ABOVE tick 200
3. Liquidity is still counted as active (never crossed tick)
4. Swap back down using double liquidity
5. Profit from the asymmetric price impact

### 2. Liquidity Conservation Violations

**Vulnerability:** Mint/burn asymmetry
- **Scenario:** Mint updates both boundaries, burn only updates one
- **Impact:** liquidityNet stops summing to zero, liquidity leak
- **Properties:** CL-LIQUIDITY-001, CL-BURN-001

### 3. Tick Spacing Violations

**Vulnerability:** Accepting non-aligned ticks
- **Scenario:** Position created at tick 123 with tickSpacing=10
- **Impact:** Orphaned liquidity that can never be crossed
- **Properties:** CL-TICK-003

## Integration with Existing Properties

Concentrated liquidity pools typically use ERC20 tokens. You can combine these properties with ERC20 properties:

```solidity
import "../ERC20/internal/properties/ERC20BasicProperties.sol";
import "./ConcentratedLiquidity/internal/properties/TickMathProperties.sol";

contract CombinedTest is
    CryticERC20BasicProperties,
    CryticTickMathProperties
{
    // Test both token accounting AND pool mechanics
}
```

## Resources

- **Uniswap V3 Whitepaper**: https://uniswap.org/whitepaper-v3.pdf
- **KyberSwap Exploit Analysis**: https://twitter.com/Certora/status/1728051144695349395
- **Uniswap V3 Core Repository**: https://github.com/Uniswap/v3-core
- **Trail of Bits Echidna**: https://github.com/crytic/echidna
- **Trail of Bits Medusa**: https://github.com/crytic/medusa

## Contributing

To add new properties:

1. Add the property to the appropriate file in `internal/properties/`
2. Follow the established naming convention: `CL-<CATEGORY>-<NUMBER>`
3. Include comprehensive NatSpec documentation with:
   - WHY THIS MUST BE TRUE section
   - MATHEMATICAL PROOF or example
   - WHAT BUG THIS CATCHES section
4. Add property to this README with description and invariant
5. Add external testing variant if applicable
6. Create test case that demonstrates a violation

## License

AGPL-3.0-or-later
