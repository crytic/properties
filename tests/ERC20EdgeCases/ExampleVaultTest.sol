// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import "../../contracts/util/erc20/ERC20EdgeCases.sol";
import "../../contracts/util/PropertiesAsserts.sol";

/**
 * @title Example Vault Test
 * @notice Example showing how to test a vault protocol with ERC20 edge cases
 * @dev This is an educational example demonstrating proper testing patterns
 *
 * Run with Echidna:
 *   echidna . --contract ExampleVaultTest --config echidna-config.yaml
 */
contract ExampleVaultTest is PropertiesAsserts {
    ERC20EdgeCases edgeCases;
    SimpleVault vault;

    constructor() {
        edgeCases = new ERC20EdgeCases();
        vault = new SimpleVault();

        // Give this contract some tokens to test with
        address[] memory tokens = edgeCases.all_erc20();
        for (uint i = 0; i < tokens.length; i++) {
            // Transfer some tokens to this contract for testing
            // (They're minted to the deployer in the edge case constructor)
        }
    }

    /**
     * @notice Test vault accounting is correct with ALL token types
     * @dev This will catch fee-on-transfer bugs that drained Balancer
     */
    function test_vault_accountingCorrectAllTokens(uint256 amount) public {
        address[] memory tokens = edgeCases.all_erc20();

        for (uint i = 0; i < tokens.length; i++) {
            _testVaultAccounting(tokens[i], amount);
        }
    }

    /**
     * @notice Test vault doesn't lose funds with fee-on-transfer tokens
     * @dev The Balancer STA exploit ($500k) could have been caught with this
     */
    function test_vault_feeOnTransferTokens(uint256 amount) public {
        address feeToken = edgeCases.tokenByName("TransferFee");
        require(amount > 0 && amount < 1000e18);

        IERC20 token = IERC20(feeToken);
        uint256 userBalanceBefore = token.balanceOf(address(this));
        require(userBalanceBefore >= amount);

        // Approve and deposit
        token.approve(address(vault), amount);
        uint256 vaultBalanceBefore = token.balanceOf(address(vault));

        vault.deposit(feeToken, amount);

        // Check vault received correct amount (NOT the transfer amount!)
        uint256 vaultBalanceAfter = token.balanceOf(address(vault));
        uint256 actualReceived = vaultBalanceAfter - vaultBalanceBefore;

        // Vault MUST track actualReceived, not amount
        assertEq(
            vault.getUserBalance(address(this), feeToken),
            actualReceived,
            "Vault must track actual received amount with fee tokens"
        );
    }

    /**
     * @notice Test vault isn't vulnerable to reentrancy
     * @dev The imBTC Uniswap drain could have been caught with this
     */
    function test_vault_noReentrancyExploit(uint256 amount) public {
        address reentrantToken = edgeCases.tokenByName("Reentrant");
        require(amount > 0 && amount < 1000e18);

        IERC20 token = IERC20(reentrantToken);
        uint256 vaultBalanceBefore = token.balanceOf(address(vault));

        // Try to exploit with reentrant callback
        token.approve(address(vault), amount);
        vault.deposit(reentrantToken, amount);

        uint256 vaultBalanceAfter = token.balanceOf(address(vault));

        // Vault should never have less tokens than before
        assertGte(
            vaultBalanceAfter,
            vaultBalanceBefore,
            "Reentrant token drained vault!"
        );
    }

    /**
     * @notice Test vault handles tokens with missing return values
     * @dev USDT, BNB, OMG don't return bool from transfer
     */
    function test_vault_missingReturnValues(uint256 amount) public {
        address[] memory tokens = edgeCases.tokens_missing_return_values();

        for (uint i = 0; i < tokens.length; i++) {
            // Vault should handle these tokens correctly
            // (Use SafeERC20 or similar)
            _testVaultAccounting(tokens[i], amount);
        }
    }

    /**
     * @notice Test vault handles tokens with approval quirks
     * @dev USDT race protection, BNB zero approval revert, etc.
     */
    function test_vault_approvalQuirks() public {
        address[] memory tokens = edgeCases.tokens_approval_quirks();

        for (uint i = 0; i < tokens.length; i++) {
            IERC20 token = IERC20(tokens[i]);

            // Try to approve, then change approval
            // Some tokens require setting to zero first
            token.approve(address(vault), 100e18);

            // This may fail with some tokens - vault must handle it
            try token.approve(address(vault), 200e18) {
                // Success
            } catch {
                // Failed - set to zero first
                token.approve(address(vault), 0);
                token.approve(address(vault), 200e18);
            }
        }
    }

    /**
     * @notice Helper function to test vault accounting
     */
    function _testVaultAccounting(address tokenAddress, uint256 amount) internal {
        IERC20 token = IERC20(tokenAddress);
        uint256 userBalance = token.balanceOf(address(this));

        if (userBalance == 0 || amount == 0) return;
        if (amount > userBalance) amount = userBalance;

        // Get balances before
        uint256 vaultBalanceBefore = token.balanceOf(address(vault));
        uint256 userVaultBalanceBefore = vault.getUserBalance(address(this), tokenAddress);

        // Approve and deposit
        token.approve(address(vault), amount);
        vault.deposit(tokenAddress, amount);

        // Check balances after
        uint256 vaultBalanceAfter = token.balanceOf(address(vault));
        uint256 actualReceived = vaultBalanceAfter - vaultBalanceBefore;

        // Vault must track actual received amount
        assertEq(
            vault.getUserBalance(address(this), tokenAddress),
            userVaultBalanceBefore + actualReceived,
            "Vault accounting incorrect"
        );
    }
}

