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
    ├── ERC4626
    │   ├── foundry
    │   └── hardhat
    └── ...
        ├── foundry
        └── hardhat
```

Please follow this structure in your collaborations.

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
