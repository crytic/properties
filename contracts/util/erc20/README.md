# ERC20 Edge Case Testing Helper

This directory contains a comprehensive helper system for testing protocols against non-standard ERC20 token behaviors. Many real-world tokens violate the ERC20 specification in various ways, and these violations have led to numerous exploits in DeFi protocols.

## Overview

The `ERC20EdgeCases` contract deploys 20 different ERC20 token implementations, each exhibiting a specific non-standard behavior found in real tokens. Use this helper to ensure your protocol handles all edge cases correctly.

## Quick Start

```solidity
import "@crytic/properties/contracts/util/erc20/ERC20EdgeCases.sol";

contract MyProtocolTest {
    ERC20EdgeCases edgeCases;
    MyProtocol protocol;

    constructor() {
        edgeCases = new ERC20EdgeCases();
        protocol = new MyProtocol();
    }

    // Test protocol with ALL token types
    function test_protocolWithAllTokens(uint256 amount) public {
        address[] memory tokens = edgeCases.all_erc20();

        for (uint i = 0; i < tokens.length; i++) {
            // Test your protocol with each token
            _testProtocol(tokens[i], amount);
        }
    }

    // Test with specific problematic behavior
    function test_protocolWithFeeTokens() public {
        address[] memory feeTokens = edgeCases.tokens_with_fee();
        // Test just with fee-on-transfer tokens
    }
}
```

## Token Types

### Standard (Baseline)

| Token | Behavior | Real Examples |
|-------|----------|---------------|
| **StandardERC20** | Compliant ERC20 implementation | Most well-behaved tokens |

### Missing Return Values

| Token | Behavior | Real Examples | Impact |
|-------|----------|---------------|--------|
| **MissingReturns** | `transfer()` and `transferFrom()` don't return `bool` | USDT, BNB, OMG | Contracts expecting return values will fail to decode |
| **ReturnsFalse** | Returns `false` even on successful transfers | Tether Gold (XAUT) | Makes it impossible to correctly handle all return values |

### Fee on Transfer

| Token | Behavior | Real Examples | Impact | Exploits |
|-------|----------|---------------|--------|----------|
| **TransferFee** | Deducts fee from transfer amount | Statera (STA), Paxos Gold (PAXG) | Receiver gets less than sent amount | Balancer $500k drain |

### Reentrant Callbacks

| Token | Behavior | Real Examples | Impact | Exploits |
|-------|----------|---------------|--------|----------|
| **Reentrant** | Calls back to receiver during transfer | Amp (AMP), imBTC | Enables reentrancy attacks | imBTC Uniswap drain, lendf.me hack |

### Admin Controls

| Token | Behavior | Real Examples | Impact |
|-------|----------|---------------|--------|
| **BlockList** | Admin can block addresses from transfers | USDC, USDT | Funds can be frozen in contracts |
| **Pausable** | Admin can pause all transfers | Binance Coin (BNB), Zilliqa (ZIL) | All transfers can be halted |

### Transfer Quirks

| Token | Behavior | Real Examples | Impact |
|-------|----------|---------------|--------|
| **RevertZero** | Reverts on zero-value transfers | Aave (LEND) | Breaks contracts that may send zero |
| **RevertToZero** | Reverts on transfer to `address(0)` | Most OpenZeppelin tokens | Can't burn via transfer to zero |
| **NoRevert** | Returns `false` instead of reverting | ZRX, EURS | Must check return value explicitly |
| **TransferFromSelf** | Doesn't decrease allowance if `from == msg.sender` | DSToken (DAI), WETH9 | Different semantics for self-transfers |
| **TransferMax** | Transfers full balance if `amount == type(uint256).max` | Compound v3 USDC | Amount parameter has special meaning |

### Approval Quirks

| Token | Behavior | Real Examples | Impact |
|-------|----------|---------------|--------|
| **ApprovalRaceProtection** | Can't change non-zero allowance to different non-zero value | USDT, KNC | Must set to zero first |
| **ApprovalToZeroAddress** | Reverts on `approve(address(0), amount)` | Most OpenZeppelin tokens | Can't use zero address to clear |
| **RevertZeroApproval** | Reverts on `approve(spender, 0)` | Binance Coin (BNB) | Can't clear allowance with zero |
| **Uint96** | Reverts if amount >= 2^96 | Uniswap (UNI), Compound (COMP) | Limited to uint96 range |

### Metadata Quirks

| Token | Behavior | Real Examples | Impact |
|-------|----------|---------------|--------|
| **Bytes32Metadata** | `name` and `symbol` are `bytes32` not `string` | MakerDAO (MKR) | String decoders will fail |
| **LowDecimals** | Only 6 decimals (vs standard 18) | USDC, Gemini USD (2) | Precision loss in calculations |
| **HighDecimals** | 24 decimals (vs standard 18) | YAM-V2 | May cause overflows |

### Permit Issues

