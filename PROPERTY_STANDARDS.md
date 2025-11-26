# Property Documentation Standards

This document defines the standardization rules for all property test functions in the Crytic Properties repository. These standards ensure consistency, clarity, and educational value across all 168+ properties.

## Overview

All property test functions must follow these standards:
1. **NatSpec Documentation** - Complete structured documentation
2. **Testing Mode** - Clearly specified approach (INTERNAL/EXTERNAL/ISOLATED/FUNCTION_OVERRIDE/MODEL)
3. **Invariant Description** - Plain English explanation of what must always be true
4. **Logical Organization** - Properties grouped into meaningful sections
5. **Unique Identifiers** - Trackable property IDs for reference

## Testing Modes

Based on [Echidna's common testing approaches](https://secure-contracts.com/program-analysis/echidna/basic/common-testing-approaches.html#partial-testing), we use five testing modes:

### INTERNAL
Test harness inherits from the contract under test. Properties have direct access to internal state and functions.

**When to use:** Testing your own contracts during development.

**Example:**
```solidity
contract TestHarness is MyToken, CryticERC20BasicProperties {
    constructor() {
        _mint(USER1, INITIAL_BALANCE);
    }
}
```

### EXTERNAL
Test harness interacts with the contract through its public interface only. Simulates real-world usage patterns.

**When to use:** Testing deployed contracts or simulating external user interactions.

**Example:**
```solidity
contract TestHarness is CryticERC20ExternalBasicProperties {
    constructor() {
        token = ITokenMock(address(new MyToken()));
    }
}
```

### ISOLATED
Testing individual components abstracted from the rest of the system. Particularly useful for stateless mathematical operations.

**When to use:** Testing math libraries, pure functions, or components with no external dependencies.

**Example:** Testing ABDKMath64x64 arithmetic operations independently.

### FUNCTION_OVERRIDE
Uses Solidity's override mechanism to mock or disable dependencies that cannot be simulated (e.g., oracles, bridges, signature verification).

**When to use:** System depends on off-chain components or external systems that cannot be easily mocked.

**Example:**
```solidity
contract TestHarness is System {
    function verifySignature(...) public override returns (bool) {
        return true; // Mock: signatures always valid for testing
    }
}
```

### MODEL
Abstract mathematical model represents expected behavior. Properties compare actual contract behavior against a simplified reference implementation.

**When to use:** Contract implements complex logic with known mathematical properties that can be expressed as a simpler model.

**Example:** Comparing vault share calculations against a simplified mathematical formula.

---

## NatSpec Documentation Template

Every property function **must** include the following NatSpec tags:

```solidity
/// @title [Human-Readable Property Name]
/// @notice [Brief user-facing description of what this property tests]
/// @dev Testing Mode: [INTERNAL|EXTERNAL|ISOLATED|FUNCTION_OVERRIDE|MODEL]
/// @dev Invariant: [Plain English description of what must always be true]
/// @dev [Optional: Additional context, examples, or preconditions]
/// @custom:property-id [STANDARD]-[CATEGORY]-[NUMBER]
function test_Standard_PropertyName() public {
    // Implementation
}
```

### Tag Requirements

| Tag | Required | Purpose | Example |
|-----|----------|---------|---------|
| `@title` | ✅ Yes | Clear, human-readable property name | "User Balance Cannot Exceed Total Supply" |
| `@notice` | ✅ Yes | Brief description for users/auditors | "Ensures individual balances never exceed the total token supply" |
| `@dev Testing Mode:` | ✅ Yes | Specify which testing approach is used | "Testing Mode: INTERNAL" |
| `@dev Invariant:` | ✅ Yes | Plain English invariant description | "For any address `user`, `balanceOf(user) <= totalSupply()` must always hold" |
| `@dev [context]` | ⚠️ Optional | Additional explanations, examples, or preconditions | "This is a fundamental accounting invariant..." |
| `@custom:property-id` | ✅ Yes | Unique identifier for tracking | "ERC20-BALANCE-001" |

---

## Property ID Format

Property IDs follow the pattern: `[STANDARD]-[CATEGORY]-[NUMBER]`

### Standard Prefixes
- `ERC20` - ERC20 token properties
- `ERC721` - ERC721 NFT properties
- `ERC4626` - ERC4626 vault properties
- `MATH` - Mathematical library properties

### Category Guidelines

Choose categories based on **functionality** being tested:

**For ERC20:**
- `SUPPLY` - Total supply accounting
- `BALANCE` - Individual balance accounting
- `TRANSFER` - Transfer mechanics and safety
- `ALLOWANCE` - Approve/transferFrom mechanics
- `BURN` - Burning mechanics
- `MINT` - Minting mechanics
- `PAUSE` - Pause functionality

**For ERC721:**
- `OWNERSHIP` - Token ownership tracking
- `TRANSFER` - Transfer mechanics
- `APPROVAL` - Approval mechanics
- `BURN` - Burning mechanics
- `MINT` - Minting mechanics

**For ERC4626:**
- `ACCOUNTING` - Share/asset accounting
- `DEPOSIT` - Deposit mechanics
- `WITHDRAW` - Withdrawal mechanics
- `SECURITY` - Security properties (inflation attacks, etc.)
- `ROUNDING` - Rounding direction safety

**For Math:**
- `[OPERATION]` - Name of the operation (ADD, SUB, MUL, DIV, SQRT, LOG, etc.)

### Numbering
- Use zero-padded 3-digit numbers: 001, 002, 003, etc.
- Sequential within each category
- No gaps in numbering

### Examples
- `ERC20-SUPPLY-001` - First supply accounting property
- `ERC20-TRANSFER-005` - Fifth transfer property
- `ERC721-OWNERSHIP-001` - First ownership property
- `ERC4626-SECURITY-002` - Second security property
- `MATH-ADD-001` - First addition property

---

## File Organization

### File-Level Documentation

Every property contract must include comprehensive contract-level NatSpec:

```solidity
// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "./PropertiesHelper.sol";

/**
 * @title [Contract Name] Properties
 * @author Crytic (Trail of Bits)
 * @notice [High-level description of what this contract tests]
 * @dev Testing Mode: [Primary mode used in this contract]
 * @dev This contract contains [X] properties testing [brief description]
 * @dev
 * @dev Usage Example:
 * @dev ```solidity
 * @dev contract TestHarness is MyToken, CryticERC20BasicProperties {
 * @dev     constructor() {
 * @dev         _mint(USER1, INITIAL_BALANCE);
 * @dev         initialSupply = totalSupply();
 * @dev     }
 * @dev }
 * @dev ```
 */
contract ContractNameProperties is PropertiesAsserts {
    // Contract body
}
```

### Section Structure

Properties should be organized into logical sections based on functionality:

```solidity
// ================================================================
// STATE VARIABLES & CONFIGURATION
// ================================================================

/// @notice [Description of state variable]
uint256 public someStateVar;


/* ================================================================

                    [SECTION NAME IN CAPS]

   Description: [What this section tests]
   Testing Mode: [MODE if different from default]
   Property Count: [X]

   ================================================================ */

// Properties for this section...


/* ================================================================

                    [NEXT SECTION NAME]

   Description: [What this section tests]
   Property Count: [X]

   ================================================================ */

// Properties for next section...
```

### Section Header Format

Must follow this exact format (matching ABDKMath64x64PropertyTests.sol):

```solidity
/* ================================================================

                    [SECTION TITLE HERE]

   Description: [Brief explanation]
   Testing Mode: [MODE] (if different from file default)
   Property Count: [X]

   ================================================================ */
```

**Rules:**
- Opening `/*` and closing `*/` on their own lines
- `================================================================` lines (64 equals signs)
- Empty line after opening
- Section title centered (3 blank lines before title)
- Empty line after title
- Description and metadata left-aligned with 3-space indent
- Empty line before closing

---

## Complete Example

Here's a complete before/after example:

### Before (Current State)
```solidity
// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import "../util/ERC20TestBase.sol";

abstract contract CryticERC20BasicProperties is CryticERC20Base {
    // User balance must not exceed total supply
    function test_ERC20_userBalanceNotHigherThanSupply() public {
        assertLte(
            balanceOf(msg.sender),
            totalSupply(),
            "User balance higher than total supply"
        );
    }

    // Address zero should have zero balance
    function test_ERC20_zeroAddressBalance() public {
        assertEq(
            balanceOf(address(0)),
            0,
            "Address zero balance not equal to zero"
        );
    }
}
```

### After (Standardized)
```solidity
// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import "../util/ERC20TestBase.sol";

/**
 * @title ERC20 Basic Properties
 * @author Crytic (Trail of Bits)
 * @notice Core invariant properties for ERC20 token implementations
 * @dev Testing Mode: INTERNAL (can also be used EXTERNALLY via interface)
 * @dev This contract contains 17 fundamental properties testing supply accounting,
 * @dev balance accounting, transfer mechanics, and allowance operations.
 * @dev
 * @dev Usage Example:
 * @dev ```solidity
 * @dev contract TestHarness is MyToken, CryticERC20BasicProperties {
 * @dev     constructor() {
 * @dev         _mint(USER1, INITIAL_BALANCE);
 * @dev         _mint(USER2, INITIAL_BALANCE);
 * @dev         initialSupply = totalSupply();
 * @dev         isMintableOrBurnable = false; // Set based on your token
 * @dev     }
 * @dev }
 * @dev ```
 */
abstract contract CryticERC20BasicProperties is CryticERC20Base {

    // ================================================================
    // STATE VARIABLES
    // ================================================================

    /// @notice Initial total supply recorded at test initialization
    /// @dev Used for constant supply checks in non-mintable/burnable tokens
    uint256 public initialSupply;

    /// @notice Flag indicating if token supply can change after deployment
    /// @dev Set to true for mintable/burnable tokens, false for fixed supply
    bool public isMintableOrBurnable;


    /* ================================================================

                    BALANCE ACCOUNTING PROPERTIES

       Description: Properties verifying individual balance accounting
       Testing Mode: INTERNAL
       Property Count: 2

       ================================================================ */

    /// @title User Balance Cannot Exceed Total Supply
    /// @notice Ensures individual user balances never exceed the total token supply
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: For any address `user`, `balanceOf(user) <= totalSupply()` must always hold
    /// @dev This is a fundamental accounting invariant - if violated, the token contract
    /// @dev has a critical bug allowing token creation from nothing or double-counting
    /// @custom:property-id ERC20-BALANCE-001
    function test_ERC20_userBalanceNotHigherThanSupply() public {
        assertLte(
            balanceOf(msg.sender),
            totalSupply(),
            "User balance higher than total supply"
        );
    }

    /// @title Zero Address Has Zero Balance
    /// @notice The zero address should never hold tokens
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: `balanceOf(address(0)) == 0` must always hold
    /// @dev The zero address is conventionally used to represent burned tokens.
    /// @dev If it holds a non-zero balance, tokens are effectively lost/inaccessible
    /// @custom:property-id ERC20-BALANCE-002
    function test_ERC20_zeroAddressBalance() public {
        assertEq(
            balanceOf(address(0)),
            0,
            "Address zero balance not equal to zero"
        );
    }
}
```

---

## Code Style Requirements

### Assertion Messages
- Must be descriptive and clearly indicate what invariant was violated
- Use present tense ("Balance exceeds supply" not "Balance exceeded supply")
- No abbreviations or unclear technical jargon

### Formatting
- Property functions should have blank lines between them for readability
- Long assertions should be formatted with one parameter per line
- Consistent indentation (4 spaces)

### Comments
- Replace inline comments with NatSpec documentation
- Only keep inline comments if they explain non-obvious implementation details
- Avoid redundant comments that simply restate the code

---

## Contribution Checklist

Before submitting a PR with new or modified properties:

- [ ] All property functions have complete NatSpec (@title, @notice, @dev tags)
- [ ] Testing mode is clearly documented in @dev tag
- [ ] Invariant is described in plain English in @dev tag
- [ ] Property has a unique ID in @custom:property-id tag
- [ ] Property ID follows the [STANDARD]-[CATEGORY]-[NUMBER] format
- [ ] Property is placed in the appropriate logical section
- [ ] Section headers follow the standardized format
- [ ] File has comprehensive contract-level NatSpec
- [ ] Assertion messages are clear and descriptive
- [ ] Related documentation (PROPERTIES.md, README) is updated

---

## Automated Validation

Future: A linting script will validate:
- All `test_*` functions have required NatSpec tags
- Testing mode is specified and valid
- Invariant descriptions are present
- Property IDs are unique and properly formatted
- Section headers follow the standard format

---

## Questions?

For questions about these standards:
1. Review existing standardized files (e.g., ERC20BasicProperties.sol)
2. Check examples in this document
3. Open an issue in the GitHub repository
4. Refer to the [contribution guidelines](./CONTRIBUTING.md)

## Document History

- **2025-11**: Initial standardization document created
- Based on issue: "Standardize properties in the repo"
- Reference implementation: ABDKMath64x64PropertyTests.sol section headers
