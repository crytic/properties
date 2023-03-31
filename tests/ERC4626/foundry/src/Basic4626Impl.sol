pragma solidity ^0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {ERC4626} from "solmate/mixins/ERC4626.sol";

contract Basic4626Impl is ERC4626 {
    uint256 private _totalAssets;

    constructor(
        address _asset
    )
        ERC4626(
            ERC20(_asset),
            string.concat(ERC20(_asset).name(), " Test Vault"),
            string.concat(ERC20(_asset).symbol(), "-4626")
        )
    {}

    function totalAssets() public view virtual override returns (uint256) {
        return _totalAssets;
    }

    function beforeWithdraw(uint256 assets, uint256) internal override {
        _totalAssets = _totalAssets - assets;
    }

    function afterDeposit(uint256 assets, uint256) internal override {
        _totalAssets = _totalAssets + assets;
    }
}
