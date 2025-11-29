// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

/**
 * @title Permit No-Op Token
 * @notice ERC20 token with a permit function that doesn't revert but does nothing
 * @dev Mimics tokens like WETH that have a fallback accepting permit calls
 * @custom:example-tokens Wrapped Ether (WETH)
 * @custom:impact Permit doesn't increase allowance, breaks integrations expecting EIP-2612
 * @custom:exploit Multichain hack - assumed permit succeeded without checking allowance
 * @custom:see https://github.com/d-xo/weird-erc20#tokens-with-permit-function
 */
contract PermitNoOp {
    string public name = "Permit NoOp Token";
    string public symbol = "PNOOP";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        totalSupply = 1000000e18;
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Insufficient allowance");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // Permit function that accepts calls but doesn't do anything
    // Similar to WETH's fallback function
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        // Does nothing! No revert, no allowance increase
        // This is the dangerous behavior
    }
}
