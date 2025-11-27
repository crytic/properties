// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

/**
 * @title Transfer Fee Token
 * @notice ERC20 token that charges a fee on every transfer
 * @dev Mimics tokens like STA, PAXG that deduct fees from transfers
 * @custom:example-tokens Statera (STA), Paxos Gold (PAXG)
 * @custom:impact Receiver gets less than the transfer amount
 * @custom:exploit Used to drain $500k from Balancer pools
 * @custom:see https://github.com/d-xo/weird-erc20#fee-on-transfer
 */
contract TransferFee {
    string public name = "Transfer Fee Token";
    string public symbol = "FEE";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    uint256 public feePercentage; // in basis points (100 = 1%)

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(uint256 _feePercentage) {
        feePercentage = _feePercentage; // Default 100 = 1% fee
        totalSupply = 1000000e18;
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");

        // Calculate fee
        uint256 fee = (amount * feePercentage) / 10000;
        uint256 amountAfterFee = amount - fee;

        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amountAfterFee; // Receiver gets LESS than amount
        // Fee is burned
        totalSupply -= fee;

        emit Transfer(msg.sender, to, amountAfterFee);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Insufficient allowance");

        // Calculate fee
        uint256 fee = (amount * feePercentage) / 10000;
        uint256 amountAfterFee = amount - fee;

        balanceOf[from] -= amount;
        balanceOf[to] += amountAfterFee; // Receiver gets LESS than amount
        allowance[from][msg.sender] -= amount;
        // Fee is burned
        totalSupply -= fee;

        emit Transfer(from, to, amountAfterFee);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
}
