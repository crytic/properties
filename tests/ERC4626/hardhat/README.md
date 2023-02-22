# Crytic Properties Example (Hardhat)

Sample repository for a [crytic/properties](https://github.com/crytic/properties) + hardhat integration. 

crytic/properties is a suite of Echidna properties/tests for common interfaces & libraries that can be added to your project to find unique bugs that cannot be easily found with unit tests.

These properties are designed to be verified using Echidna, and _do not_ use Hardhat's testing functionality. Running 'npx hardhat test' will not execute them. 

Learn more:
- [crytic/properties](https://github.com/crytic/properties)
- [Echidna Fuzzer](https://github.com/crytic/echidna)
- [Echidna tutorials](https://github.com/crytic/building-secure-contracts/tree/master/program-analysis/echidna)

## Requirements

1. [Echidna](https://github.com/crytic/echidna) is installed
2. Run `npm install`
3. Run `npx hardhat compile`

## ERC4626 Properties

Contract under test is `Basic4626Impl`, which inherits from solmate's ERC4626 mixin.

Test harness is `Echidna4626Harness`

To run tests, use `npm run echidna4626` or  `echidna-test . --contract Echidna4626Harness --config ./echidna.yaml`