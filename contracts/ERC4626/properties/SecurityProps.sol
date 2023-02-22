pragma solidity ^0.8.0;
import {CryticERC4626PropertyBase} from "../util/ERC4626PropertyTestBase.sol";

contract CryticERC4626SecurityProps is CryticERC4626PropertyBase {
    /// @notice verify `decimals()` should be larger than or equal to `asset.decimals()` 
    function verify_assetDecimalsLessThanVault() public {
        assertGte(vault.decimals(), asset.decimals(), "The vault's share token should have greater than or equal to the number of decimals as the vault's asset token.");
    }

    /// @notice verify Accounting system must not be vulnerable to share price inflation attacks 
    function verify_sharePriceInflationAttack(uint256 inflateAmount, uint256 delta) public {
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
        asset.transfer(address(vault), inflateAmount-1);

        // fund victim
        alice.fund(victimDeposit);
        alice.approveFunds();

        emit LogUint256("Amount of alice's deposit:", victimDeposit);
        uint256 aliceShares = alice.depositFunds(victimDeposit);
        emit LogUint256("Alice Shares:", aliceShares);
        uint256 aliceWithdrawnFunds = alice.redeemShares(aliceShares);
        emit LogUint256("Amount of tokens alice withdrew:", aliceWithdrawnFunds);

        uint256 victimLoss = victimDeposit - aliceWithdrawnFunds;
        emit LogUint256("Alice Loss:", victimLoss);

        uint256 minRedeemedAmountNorm = (victimDeposit * lossThreshold) / 1 ether;

        emit LogUint256("lossThreshold", lossThreshold);
        emit LogUint256("minRedeemedAmountNorm", minRedeemedAmountNorm);
        assertGt(aliceWithdrawnFunds, minRedeemedAmountNorm, "Share inflation attack possible, victim lost an amount over lossThreshold%");
    }


}
