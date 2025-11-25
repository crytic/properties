# Table of contents

- [Table of contents](#table-of-contents)
- [Properties](#properties)
  - [Testing the properties with fuzzing](#testing-the-properties-with-fuzzing)
    - [ERC20 tests](#erc20-tests)
      - [Integration](#integration)
      - [Configuration](#configuration)
      - [Run](#run)
      - [Example: Output for a compliant token](#example-output-for-a-compliant-token)
      - [Example: Output for a non-compliant token](#example-output-for-a-non-compliant-token)
    - [ERC721 tests](#erc721-tests)
      - [Integration](#integration-1)
      - [Configuration](#configuration-1)
      - [Run](#run-1)
      - [Example: Output for a compliant token](#example-output-for-a-compliant-token-1)
      - [Example: Output for a non-compliant token](#example-output-for-a-non-compliant-token-1)
    - [ERC4626 Tests](#erc4626-tests)
      - [Integration](#integration-2)
      - [Configuration](#configuration-2)
      - [Run](#run-2)
    - [ABDKMath64x64 tests](#abdkmath64x64-tests)
      - [Integration](#integration-3)
      - [Run](#run-3)
  - [Additional resources](#additional-resources)
- [Helper functions](#helper-functions)
  - [Usage examples](#usage-examples)
    - [Logging](#logging)
    - [Assertions](#assertions)
    - [Clamping](#clamping)
- [HEVM cheat codes support](#hevm-cheat-codes-support)
  - [Usage example](#usage-example)
- [Trophies](#trophies)
- [How to contribute to this repo?](#how-to-contribute-to-this-repo)

# Properties

This repository contains 168 code properties for:

- [ERC20](https://ethereum.org/en/developers/docs/standards/tokens/erc-20/) token: mintable, burnable, pausable and transferable invariants ([25 properties](PROPERTIES.md#erc20)).
- [ERC721](https://ethereum.org/en/developers/docs/standards/tokens/erc-721/) token: mintable, burnable, and transferable invariants ([19 properties](PROPERTIES.md#erc721)).
- [ERC4626](https://ethereum.org/en/developers/docs/standards/tokens/erc-4626/) vaults: strict specification and additional security invariants ([37 properties](PROPERTIES.md#erc4626)).
- [ABDKMath64x64](https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.md) fixed-point library invariants ([106 properties](PROPERTIES.md#abdkmath64x64)).

The goals of these properties are to:

- Detect vulnerabilities
- Ensure adherence to relevant standards
- Provide educational guidance for writing invariants

The properties can be used through unit tests or through fuzzing with [Echidna](https://github.com/crytic/echidna) or [Medusa](https://github.com/crytic/medusa).

## Testing the properties with fuzzing

1. Install [Echidna](https://github.com/crytic/echidna#installation) or [Medusa](https://github.com/crytic/medusa/blob/master/docs/src/getting_started/installation.md#installation).
2. Import the properties into to your project:

   - In case of using Hardhat, use: `npm install https://github.com/crytic/properties.git` or `yarn add https://github.com/crytic/properties.git`
   - In case of using Foundry, use: `forge install crytic/properties`

3. According to tests required, go the the specific sections:
   - [ERC20 tests](#erc20-tests)
   - [ERC4626 test](#erc4626-tests)
   - [ABDKMath64x64 tests](#abdkmath64x64-tests)

### ERC20 tests

To test an ERC20 token, follow these steps:

1. [Integration](#integration)
2. [Configuration](#configuration)
3. [Run](#run)

You can see the output for a [compliant token](#example-output-for-a-compliant-token), and [non compliant token](#example-output-for-a-non-compliant-token).

#### Integration

Decide if you want to do internal or external testing. Both approaches have advantages and disadvantages, you can check more information about them [here](https://secure-contracts.com/program-analysis/echidna/basic/common-testing-approaches.html).

For internal testing, create a new Solidity file containing the `CryticERC20InternalHarness` contract. `USER1`, `USER2` and `USER3` constants are initialized by default in `PropertiesConstants` contract to be the addresses from where echidna sends transactions, and `INITIAL_BALANCE` is by default `1000e18`:

```Solidity
pragma solidity ^0.8.0;
import "@crytic/properties/contracts/ERC20/internal/properties/ERC20BasicProperties.sol";
import "./MyToken.sol";
contract CryticERC20InternalHarness is MyToken, CryticERC20BasicProperties {

    constructor() {
        // Setup balances for USER1, USER2 and USER3:
        _mint(USER1, INITIAL_BALANCE);
        _mint(USER2, INITIAL_BALANCE);
        _mint(USER3, INITIAL_BALANCE);
        // Setup total supply:
        initialSupply = totalSupply();
    }
}
```

For external testing, create two contracts: the `CryticERC20ExternalHarness` and the `TokenMock` as shown below.
In the `CryticERC20ExternalHarness` contract you can specify which properties to test, via inheritance. In the `TokenMock` contract, you will need to modify the `isMintableOrBurnable` variable if your contract is able to mint or burn tokens.

```Solidity
pragma solidity ^0.8.0;
import "./MyToken.sol";
import {ITokenMock} from "@crytic/properties/contracts/ERC20/external/util/ITokenMock.sol";
import {CryticERC20ExternalBasicProperties} from "@crytic/properties/contracts/ERC20/external/properties/ERC20ExternalBasicProperties.sol";
import {PropertiesConstants} from "@crytic/properties/contracts/util/PropertiesConstants.sol";


contract CryticERC20ExternalHarness is CryticERC20ExternalBasicProperties {
    constructor() {
        // Deploy ERC20
        token = ITokenMock(address(new CryticTokenMock()));
    }
}

contract CryticTokenMock is MyToken, PropertiesConstants {

    bool public isMintableOrBurnable;
    uint256 public initialSupply;
    constructor () {
        _mint(USER1, INITIAL_BALANCE);
        _mint(USER2, INITIAL_BALANCE);
        _mint(USER3, INITIAL_BALANCE);
        _mint(msg.sender, INITIAL_BALANCE);

        initialSupply = totalSupply();
        isMintableOrBurnable = true;
    }
}
```

#### Configuration

**Echidna**

Create the following Echidna config file

```yaml
corpusDir: "tests/crytic/erc20/echidna-corpus-internal"
testMode: assertion
testLimit: 100000
deployer: "0x10000"
sender: ["0x10000", "0x20000", "0x30000"]
# Uncomment the following line for external testing
#allContracts: true
```

**Medusa**

Create the following Medusa config file:

```json
{
  "fuzzing": {
    "testLimit": 100000,
    "corpusDirectory": "tests/medusa-corpus",
    "deployerAddress": "0x10000",
    "senderAddresses": ["0x10000", "0x20000", "0x30000"],
    "assertionTesting": {
      "enabled": true
    },
    "propertyTesting": {
      "enabled": false
    },
    "optimizationTesting": {
      "enabled": false
    }
  },
  // Uncomment the following lines for external testing
  //		"testing": {
  //			"testAllContracts": true
  //    },
  "compilation": {
    "platform": "crytic-compile",
    "platformConfig": {
      "target": ".",
      "solcVersion": "",
      "exportDirectory": "",
      "args": ["--foundry-compile-all"]
    }
  }
}
```

To perform more than one test, save the files with a descriptive path, to identify what test each file or corpus belongs to. For instace, for these examples, we use `tests/crytic/erc20/echidna-internal.yaml` and `tests/crytic/erc20/echidna-external.yaml` for the Echidna tests for ERC20. We recommended to modify the corpus directory config opction for external tests accordingly.

The above configuration will start Echidna or Medusa in assertion mode. The target contract(s) will be deployed from address `0x10000`, and transactions will be sent from the owner as well as two different users (`0x20000` and `0x30000`). There is an initial limit of `100000` tests, but depending on the token code complexity, this can be increased. Finally, once our fuzzing tools finish the fuzzing campaign, corpus and coverage results will be available in the specified corpus directory.

#### Run

**Echidna**

- For internal testing: `echidna . --contract CryticERC20InternalHarness --config tests/crytic/erc20/echidna-internal.yaml`
- For external testing: `echidna . --contract CryticERC20ExternalHarness --config tests/crytic/erc20/echidna-external.yaml`

**Medusa**

- Go to the directory `cd tests/crytic/erc20`
- For internal testing: `medusa fuzz --target-contracts CryticERC20InternalHarness --config medusa-internal.yaml`
- For external testing: `medusa fuzz --target-contracts CryticERC20ExternalHarness --config medusa-external.yaml`

#### Example: Output for a compliant token

If the token under test is compliant and no properties will fail during fuzzing, the Echidna output should be similar to the screen below:

```
$ echidna . --contract CryticERC20InternalHarness --config tests/echidna.config.yaml
Loaded total of 23 transactions from corpus/coverage
Analyzing contract: contracts/ERC20/CryticERC20InternalHarness.sol:CryticERC20InternalHarness
name():  passed! 🎉
test_ERC20_transferFromAndBurn():  passed! 🎉
approve(address,uint256):  passed! 🎉
test_ERC20_userBalanceNotHigherThanSupply():  passed! 🎉
totalSupply():  passed! 🎉
...
```

#### Example: Output for a non-compliant token

For this example, the ExampleToken's approval function was modified to perform no action:

```
function approve(address spender, uint256 amount) public virtual override(ERC20) returns (bool) {
  // do nothing
  return true;
}
```

In this case, the Echidna output should be similar to the screen below, notice that all functions that rely on `approve()` to work correctly will have their assertions broken, and will report the situation.

```
$ echidna . --contract CryticERC20ExternalHarness --config tests/echidna.config.yaml
Loaded total of 25 transactions from corpus/coverage
Analyzing contract: contracts/ERC20/CryticERC20ExternalHarness.sol:CryticERC20ExternalHarness
name():  passed! 🎉
test_ERC20_transferFromAndBurn():  passed! 🎉
approve(address,uint256):  passed! 🎉
...
test_ERC20_setAllowance(): failed!💥
  Call sequence:
    test_ERC20_setAllowance()

Event sequence: Panic(1), AssertEqFail("Equal assertion failed. Message: Failed to set allowance") from: ERC20PropertyTests@0x00a329c0648769A73afAc7F9381E08FB43dBEA72
...
```

### ERC721 tests

To test an ERC721 token, follow these steps:

1. [Integration](#integration-1)
2. [Configuration](#configuration-1)
3. [Run](#run-1)

You can see the output for a [compliant token](#example-output-for-a-compliant-token-1), and [non compliant token](#example-output-for-a-non-compliant-token-1).

#### Integration

Decide if you want to do internal or external testing. Both approaches have advantages and disadvantages, you can check more information about them [here](https://secure-contracts.com/program-analysis/echidna/basic/common-testing-approaches.html).

For internal testing, create a new Solidity file containing the `CryticERC721InternalHarness` contract. `USER1`, `USER2` and `USER3` constants are initialized by default in `PropertiesConstants` contract to be the addresses from where echidna sends transactions.

```Solidity
pragma solidity ^0.8.0;
import "@crytic/properties/contracts/ERC721/internal/properties/ERC721BasicProperties.sol";
import "./MyToken.sol";
contract CryticERC721InternalHarness is MyToken, CryticERC721BasicProperties {

    constructor() {
    }
}
```

For external testing, create two contracts: the `CryticERC721ExternalHarness` and the `TokenMock` as shown below.
In the `CryticERC721ExternalHarness` contract you can specify which properties to test, via inheritance. In the `TokenMock` contract, you will need to modify the `isMintableOrBurnable` variable if your contract is able to mint or burn tokens.

```Solidity
pragma solidity ^0.8.0;
import "./MyToken.sol";
import {ITokenMock} from "@crytic/properties/contracts/ERC721/external/util/ITokenMock.sol";
import {CryticERC721ExternalBasicProperties} from "@crytic/properties/contracts/ERC721/external/properties/ERC721ExternalBasicProperties.sol";
import {PropertiesConstants} from "@crytic/properties/contracts/util/PropertiesConstants.sol";


contract CryticERC721ExternalHarness is CryticERC721ExternalBasicProperties {
    constructor() {
        // Deploy ERC721
        token = ITokenMock(address(new CryticTokenMock()));
    }
}

contract CryticTokenMock is MyToken, PropertiesConstants {

    bool public isMintableOrBurnable;

    constructor () {
        isMintableOrBurnable = true;
    }
<<<<<<< Updated upstream
=======

    function burn(uint256 tokenId) public {
        _burn(tokenId);
    }

    function _customMint(address to, uint256 amount) public {
        for (uint256 i; i < amount; i++) {
            _mint(to, counter++);
        }
    }
>>>>>>> Stashed changes
}
```

#### Configuration

Create the following Echidna config file

```yaml
corpusDir: "tests/crytic/erc721/echidna-corpus-internal"
testMode: assertion
testLimit: 100000
deployer: "0x10000"
sender: ["0x10000", "0x20000", "0x30000"]
```

If you're using external testing, you will also need to specify:

```yaml
allContracts: true
```

To perform more than one test, save the files with a descriptive path, to identify what test each file or corpus belongs to. For these examples, we use `tests/crytic/erc721/echidna-internal.yaml` and `tests/crytic/erc721/echidna-external.yaml` for the Echidna tests for ERC721. We recommended to modify the `corpusDir` for external tests accordingly.

The above configuration will start Echidna in assertion mode. Contract will be deployed from address `0x10000`, and transactions will be sent from the owner and two different users (`0x20000` and `0x30000`). There is an initial limit of `100000` tests, but depending on the token code complexity, this can be increased. Finally, once Echidna finishes the fuzzing campaign, corpus and coverage results will be available in the `tests/crytic/erc721/echidna-corpus-internal` directory.

#### Run

Run Echidna:

- For internal testing: `echidna . --contract CryticERC721InternalHarness --config tests/crytic/erc721/echidna-internal.yaml`
- For external testing: `echidna . --contract CryticERC721ExternalHarness --config tests/crytic/erc721/echidna-external.yaml`

Finally, inspect the coverage report in `tests/crytic/erc721/echidna-corpus-internal` or `tests/crytic/erc721/echidna-corpus-external` when it finishes.

#### Example: Output for a compliant token

If the token under test is compliant and no properties will fail during fuzzing, the Echidna output should be similar to the screen below:

```
$ echidna . --contract CryticERC721InternalHarness --config tests/echidna.config.yaml
Loaded total of 23 transactions from corpus/coverage
Analyzing contract: contracts/ERC721/CryticERC721InternalHarness.sol:CryticERC721InternalHarness
name():  passed! 🎉
test_ERC721_external_transferFromNotApproved():  passed! 🎉
approve(address,uint256):  passed! 🎉
test_ERC721_external_transferFromUpdatesOwner():  passed! 🎉
totalSupply():  passed! 🎉
...
```

#### Example: Output for a non-compliant token

For this example, the ExampleToken's balanceOf function was modified so it does not check that `owner` is the zero address:

```
function balanceOf(address owner) public view virtual override returns (uint256) {
    return _balances[owner];
}
```

In this case, the Echidna output should be similar to the screen below, notice that all functions that rely on `balanceOf()` to work correctly will have their assertions broken, and will report the situation.

```
$ echidna . --contract CryticERC721ExternalHarness --config tests/echidna.config.yaml
Loaded total of 25 transactions from corpus/coverage
Analyzing contract: contracts/ERC721/CryticERC721ExternalHarness.sol:CryticERC721ExternalHarness
name():  passed! 🎉
test_ERC721_external_transferFromUpdatesOwner():  passed! 🎉
approve(address,uint256):  passed! 🎉
...
test_ERC721_external_balanceOfZeroAddressMustRevert(): failed!💥
  Call sequence:
    test_ERC721_external_balanceOfZeroAddressMustRevert()

Event sequence: Panic(1), AssertFail("address(0) balance query should have reverted") from: ERC721PropertyTests@0x00a329c0648769A73afAc7F9381E08FB43dBEA72
...
```

### ERC4626 Tests

To test an ERC4626 token, follow these steps:

1. [Integration](#integration-2)
2. [Configuration](#configuration-2)
3. [Run](#run-2)

#### Integration

Create a new Solidity file containing the `CryticERC4626Harness` contract. Make sure it properly initializes your ERC4626 vault with a test token (`TestERC20Token`):

If you are using Hardhat:

```Solidity
    import {CryticERC4626PropertyTests} from "@crytic/properties/contracts/ERC4626/ERC4626PropertyTests.sol";
    // this token _must_ be the vault's underlying asset
    import {TestERC20Token} from "@crytic/properties/contracts/ERC4626/util/TestERC20Token.sol";
    // change to your vault implementation
    import "./Basic4626Impl.sol";

    contract CryticERC4626Harness is CryticERC4626PropertyTests {
        constructor () {
            TestERC20Token _asset = new TestERC20Token("Test Token", "TT", 18);
            Basic4626Impl _vault = new Basic4626Impl(_asset);
            initialize(address(_vault), address(_asset), false);
        }
    }
```

If you are using Foundry:

```Solidity
    import {CryticERC4626PropertyTests} from "properties/ERC4626/ERC4626PropertyTests.sol";
    // this token _must_ be the vault's underlying asset
    import {TestERC20Token} from "properties/ERC4626/util/TestERC20Token.sol";
    // change to your vault implementation
    import "../src/Basic4626Impl.sol";

    contract CryticERC4626Harness is CryticERC4626PropertyTests {
        constructor () {
            TestERC20Token _asset = new TestERC20Token("Test Token", "TT", 18);
            Basic4626Impl _vault = new Basic4626Impl(_asset);
            initialize(address(_vault), address(_asset), false);
        }
    }
```

#### Configuration

Create a minimal Echidna config file (e.g. `tests/echidna.config.yaml`)

```yaml
corpusDir: "tests/echidna-corpus"
testMode: assertion
testLimit: 100000
deployer: "0x10000"
sender: ["0x10000"]
```

#### Run

Run the test suite using `echidna . --contract CryticERC4626Harness --config tests/echidna.config.yaml` and inspect the coverage report in `tests/echidna-corpus` when it finishes.

Example repositories are available for [Hardhat](tests/ERC4626/hardhat) and [Foundry](tests/ERC4626/foundry).

Once things are up and running, consider adding internal testing methods to your Vault ABI to allow testing special edge case properties like rounding. For more info, see the [ERC4626 readme](contracts/ERC4626/README.md#adding-internal-test-methods).

### ABDKMath64x64 tests

The Solidity smart contract programming language does not have any inbuilt feature for working with decimal numbers, so for contracts dealing with non-integer values, a third party solution is needed. [ABDKMath64x64](https://github.com/abdk-consulting/abdk-libraries-solidity) is a fixed-point arithmetic Solidity library that operates on 64.64-bit numbers.

A 64.64-bit fixed-point number is a data type that consists of a sign bit, a 63-bit integer part, and a 64bit decimal part. Since there is no direct support for fractional numbers in the EVM, the underlying data type that stores the values is a 128-bit signed integer.

ABDKMath64x64 library implements [19 arithmetic operations](https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.md#simple-arithmetic "19 arithmetic operations") using fixed-point numbers and [6 conversion functions](https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.md#conversions "6 conversion functions") between integer types and fixed-point types.

We provide a number of tests related with fundamental mathematical properties of the floating point numbers. To include these tests into your repository, follow these steps:

1. [Integration](#integration-3)
2. [Run](#run-3)

#### Integration

Create a new Solidity file containing the `ABDKMath64x64Harness` contract:

```Solidity
pragma solidity ^0.8.0;
import "@crytic/properties/contracts/Math/ABDKMath64x64/ABDKMath64x64PropertyTests.sol;

contract CryticABDKMath64x64Harness is CryticABDKMath64x64PropertyTests {
    /* Any additional test can be added here */
}
```

#### Run

Run the test suite using `echidna . --contract CryticABDKMath64x64Harness --seq-len 1 --test-mode assertion --corpus-dir tests/echidna-corpus` and inspect the coverage report in `tests/echidna-corpus` when it finishes.

## Additional resources

- [Building secure contracts](https://secure-contracts.com/program-analysis/index.html)
- Our [EmpireSlacking](https://slack.empirehacking.nyc) slack server, channel #ethereum
- Watch our [fuzzing workshop](https://www.youtube.com/watch?v=QofNQxW_K08&list=PLciHOL_J7Iwqdja9UH4ZzE8dP1IxtsBXI)

# Helper functions

The repository provides a collection of functions and events meant to simplify the debugging and testing of assertions in Echidna. Commonly used functions, such as integer clamping or logging for different types are available in [contracts/util/PropertiesHelper.sol](contracts/util/PropertiesHelper.sol).

Available helpers:

- `LogXxx`: Events that can be used to log values in fuzzing tests. `string`, `uint256` and `address` loggers are provided. In Echidna's assertion mode, when an assertion violation is detected, all events emitted in the call sequence are printed.
- `assertXxx`: Asserts that a condition is met, logging violations. Assertions for equality, non-equality, greater-than, greater-than-or-equal, less-than and less-than-or-equal comparisons are provided, and user-provided messages are supported for logging.
- `clampXxx`: Limits an `int256` or `uint256` to a certain range. Clamps for less-than, less-than-or-equal, greater-than, greater-than-or-equal, and range are provided.

## Usage examples

### Logging

Log a value for debugging. When the assertion is violated, the value of `someValue` will be printed:

```solidity
pragma solidity ^0.8.0;

import "@crytic/properties/contracts/util/PropertiesHelper.sol";

contract TestProperties is PropertiesAsserts {
  // ...

  function test_some_invariant(uint256 someValue) public {
    // ...

    LogUint256("someValue is: ", someValue);

    // ...

    assert(fail);

    // ...
  }

  // ...
}
```

### Assertions

Assert equality, and log violations:

```solidity
pragma solidity ^0.8.0;

import "@crytic/properties/contracts/util/PropertiesHelper.sol";

contract TestProperties is PropertiesAsserts {
  // ...

  function test_some_invariant(uint256 someValue) public {
    // ...

    assertEq(someValue, 25, "someValue doesn't have the correct value");

    // ...
  }

  // ...
}
```

In case this assertion fails, for example if `someValue` is 30, the following will be printed in Echidna:

`Invalid: 30!=25, reason: someValue doesn't have the correct value`

### Clamping

Assure that a function's fuzzed parameter is in a certain range:

```solidity
pragma solidity ^0.8.0;

import "@crytic/properties/contracts/util/PropertiesHelper.sol";

contract TestProperties is PropertiesAsserts {
  int256 constant MAX_VALUE = 2 ** 160;
  int256 constant MIN_VALUE = -2 ** 24;

  // ...

  function test_some_invariant(int256 someValue) public {
    someValue = clampBetween(someValue, MIN_VALUE, MAX_VALUE);

    // ...
  }

  // ...
}
```

# HEVM cheat codes support

Since version 2.0.5, Echidna supports [HEVM cheat codes](https://hevm.dev/std-test-tutorial.html#supported-cheat-codes). This repository contains a [`Hevm.sol`](contracts/util/Hevm.sol) contract that exposes cheat codes for easy integration into contracts under test.

Cheat codes should be used with care, since they can alter the execution environment in ways that are not expected, and may introduce false positives or false negatives.

## Usage example

Use `prank` to simulate a call from a different `msg.sender`:

```solidity
pragma solidity ^0.8.0;

import "@crytic/properties/contracts/util/Hevm.sol";

contract TestProperties {
  // ...

  function test_some_invariant(uint256 someValue) public {
    // ...

    hevm.prank(newSender);
    otherContract.someFunction(someValue); // This call's msg.sender will be newSender
    otherContract.someFunction(someValue); // This call's msg.sender will be address(this)

    // ...
  }

  // ...
}
```

# Trophies

A list of security vulnerabilities that were found using the properties can be found on the [trophies page](Trophies.md#properties-trophies).

# How to contribute to this repo?

Contributions are welcome! You can read more about the contribution guidelines and directory structure in the [CONTRIBUTING.md](CONTRIBUTING.md) file.
