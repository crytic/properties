### Vanilla OpenZeppelin ERC1155

- External:
`echidna . --contract ERC1155CompliantExternalHarness  --config contracts/ERC1155/external/test/echidna.config.yaml`

- Internal:
`echidna . --contract ERC1155InternalCompliant --config ./contracts/ERC1155/internal/test/echidna.config.yaml`

[EIP-1155 Spec](https://eips.ethereum.org/EIPS/eip-1155)

# Properties Tested

### Basic properties
- `balanceOf()` should revert on address zero
- `balanceOfBatch` Works as expected
- `safeTransferFrom()` should revert while transferring unapproved token
- `safeTransferFrom()` correctly update balances
- `safeTransferFrom()` should revert if `from` is the zero address
- `safeTransferFrom()` should revert if `to` is the zero address
- `safeTransferFrom()` to self should not break accounting
- `safeBatchTransferFrom()` to self should not break accounting
- `safeBatchTransferFrom()` correctly update balances
- `safeTransferFrom()` should revert if receiver is a contract that does not implement onERC1155Received()
- `safeBatchTransferFrom()` should revert if receiver is a contract that does not implement onERC1155Received()

### Burnable properties 
- `burn()` destroys token(s)
- `burn()` destroys token(s) from approved address
- `burnBatch()` destroys token(s)
- `burnBatch()` destroys token(s) from approved address
- cannot transfer a burned token
- burned token(s) should not be transferrable when burned with burnBatch

### Mintable properties
- Should mint tokens and should increase balance
- Should mint tokens in batch and should increase balance