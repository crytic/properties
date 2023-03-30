
# ERC721 Echidna Property Tests

- [ERC721 Echidna Property Tests](#erc721-echidna-property-tests)
  - [Consuming](#consuming)
    - [Initial setup](#initial-setup)
    - [Adding internal test methods to an ERC721](#adding-internal-test-methods-to-an-erc721)
  - [Developing](#developing)
  - [Properties Tested](#properties-tested)
    - [Should revert](#should-revert)

## Consuming

### Initial setup
To use these properties to test a given vault implementation, see the readme in the project root.

### Adding internal test methods to an ERC721
Some properties of the ERC721 spec cannot be tested externally because testing them requires interactions between the test suite & functionality that is not defined in the spec. 

To compensate for this limitation, a vault under test may optionally implement a set of methods that allow such properties to be tested. See [IERC721Internal](util/IERC721Internal.sol) for the list of methods.

These methods should be added to the ERC721 contract by a derived, test-environment-only contract to minimize changes to the production contract. When an ERC721 under test implements IERC721Internal, pass `true` to the test harness's `initialize()` function to enable the properties that require the internal interface:

```
contract MyERC721 is IERC721Internal { ... }

contract MyERC721Testable is MyERC721, IERC721Internal { ... }

contract TestHarness is CryticERC721InternalPropertyTests{
  constructor(...) {
    [...]
    initialize(true);
  }
}
```

## Developing

Before doing any development, run `forge install` to get dependencies sorted out. `forge build` will not work without the [Echidna remappings](internal/test/echidna.config.yaml).

Running tests(used to validate the properties are working correctly):

- Internal:
`echidna-test ./contracts/ERC721/internal/test/standard/ERC721ShouldRevert.sol --contract TestHarness --config ./contracts/ERC721/internal/test/echidna.config.yaml`
- External:
`echidna-test ./contracts/ERC721/external/test/standard/ERC721ShouldRevert.sol --contract TestHarness --config ./contracts/ERC721/external/test/echidna.config.yaml`

Should cause these properties to fail:
- test_ERC721_external_ownerOfInvalidTokenMustRevert
- test_ERC721_external_balanceOfZeroAddressMustRevert
- test_ERC721_external_approvingInvalidTokenMustRevert
- test_ERC721_external_transferFromNotApproved
- test_ERC721_external_transferFromZeroAddress
- test_ERC721_external_transferToZeroAddress
- test_ERC721_external_safeTransferFromRevertsOnNoncontractReceiver






Run property tests against vanilla OpenZeppelin ERC721:

- Internal:
`echidna-test ./contracts/ERC721/internal/test/standard/ERC721Compliant.sol --contract ERC721Compliant --config ./contracts/ERC721/internal/test/echidna.config.yaml`

- External:
`echidna-test ./contracts/ERC721/external/test/standard/ERC721CompliantTests.sol --contract TestHarness --config ./contracts/ERC721/external/test/echidna.config.yaml`

[EIP-721 Spec](https://eips.ethereum.org/EIPS/eip-721)

## Properties Tested

### Should revert
- `ownerOf()` must revert for the zero address
- `safeTransferFrom()` must revert if the receiver does not implement onERC721Received 