// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

/**
 * @title Uint96 Token
 * @notice ERC20 token that reverts on large approvals/transfers (>= 2^96)
 * @dev Mimics tokens like UNI, COMP that use uint96 for amounts
 * @custom:example-tokens Uniswap (UNI), Compound (COMP)
 * @custom:impact Reverts on large amounts, special case for type(uint256).max
 * @custom:see https://github.com/d-xo/weird-erc20#revert-on-large-approvals--transfers
 */
contract Uint96 {
    string public name = "Uint96 Token";
    string public symbol = "U96";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint96) public balanceOf;
    mapping(address => mapping(address => uint96)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        totalSupply = 1000000e18;
        balanceOf[msg.sender] = uint96(totalSupply);
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        // Reverts if amount >= 2^96
        uint96 amount96 = _safe96(amount, "Amount exceeds 96 bits");
        require(balanceOf[msg.sender] >= amount96, "Insufficient balance");
        balanceOf[msg.sender] -= amount96;
        balanceOf[to] += amount96;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        // Reverts if amount >= 2^96
        uint96 amount96 = _safe96(amount, "Amount exceeds 96 bits");
        require(balanceOf[from] >= amount96, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount96, "Insufficient allowance");
        balanceOf[from] -= amount96;
        balanceOf[to] += amount96;
        allowance[from][msg.sender] -= amount96;
        emit Transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        // Special case: uint256(-1) sets allowance to type(uint96).max
        uint96 amount96;
        if (amount == type(uint256).max) {
            amount96 = type(uint96).max;
        } else {
            amount96 = _safe96(amount, "Amount exceeds 96 bits");
        }
        allowance[msg.sender][spender] = amount96;
        emit Approval(msg.sender, spender, amount96);
        return true;
    }

    function _safe96(uint256 n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }
}
