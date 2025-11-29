// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;
import {CryticERC4626PropertyBase} from "../util/ERC4626PropertyTestBase.sol";

/**
 * @title ERC4626 Security Properties
 * @author Crytic (Trail of Bits)
 * @notice Properties protecting ERC4626 vaults from economic attacks
 * @dev Testing Mode: INTERNAL (test harness inherits from vault and properties)
 * @dev This contract contains 2 properties that verify vaults are resistant to common
 * @dev economic attacks including decimal manipulation and share price inflation attacks.
 * @dev These properties ensure vault users are protected from value extraction exploits.
 * @dev
 * @dev Usage Example:
 * @dev ```solidity
 * @dev contract TestHarness is MyERC4626Vault, CryticERC4626SecurityProps {
 * @dev     constructor() {
 * @dev         // Initialize vault with underlying asset
 * @dev         // Ensure alice helper is properly initialized
 * @dev     }
 * @dev }
 * @dev ```
 */
contract CryticERC4626SecurityProps is CryticERC4626PropertyBase {

    /* ================================================================

                    DECIMAL CONFIGURATION PROPERTIES

       Description: Properties verifying safe decimal configuration
       Testing Mode: INTERNAL
       Property Count: 1

       ================================================================ */

    /// @title Vault Decimals Must Match Or Exceed Asset Decimals
    /// @notice The vault share token should have at least as many decimals as the asset
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: `vault.decimals() >= asset.decimals()`
    /// @dev When vault decimals are less than asset decimals, rounding errors can become
    /// @dev significant enough to enable value extraction. This property ensures sufficient
    /// @dev precision is maintained throughout deposit and withdrawal operations.
    /// @custom:property-id ERC4626-SECURITY-001
    function verify_assetDecimalsLessThanVault() public {
        assertGte(
            vault.decimals(),
            asset.decimals(),
            "The vault's share token should have greater than or equal to the number of decimals as the vault's asset token."
        );
    }


    /* ================================================================

                    INFLATION ATTACK PROPERTIES

       Description: Properties verifying resistance to price manipulation
       Testing Mode: INTERNAL
       Property Count: 1

       ================================================================ */

    /// @title Share Price Inflation Attack Must Not Succeed
    /// @notice Vault must resist share price manipulation attacks
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: After an attacker inflates share price by depositing 1 wei and donating assets,
    /// @dev a subsequent victim deposit must not lose more than 0.1% of value due to rounding
    /// @dev This tests the classic ERC4626 inflation attack where:
    /// @dev 1. Attacker deposits 1 wei to get 1 share
    /// @dev 2. Attacker directly transfers large amount of assets to vault (inflating price per share)
    /// @dev 3. Victim deposits, receives very few shares due to inflated price
    /// @dev 4. Victim redeems and loses significant value to rounding
    /// @dev Properly implemented vaults use virtual shares/assets or other mechanisms to prevent this.
    /// @custom:property-id ERC4626-SECURITY-002
    function verify_sharePriceInflationAttack(
        uint256 inflateAmount,
        uint256 delta
    ) public {
        // this has to be changed if there's deposit/withdraw fees
        uint256 lossThreshold = 0.999 ether;
        // vault is fresh
        require(vault.totalAssets() == 0);
        require(vault.totalSupply() == 0);

        // these minimums are to prevent 1-wei rounding errors from triggering the property
        require(inflateAmount > 10000);
        uint256 victimDeposit = inflateAmount + delta;
        address attacker = address(this);
        // fund account
        prepareAddressForDeposit(attacker, inflateAmount);

        uint256 shares = vault.deposit(1, attacker);
        // attack only works when pps=1:1 + new vault
        require(shares == 1);
        require(vault.totalAssets() == 1);

        // inflate pps
        asset.transfer(address(vault), inflateAmount - 1);

        // fund victim
        alice.fund(victimDeposit);
        alice.approveFunds();

        emit LogUint256("Amount of alice's deposit:", victimDeposit);
        uint256 aliceShares = alice.depositFunds(victimDeposit);
        emit LogUint256("Alice Shares:", aliceShares);
        uint256 aliceWithdrawnFunds = alice.redeemShares(aliceShares);
        emit LogUint256(
            "Amount of tokens alice withdrew:",
            aliceWithdrawnFunds
        );

        uint256 victimLoss = victimDeposit - aliceWithdrawnFunds;
        emit LogUint256("Alice Loss:", victimLoss);

        uint256 minRedeemedAmountNorm = (victimDeposit * lossThreshold) /
            1 ether;

        emit LogUint256("lossThreshold", lossThreshold);
        emit LogUint256("minRedeemedAmountNorm", minRedeemedAmountNorm);
        assertGt(
            aliceWithdrawnFunds,
            minRedeemedAmountNorm,
            "Share inflation attack possible, victim lost an amount over lossThreshold%"
        );
    }


    /* ================================================================

                    ADDITIONAL SECURITY PROPERTIES

       Description: Placeholder for additional security properties
       Testing Mode: INTERNAL
       Property Count: 0

       ================================================================ */

    /// @dev Additional security properties can be added here as new attack vectors
    /// @dev are discovered in the ERC4626 ecosystem. Common areas to monitor include:
    /// @dev - Flash loan attacks on vault accounting
    /// @dev - Reentrancy vulnerabilities in deposit/withdraw flows
    /// @dev - Fee manipulation attacks
    /// @dev - MEV extraction through sandwich attacks on deposits/withdrawals
}
