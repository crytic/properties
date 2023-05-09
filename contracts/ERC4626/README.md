# ERC4626 Echidna Property Tests

- [ERC4626 Echidna Property Tests](#erc4626-echidna-property-tests)
  - [Consuming](#consuming)
    - [Initial setup](#initial-setup)
    - [Adding internal test methods to a vault](#adding-internal-test-methods-to-a-vault)
  - [Developing](#developing)
  - [Properties Tested](#properties-tested)
    - [MustNotRevertProps](#mustnotrevertprops)
    - [FunctionalAccountingProps](#functionalaccountingprops)
    - [RedeemUsingApprovalProps](#redeemusingapprovalprops)
    - [SenderIndependentProps](#senderindependentprops)
    - [RoundingProps](#roundingprops)
    - [SecurityProps](#securityprops)
  - [Properties to consider adding](#properties-to-consider-adding)
  - [Properties that may not be testable](#properties-that-may-not-be-testable)

## Consuming

### Initial setup

To use these properties to test a given vault implementation, see the readme in the project root.

### Adding internal test methods to a vault

Some properties of the ERC4626 spec cannot be tested externally because testing them requires interactions between the test suite & functionality that is not defined in the spec.

To compensate for this limitation, a vault under test may optionally implement a set of methods that allow such properties to be tested. See [IERC4626Internal](util/IERC4626Internal.sol) for the list of methods.

These methods should be added to the Vault by a derived, test-environment-only contract to minimize changes to the production contract. When a vault under test implements IERC4626Internal, pass `true` to the test harness's `initialize()` function to enable the properties that require the internal interface:

```
contract Vault is IERC4626 { ... }

contract VaultTestable is Vault, IERC4626Internal { ... }

contract TestHarness is CryticERC4626PropertyTests{
  constructor(...) {
    [...]
    initialize(address(_vault), address(_asset), true);
  }
}
```

Check out the [rounding property verification contracts](test/rounding/BadConvertToAssetsRounding.sol) if you'd like to see how such an implementation would look.

## Developing

Before doing any development, run `forge install` to get dependencies sorted out. `forge build` will not work without the [Echidna remappings](test/echidna.config.yaml).

Running tests(used to validate the properties are working correctly):

`echidna ./contracts/ERC4626/test/rounding/BadConvertToAssetsRounding.sol --contract TestHarness --config ./contracts/ERC4626/test/echidna.config.yaml`
Should cause these properties to fail:

- verify_previewRedeemRoundingDirection
- verify_redeemRoundingDirection
- verify_convertToAssetsRoundingDirection

`echidna ./contracts/ERC4626/test/rounding/BadConvertToSharesRounding.sol --contract TestHarness --config ./contracts/ERC4626/test/echidna.config.yaml`
Should cause these properties to fail:

- verify_convertToSharesRoundingDirection
- verify_previewDepositRoundingDirection
- verify_depositRoundingDirection

`echidna ./contracts/ERC4626/test/rounding/BadPreviewMintRounding.sol --contract TestHarness --config ./contracts/ERC4626/test/echidna.config.yaml`
Should cause these properties to fail:

- verify_previewMintRoundingDirection
- verify_mintRoundingDirection

`echidna ./contracts/ERC4626/test/rounding/BadPreviewWithdrawRounding.sol --contract TestHarness --config ./contracts/ERC4626/test/echidna.config.yaml`
Should cause these properties to fail:

- verify_previewWithdrawRoundingDirection
- verify_withdrawRoundingDirection

`echidna ./contracts/ERC4626/test/security/BadShareInflation.sol --contract TestHarness --config ./contracts/ERC4626/test/echidna.config.yaml`
Should cause these properties to fail:

- verify_sharePriceInflationAttack

`echidna ./contracts/ERC4626/test/usingApproval/BadAllowanceUpdate.sol --contract TestHarness --config ./contracts/ERC4626/test/echidna.config.yaml`
Should cause these properties to fail:

- verify_redeemViaApprovalProxy
- verify_withdrawViaApprovalProxy
- verify_redeemRequiresTokenApproval
- verify_withdrawRequiresTokenApproval

Run property tests against vanilla solmate:

`echidna ./contracts/ERC4626/test/Solmate4626.sol --contract TestHarness --config ./contracts/ERC4626/test/echidna.config.yaml`

[EIP-4626 Spec](https://eips.ethereum.org/EIPS/eip-4626)

## Properties Tested

### MustNotRevertProps

- `convertToAssets()` must not revert for reasonable values
- `convertToShares()` must not revert for reasonable values
- `asset()` must not revert
- `totalAssets()` must not revert
- `maxDeposit()` must not revert
- `maxMint()` must not revert
- `maxRedeem()` must not revert
- `maxWithdraw()` must not revert

### FunctionalAccountingProps

- `deposit()` must deduct assets from the owner
- `deposit()` must credit shares to the receiver
- `deposit()` must mint greater than or equal to the number of shares predicted by `previewDeposit()`
- `mint()` must deduct assets from the owner
- `mint()` must credit shares to the receiver
- `mint()` must consume less than or equal to the number of assets predicted by `previewMint()`
- `withdraw()` must deduct shares from the owner
- `withdraw()` must credit assets to the receiver
- `withdraw()` must deduct less than or equal to the number of shares predicted by `previewWithdraw()`
- `redeem()` must deduct shares from the owner
- `redeem()` must credit assets to the receiver
- `redeem()` must credit greater than or equal to the number of assets predicted by `previewRedeem()`

### RedeemUsingApprovalProps

- `withdraw()` must allow proxies to withdraw tokens on behalf of the owner using share token approvals
- `redeem()` must allow proxies to redeem shares on behalf of the owner using share token approvals
- Third party `withdraw()` calls must update the msg.sender's allowance
- Third party `redeem()` calls must update the msg.sender's allowance
- Third parties must not be able to `withdraw()` tokens on an owner's behalf without a token approval
- Third parties must not be able to `redeem()` shares on an owner's behalf without a token approval

### SenderIndependentProps

- `maxDeposit()` must assume the receiver/sender has infinite assets
- `maxMint()` must assume the receiver/sender has infinite assets
- `previewMint()` must not account for msg.sender asset balance
- `previewDeposit()` must not account for msg.sender asset balance
- `previewWithdraw()` must not account for msg.sender share balance
- `previewRedeem()` must not account for msg.sender share balance

### RoundingProps

- Shares may never be minted for free using:
  - `previewDeposit()`
  - `previewMint()`
  - `convertToShares()`
- Tokens may never be withdrawn for free using:
  - `previewWithdraw()`
  - `previewRedeem()`
  - `convertToAssets()`
- Shares may never be minted for free using:
  - `deposit()`
  - `mint()`
- Tokens may never be withdrawn for free using:
  - `withdraw()`
  - `redeem()`

### SecurityProps

- `decimals()` should be larger than or equal to `asset.decimals()`
- Accounting system must not be vulnerable to share price inflation attacks

## Properties to consider adding

- deposit/mint must increase totalSupply/totalAssets
- withdraw/redeem must decrease totalSupply/totalAssets
- `previewDeposit()` must not account for vault specific/user/global limits
- `previewMint()` must not account for vault specific/user/global limits
- `previewWithdraw()` must not account for vault specific/user/global limits
- `previewRedeem()` must not account for vault specific/user/global limits

## Properties that may not be testable

- Note that any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in share price or some other type of condition, meaning the depositor will lose assets by depositing.
- Whether a given method is inclusive of withdraw/deposit fees
