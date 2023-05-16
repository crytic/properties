# Contributing to Properties

First, thanks for your interest in contributing to this repository! We welcome and appreciate all contributions, including bug reports, feature suggestions, tutorials/blog posts, and code improvements.

If you're unsure where to start, we recommend taking a look at our [issue tracker](https://github.com/crytic/properties/issues). If you find an issue or proposal that you feel you can do, assign yourself to it or contact the relevant [CODEOWNERS](CODEOWNERS)

## Bug reports and feature suggestions

Bug reports and feature suggestions can be submitted to our issue tracker. For bug reports, adding as much information as you can will help us in debugging and resolving the issue quickly. If you find a security vulnerability, do not open an issue, email opensource@trailofbits.com instead.

## Questions

Questions can be submitted to the issue tracker, but you may get a faster response if you ask in our [chat room](https://empireslacking.herokuapp.com/) (in the #ethereum channel).

## Code

This repository uses the pull request contribution model. Please create an account on Github if you don't have one already, fork this repository, and submit your contributions via pull requests. For more documentation, look [here](https://guides.github.com/activities/forking/).

Some pull request guidelines:

- Create a new branch from the [`main`](https://github.com/crytic/properties/tree/main) branch. If you are submitting a new feature, prefix the new branch name with `dev` (for example, `dev-add-properties-for-erc20-transfers`). If your submission is a bug fix, prefix the new branch name with `fix` (for example, `fix-typo-in-readme`). Please be descriptive in the branch name, avoid confusing or unclear names such as `mypatch2` or `bugfix`.
- Minimize irrelevant changes (formatting, whitespace, etc) to code that would otherwise not be touched by this patch. Save formatting or style corrections for a separate pull request that does not make any semantic changes.
- When possible, large changes should be split up into smaller focused pull requests.
- Fill out the pull request description with a summary of what your patch does, key changes that have been made, and any further points of discussion, if applicable. If your pull request solves an open issue, add "Fixes #xxx" at the end.
- Title your pull request with a brief description of what it's changing. "Fixes #123" is a good comment to add to the description, but makes for an unclear title on its own.
- If your are unsure about something, don't hesitate to ask!

## Directory Structure

Below is a rough outline of the directory structure:

```text
.
├── contracts                                   # Parent folder for contracts
│   ├── ERC20                                   # Properties for ERC-20 contracts
│   │   ├── external                            # External testing
│   │   │   ├── properties
│   │   │   └── util
│   │   └── internal                            # Internal testing
│   │       ├── properties
│   │       └── util
│   ├── ERC721                                  # Properties for ERC-721 contracts
│   │   ├── external                            # External testing
│   │   │   ├── properties
│   │   │   ├── test
│   │   │   └── util
│   │   └── internal                            # Internal testing
│   │       ├── properties
│   │       ├── test
│   │       └── util
│   ├── ERC4626                                 # Properties for ERC-4626 tokenized vaults
│   │   ├── properties
│   │   ├── test
│   │   │   ├── rounding
│   │   │   ├── security
│   │   │   └── usingApproval
│   │   └── util
│   ├── Math                                    # Properties for mathematical libraries
│   │   └── ABDKMath64x64
│   ├── util                                    # Helpers for new or existing properties
│   └── ...
├── lib                                         # External libraries needed for the repository
└── tests                                       # Tests for properties
    ├── ERC20
    │   ├── foundry
    │   └── hardhat
    ├── ERC721
    │   ├── foundry
    │   └── hardhat
    ├── ERC4626
    │   ├── foundry
    │   └── hardhat
    └── ...
        ├── foundry
        └── hardhat
```

Please follow this structure in your collaborations.

## How to add a property

Whenever you're adding a property to an existing properties set (e.g., ERC20, ERC721) we recommend to follow the below guidelines:
1. If a property is related to an existing property group, it should be added there. E.g., an ERC721 property *"totalSupply should never be larger than the maxSupply"* could probably be added to the `Mintable` property files. If the property is not related to any existing property group a new file should be created.
2. If the directory structure contains an `internal` and `external` directory, the property should be added to both.
3. If the directory structure contains a `test` directory, we recommmend adding a test for the property to ensure it works as expected. Once the test is added, you can add the property to the corresponding README.md file.
4. We keep a table of all the properties in [PROPERTIES.md](https://github.com/crytic/properties/blob/main/PROPERTIES.md), this should be updated whenever a new property is added.

As an example, we can illustrate the addition of the previously mentioned ERC721 property: *"totalSupply should never be larger than the maxSupply"*.

### Example
Since the ERC721 properties are split into `internal` and `external` properties we will be adding our new property to both, and since the property is related to minting we will add it to the [ERC721ExternalMintableProperties](https://github.com/crytic/properties/blob/main/contracts/ERC721/external/properties/ERC721ExternalMintableProperties.sol) and [ERC721MintableProperties](https://github.com/crytic/properties/blob/main/contracts/ERC721/internal/properties/ERC721MintableProperties.sol) files. The directory also contains a `test` folder and a [README.md](https://github.com/crytic/properties/blob/main/contracts/ERC721/README.md) with a list of all the tested properties, so we will add a test and update the README once the property is created.

**Creating an internal property.**

Since the state variable `maxSupply` isn't a universal naming convention we can create a `_prop_maxSupply` wrapper function that returns the corresponding state variable. This function can be left unimplemented since we will rely on the parent test harness to override and implement it.

```solidity
/// file: contracts/ERC721/internal/properties/ERC721MintableProperties.sol

// Should be implemented in the parent test harness
function _prop_maxSupply() internal virtual returns (uint256); 

function test_ERC721_cannotMintMoreThanMaxSupply() public virtual {
  require(isMintableOrBurnable);
  uint256 max = _prop_maxSupply();
  uint256 total = totalSupply();

  assertWithMsg(total <= max, "Total supply exceeds max supply!");
}
```

Now that the property is defined we will modify the [ERC721MintableTests.sol](https://github.com/crytic/properties/blob/main/contracts/ERC721/internal/test/standard/ERC721MintableTests.sol) contract to break the property. An easy way to do this would be to create a public minting function that does not validate the condition we are testing. The test can be executed using the following command:
```
echidna ./contracts/ERC721/internal/test/standard/ERC721MintableTests.sol --contract TestHarness --config ./contracts/ERC721/internal/test/echidna.config.yaml
```

If we correctly added our property the test should fail, indicating that Echidna has found the issue.

**Creating an External Property**

The steps for creating an external property are mostly the same, except that we will make the wrapper function `_prop_maxSupply` external and add it to the [IERC721Internal.sol](https://github.com/crytic/properties/blob/main/contracts/ERC721/util/IERC721Internal.sol) file.
```
/// file: contracts/ERC721/external/properties/ERC721ExternalMintableProperties.sol

function test_ERC721_cannotMintMoreThanMaxSupply() public virtual {
  require(token.isMintableOrBurnable);
  uint256 max = token._prop_maxSupply();
  uint256 total = token.totalSupply();

  assertWithMsg(total <= max, "Total supply exceeds max supply!");
}
```

To add a test we will modify the [ERC721IncorrectMintable](https://github.com/crytic/properties/blob/main/contracts/ERC721/external/util/ERC721IncorrectMintable.sol) contract so the property fails, and run it with the following command:

```
echidna ./contracts/ERC721/external/test/standard/ERC721MintableTests.sol --contract TestHarness --config ./contracts/ERC721/external/test/echidna.config.yaml
```

Now we can add the new property to the [README](https://github.com/crytic/properties/blob/main/contracts/ERC721/README.md) and to the [properties list](https://github.com/crytic/properties/blob/main/PROPERTIES.md).

## Linting and formatting

To install the formatters and linters, run:

```bash
npm install
```

The formatter is run with:

```bash
npm run format
```

The linter is run with:

```bash
npm run lint
```

## Running tests on your computer

Please read [README.md](README.md) for instructions on how to set up your environment and run the tests.