/**
 * @title Simple Vault
 * @notice Example vault implementation for testing
 * @dev This vault demonstrates CORRECT handling of edge case tokens
 */
contract SimpleVault {
    mapping(address => mapping(address => uint256)) public userBalances;

    event Deposit(address indexed user, address indexed token, uint256 amount);
    event Withdraw(address indexed user, address indexed token, uint256 amount);

    /**
     * @notice Deposit tokens into vault
     * @dev Correctly handles fee-on-transfer tokens by checking actual received amount
     */
    function deposit(address token, uint256 amount) external {
        require(amount > 0, "Cannot deposit zero");

        // Check actual received amount (handles fee-on-transfer tokens)
        uint256 balanceBefore = IERC20(token).balanceOf(address(this));

        // Use SafeTransferFrom to handle tokens with missing return values
        _safeTransferFrom(token, msg.sender, address(this), amount);

        uint256 balanceAfter = IERC20(token).balanceOf(address(this));
        uint256 actualReceived = balanceAfter - balanceBefore;

        // Credit user with actual received amount, not transfer amount
        userBalances[msg.sender][token] += actualReceived;

        emit Deposit(msg.sender, token, actualReceived);
    }

    /**
     * @notice Withdraw tokens from vault
     */
    function withdraw(address token, uint256 amount) external {
        require(userBalances[msg.sender][token] >= amount, "Insufficient balance");

        userBalances[msg.sender][token] -= amount;

        _safeTransfer(token, msg.sender, amount);

        emit Withdraw(msg.sender, token, amount);
    }

    /**
     * @notice Get user balance for a token
     */
    function getUserBalance(address user, address token) external view returns (uint256) {
        return userBalances[user][token];
    }

    /**
     * @notice Safe transferFrom that handles tokens with missing return values
     * @dev Based on OpenZeppelin's SafeERC20
     */
    function _safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount)
        );

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferFrom failed"
        );
    }

    /**
     * @notice Safe transfer that handles tokens with missing return values
     */
    function _safeTransfer(address token, address to, uint256 amount) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
        );

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "Transfer failed"
        );
    }
}

/**
 * @dev Minimal IERC20 interface for testing
 */
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}
