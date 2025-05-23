// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {ERC4626} from "solmate/src/mixins/ERC4626.sol";
import {FixedPointMathLib} from "solmate/src/utils/FixedPointMathLib.sol";

import {TestERC20Token} from "../../util/TestERC20Token.sol";
import {CryticERC4626PropertyTests} from "../../ERC4626PropertyTests.sol";
import {CryticERC4626Rounding} from "../../properties/RoundingProps.sol";

contract BadConvertToSharesRounding is ERC4626 {
    using FixedPointMathLib for uint256;

    uint256 private _totalAssets;

    constructor(ERC20 _asset) ERC4626(_asset, "Test Vault", _asset.symbol()) {}

    function totalAssets() public view virtual override returns (uint256) {
        return _totalAssets;
    }

    function beforeWithdraw(uint256 assets, uint256) internal override {
        _totalAssets = _totalAssets - assets;
    }

    function afterDeposit(uint256 assets, uint256) internal override {
        _totalAssets = _totalAssets + assets;
    }

    function convertToShares(
        uint256 assets
    ) public view override returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        if (supply == 0) {
            return assets;
        } else {
            return assets.mulDivUp(supply, totalAssets());
        }
    }

    function recognizeProfit(uint256 profit) public {
        TestERC20Token(address(asset)).mint(address(this), profit);
        _totalAssets += profit;
    }

    function recognizeLoss(uint256 loss) public {
        TestERC20Token(address(asset)).burn(address(this), loss);
        _totalAssets -= loss;
    }
}

contract TestHarness is CryticERC4626Rounding {
    constructor() {
        TestERC20Token _asset = new TestERC20Token("Test Token", "TT", 18);
        ERC4626 _vault = new BadConvertToSharesRounding(ERC20(address(_asset)));
        initialize(address(_vault), address(_asset), true);
    }
}
