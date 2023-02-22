pragma solidity ^0.8.0;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {ERC4626} from "solmate/src/mixins/ERC4626.sol";
import {FixedPointMathLib} from "solmate/src/utils/FixedPointMathLib.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";

import {CryticERC4626PropertyTests} from "../../ERC4626PropertyTests.sol";
import {TestERC20Token} from "../../util/TestERC20Token.sol";
import {CryticERC4626RedeemUsingApproval} from "../../properties/RedeemUsingApprovalProps.sol";

contract BadAllowanceUpdate is ERC4626 {
    using FixedPointMathLib for uint256;
    using SafeTransferLib for ERC20;

    uint256 private _totalAssets;
  
    constructor(ERC20 _asset) ERC4626(_asset, "Test Vault", _asset.symbol()) {
    }

    function totalAssets() public view virtual override returns (uint256) {
       return _totalAssets;
    }

    function beforeWithdraw(uint256 assets, uint256) internal override {
        _totalAssets = _totalAssets - assets;
    }

    function afterDeposit(uint256 assets, uint256) internal override {
        _totalAssets = _totalAssets + assets;
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public override returns (uint256 shares) {
            shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

            if (msg.sender != owner) {
                uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

                // if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
            }

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public override returns (uint256 assets) {
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            // if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }
}

contract TestHarness is CryticERC4626RedeemUsingApproval{
    constructor () {
        TestERC20Token _asset = new TestERC20Token("Test Token", "TT", 18);
        ERC4626 _vault = new BadAllowanceUpdate(ERC20(address(_asset)));
        initialize(address(_vault), address(_asset), false);
    }
}
