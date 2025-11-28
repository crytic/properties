// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

/**
 * @title Reentrant Token
 * @notice ERC20 token with ERC777-style hooks that enable reentrancy
 * @dev Mimics tokens like AMP, imBTC that call back to receiver on transfer
 * @custom:example-tokens Amp (AMP), Tokenized Bitcoin (imBTC)
 * @custom:impact Allows reentrancy attacks during transfers
 * @custom:exploit Used to drain imBTC Uniswap pool and lendf.me
 * @custom:see https://github.com/d-xo/weird-erc20#reentrant-calls
 */
contract Reentrant {
    string public name = "Reentrant Token";
    string public symbol = "REENT";
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

        // ERC777-style hook - calls back to receiver
        _callTokensReceived(msg.sender, to, amount);

        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Insufficient allowance");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;

        // ERC777-style hook - calls back to receiver
        _callTokensReceived(from, to, amount);

        emit Transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // Hook that enables reentrancy
    function _callTokensReceived(address from, address to, uint256 amount) internal {
        if (to.code.length > 0) {
            // Call tokensReceived on the recipient if it's a contract
            // This enables reentrancy attacks
            (bool success, ) = to.call(
                abi.encodeWithSignature(
                    "tokensReceived(address,address,uint256)",
                    from,
                    to,
                    amount
                )
            );
            // Ignore failures to maintain ERC20 compatibility
        }
    }
}
