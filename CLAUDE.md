# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository by Trail of Bits provides 181+ pre-made Solidity property tests for fuzz testing smart contracts with [Echidna](https://github.com/crytic/echidna) or [Medusa](https://github.com/crytic/medusa). It covers:
- ERC20 tokens (25 properties)
- ERC721 tokens (19 properties)
- ERC4626 vaults (37 properties)
- ABDKMath64x64 fixed-point library (106 properties)
- Concentrated Liquidity AMMs (13+ properties)

## Build Commands

**Root level (Foundry):**
```bash
forge build                    # Compile contracts
```

**Root level (Hardhat):**
```bash
npm install                    # Install dependencies
npm run compile                # Compile contracts
```

**Linting and formatting:**
```bash
npm run format                 # Format code with Prettier
npm run lint                   # Check formatting and markdown links
```

## Running Fuzz Tests

Tests are organized in `tests/<standard>/<framework>/` directories (e.g., `tests/ERC20/foundry/`).

**Echidna (from test directory):**
```bash
# Internal testing
echidna . --contract CryticERC20InternalHarness --config echidna-config.yaml

# External testing
echidna . --contract CryticERC20ExternalHarness --config echidna-config-ext.yaml
```

**Medusa (from test directory):**
```bash
# Build first
forge build --build-info

# Run fuzzer
medusa fuzz --target-contracts CryticERC20InternalHarness --config medusa-config.json
```

## Architecture

### Directory Structure
- `contracts/` - Property contracts by standard
  - `ERC20/`, `ERC721/`, `ERC4626/` - Each split into `internal/` and `external/` testing
  - `ConcentratedLiquidity/` - Uniswap V3 style AMM properties (tick math, liquidity accounting, swaps)
  - `Math/ABDKMath64x64/` - Fixed-point math properties
  - `util/` - Helper functions (PropertiesHelper.sol, Hevm.sol, PropertiesConstants.sol)
- `tests/` - Example test harnesses for Foundry and Hardhat
- `PROPERTIES.md` - Complete property reference table

### Testing Approaches

**Internal testing**: Test contract inherits from both the token and property contracts. Properties access internal state directly.

**External testing**: Separate harness contract interacts with token through its external interface. Requires `allContracts: true` in Echidna config.

### Key Patterns

1. **Harness contracts** inherit from `CryticERC*Properties` and initialize test state (mint to USER1, USER2, USER3)
2. **PropertiesConstants** provides standard addresses: `USER1=0x10000`, `USER2=0x20000`, `USER3=0x30000`, `INITIAL_BALANCE=1000e18`
3. **PropertiesHelper** provides `assertEq`, `assertWithMsg`, `clampBetween`, and `LogXxx` events for debugging
4. **Echidna/Medusa configs** use assertion mode (`testMode: assertion`) with deployer `0x10000`

## Adding New Properties

1. Add property to appropriate file in `contracts/<standard>/internal/properties/` and `external/properties/`
2. For external properties, update the interface in `contracts/<standard>/util/`
3. Add test in `contracts/<standard>/*/test/` to verify property catches violations
4. Update `PROPERTIES.md` table
5. Update `contracts/<standard>/README.md` if present

## Branch Naming

- Features: `dev-<description>` (e.g., `dev-add-properties-for-erc20-transfers`)
- Bug fixes: `fix-<description>` (e.g., `fix-typo-in-readme`)
