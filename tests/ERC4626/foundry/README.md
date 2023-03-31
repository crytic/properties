# Crytic Properties Example (Foundry)

Sample repository for a [crytic/properties](https://github.com/crytic/properties) + foundry integration.

crytic/properties is a suite of Echidna properties/tests for common interfaces & libraries that can be added to your project to find unique bugs that cannot be easily found with foundry tests.

These properties are designed to be verified using Echidna, and _do not_ use Foundry's built in fuzzer. Running 'forge test' will not execute them.

Learn more:

- [crytic/properties](https://github.com/crytic/properties)
- [Echidna Fuzzer](https://github.com/crytic/echidna)
- [Echidna tutorials](https://secure-contracts.com/program-analysis/echidna/index.html)

## Requirements

1. [Echidna](https://github.com/crytic/echidna) is installed
2. Run `foundryup`
3. Run `forge build`

## ERC4626 Properties

Contract under test is `Basic4626Impl`, which inherits from solmate's ERC4626 mixin.

Test harness is `CryticERC4626InternalHarness`

To run tests, use `echidna-test . --contract CryticERC4626InternalHarness --config ./echidna.yaml`