| Token | Behavior | Real Examples | Impact | Exploits |
|-------|----------|---------------|--------|----------|
| **PermitNoOp** | `permit()` doesn't revert but does nothing | Wrapped Ether (WETH) | Allowance not increased | Multichain hack |

## Helper Functions

### Basic Access

```solidity
// Get all tokens (standard + non-standard)
address[] memory allTokens = edgeCases.all_erc20();

// Get only standard-compliant tokens
address[] memory standardTokens = edgeCases.all_erc20_standard();

// Get only non-standard tokens
address[] memory weirdTokens = edgeCases.all_erc20_non_standard();

// Get specific token by name
address usdt = edgeCases.tokenByName("USDT-like");
address sta = edgeCases.tokenByName("STA-like");
```

### Categorized Access

```solidity
// Get tokens by behavior category
address[] memory missingReturns = edgeCases.tokens_missing_return_values();
address[] memory feeTokens = edgeCases.tokens_with_fee();
address[] memory reentrant = edgeCases.tokens_reentrant();
address[] memory adminControlled = edgeCases.tokens_with_admin_controls();
address[] memory approvalQuirks = edgeCases.tokens_approval_quirks();
```

## Common Testing Patterns

### Pattern 1: Test Against All Tokens

```solidity
function test_vaultAccountingCorrect(uint256 amount) public {
    address[] memory tokens = edgeCases.all_erc20();

    for (uint i = 0; i < tokens.length; i++) {
        IERC20 token = IERC20(tokens[i]);

        // Setup
        token.approve(address(vault), amount);
        uint256 vaultBalanceBefore = token.balanceOf(address(vault));

        // Action
        vault.deposit(tokens[i], amount);

        // Verify
        uint256 vaultBalanceAfter = token.balanceOf(address(vault));
        uint256 actualReceived = vaultBalanceAfter - vaultBalanceBefore;

        // This will FAIL with fee-on-transfer tokens if vault doesn't check!
        assertEq(
            vault.balances(address(this), tokens[i]),
            actualReceived, // Not amount!
            "Vault must track actual received amount"
        );
    }
}
```

### Pattern 2: Test Specific Edge Cases

```solidity
function test_poolNoReentrancyExploit() public {
    address reentrantToken = edgeCases.tokenByName("ERC777-like");

    uint256 poolBalanceBefore = IERC20(reentrantToken).balanceOf(address(pool));

    // Try to exploit with reentrant callback
    pool.swap(reentrantToken, 1000e18);

    uint256 poolBalanceAfter = IERC20(reentrantToken).balanceOf(address(pool));

    // Pool should never lose tokens
    assertGte(poolBalanceAfter, poolBalanceBefore, "Reentrant attack succeeded!");
}
```

### Pattern 3: Verify Explicit Rejections

```solidity
function test_vaultRejectsDangerousTokens() public {
    // Vault with allowlist should reject problematic tokens
    address feeToken = edgeCases.tokenByName("TransferFee");
    address reentrantToken = edgeCases.tokenByName("Reentrant");

    // These should revert
    try vault.addToken(feeToken) {
        assertWithMsg(false, "Vault should reject fee-on-transfer tokens");
    } catch {}

    try vault.addToken(reentrantToken) {
        assertWithMsg(false, "Vault should reject reentrant tokens");
    } catch {}
}
```

## Real-World Exploits Prevented

This helper would have caught:

- **Balancer STA Exploit (2020)**: $500k drained due to fee-on-transfer tokens
  - Use `TransferFee` token to test
- **imBTC Uniswap Drain**: Reentrancy via ERC777 hooks
  - Use `Reentrant` token to test
- **Multichain Hack**: Assumed permit succeeded without checking allowance
  - Use `PermitNoOp` token to test
- **Numerous integration bugs**: Missing return value handling, approval race conditions, etc.

## Integration with Echidna/Medusa

```bash
# Run fuzzer with edge case tests
echidna . --contract TestProtocolWithEdgeCases --config echidna-config.yaml
```

Example `echidna-config.yaml`:
```yaml
testMode: assertion
deployer: "0x10000"
```

## Best Practices

1. **Always test with `all_erc20()`** - Don't assume standard behavior
2. **Check actual received amounts** - Use balance differencing, not transfer amounts
3. **Use SafeERC20** - Or implement similar checks for return values
4. **Verify explicit behavior** - Test that dangerous tokens are properly rejected
5. **Test reentrancy** - Especially for tokens with callbacks

## Additional Resources

- [Trail of Bits Token Integration Checklist](https://github.com/crytic/building-secure-contracts/blob/master/development-guidelines/token_integration.md)
- [weird-erc20 Repository](https://github.com/d-xo/weird-erc20)
- [Consensys Diligence Token Integration Checklist](https://consensys.github.io/smart-contract-best-practices/tokens/)

## See Also

- `contracts/ERC20/` - Properties for testing token implementations
- `contracts/util/PropertiesHelper.sol` - Assertion helpers
- `tests/` - Example test harnesses
