
# ERC721 Echidna Property Tests

- [ERC721 Echidna Property Tests](#erc721-echidna-property-tests)
  - [Consuming](#consuming)
    - [Initial setup](#initial-setup)
    - [Adding internal test methods to an ERC721](#adding-internal-test-methods-to-an-erc721)
  - [Developing](#developing)
  - [Properties Tested](#properties-tested)
    - [Basic Properties](#basic-properties)
    - [Mintable Properties](#mintable-properties)
    - [Burnable Properties](#burnable-properties)

## Consuming

### Initial setup
To use these properties to test a given vault implementation, see the readme in the project root.

### Adding internal test methods to an ERC721
Some properties of the ERC721 spec cannot be tested externally because testing them requires interactions between the test suite & functionality that is not defined in the spec. 

To compensate for this limitation, a vault under test may optionally implement a set of methods that allow such properties to be tested. See [IERC721Internal](util/IERC721Internal.sol) for the list of methods.

These methods should be added to the ERC721 contract by a derived, test-environment-only contract to minimize changes to the production contract.

## Developing

Before doing any development, run `forge install` to get dependencies sorted out. `forge build` will not work without the [Echidna remappings](internal/test/echidna.config.yaml).

Running tests(used to validate the properties are working correctly):

### Basic properties

- External:
`echidna ./contracts/ERC721/external/test/standard/ERC721BasicTests.sol --contract TestHarness --config ./contracts/ERC721/external/test/echidna.config.yaml`
- Internal:
`echidna ./contracts/ERC721/internal/test/standard/ERC721BasicTests.sol --contract TestHarness --config ./contracts/ERC721/internal/test/echidna.config.yaml`

Should cause these properties to fail:
- test_ERC721_transferFromResetApproval 
- test_ERC721_transferFromUpdatesOwner 
- test_ERC721_transferFromSelf 
- test_ERC721_transferFromSelfResetsApproval 
- test_ERC721_external_ownerOfInvalidTokenMustRevert
- test_ERC721_external_balanceOfZeroAddressMustRevert
- test_ERC721_external_approvingInvalidTokenMustRevert
- test_ERC721_external_transferFromNotApproved
- test_ERC721_external_transferFromZeroAddress
- test_ERC721_external_transferToZeroAddress 
- test_ERC721_external_safeTransferFromRevertsOnNoncontractReceiver

### Mintable properties

- External:
`echidna ./contracts/ERC721/external/test/standard/ERC721MintableTests.sol --contract TestHarness --config ./contracts/ERC721/external/test/echidna.config.yaml`
- Internal:
`echidna ./contracts/ERC721/internal/test/standard/ERC721MintableTests.sol --contract TestHarness --config ./contracts/ERC721/internal/test/echidna.config.yaml`

Should cause these properties to fail:
- test_ERC721_mintIncreasesSupply
- test_ERC721_mintCreatesFreshToken

### Burnable properties

- External:
`echidna ./contracts/ERC721/external/test/standard/ERC721BurnableTests.sol --contract TestHarness --config ./contracts/ERC721/external/test/echidna.config.yaml`
- Internal:
`echidna ./contracts/ERC721/internal/test/standard/ERC721BurnableTests.sol --contract TestHarness --config ./contracts/ERC721/internal/test/echidna.config.yaml`

Should cause these properties to fail:
- test_ERC721_burnReducesTotalSupply
- test_ERC721_burnRevertOnTransferFromPreviousOwner
- test_ERC721_burnRevertOnApprove
- test_ERC721_burnRevertOnOwnerOf
- test_ERC721_burnRevertOnTransferFromZeroAddress
- test_ERC721_burnRevertOnGetApproved

### Vanilla OpenZeppelin ERC721

- Internal:
`echidna ./contracts/ERC721/internal/test/standard/ERC721Compliant.sol --contract ERC721Compliant --config ./contracts/ERC721/internal/test/echidna.config.yaml`

- External:
`echidna ./contracts/ERC721/external/test/standard/ERC721CompliantTests.sol --contract TestHarness --config ./contracts/ERC721/external/test/echidna.config.yaml`

[EIP-721 Spec](https://eips.ethereum.org/EIPS/eip-721)

## Properties Tested

### Basic properties
- test_ERC721_transferFromResetApproval 
- test_ERC721_transferFromUpdatesOwner 
- test_ERC721_transferFromSelf 
- test_ERC721_transferFromSelfResetsApproval 
- test_ERC721_external_ownerOfInvalidTokenMustRevert
- test_ERC721_external_balanceOfZeroAddressMustRevert
- test_ERC721_external_approvingInvalidTokenMustRevert
- test_ERC721_external_transferFromNotApproved
- test_ERC721_external_transferFromZeroAddress
- test_ERC721_external_transferToZeroAddress 
- test_ERC721_external_safeTransferFromRevertsOnNoncontractReceiver

### Mintable properties
- test_ERC721_mintIncreasesSupply
- test_ERC721_mintCreatesFreshToken

### Burnable properties
- test_ERC721_burnReducesTotalSupply
- test_ERC721_burnRevertOnTransferFromPreviousOwner
- test_ERC721_burnRevertOnApprove
- test_ERC721_burnRevertOnOwnerOf
- test_ERC721_burnRevertOnTransferFromZeroAddress
- test_ERC721_burnRevertOnGetApproved