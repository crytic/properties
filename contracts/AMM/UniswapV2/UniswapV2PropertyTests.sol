pragma solidity ^0.6.0;

import "./Setup.sol";
import "./libraries/UniswapV2Library.sol";

contract CryticUniswapV2PropertyTests is Setup {
    event AmountsIn(uint amount0, uint amount1);
    event AmountsOut(uint amount0, uint amount1);
    event BalancesBefore(uint balance0, uint balance1);
    event BalancesAfter(uint balance0, uint balance1);
    event ReservesBefore(uint reserve0, uint reserve1);
    event ReservesAfter(uint reserve0, uint reserve1);
    event KValues(uint256 a, uint256 b);

    function _provideLiquidity(
        uint256 amount0,
        uint256 amount1
    ) internal returns (uint256, uint256, bool) {
        // Preconditions:
        amount0 = _between(amount0, 1000, uint(-1));
        amount1 = _between(amount1, 1000, uint(-1));

        if (!completed) {
            _init(amount0, amount1);
        }

        // Transfer tokens to UniswapV2Pair contract
        (bool success1, ) = user.proxy(
            address(testToken1),
            abi.encodeWithSelector(
                testToken1.transfer.selector,
                address(pair),
                amount0
            )
        );
        (bool success2, ) = user.proxy(
            address(testToken2),
            abi.encodeWithSelector(
                testToken2.transfer.selector,
                address(pair),
                amount1
            )
        );
        require(success1 && success2);

        // Action:
        (bool success, ) = user.proxy(
            address(pair),
            abi.encodeWithSelector(
                bytes4(keccak256("mint(address)")),
                address(user)
            )
        );

        return (amount0, amount1, success);
    }

    function _burnLiquidity(
        uint256 amount,
        uint256 balance
    ) internal returns (uint256, bool) {
        amount = _between(amount, 1, balance);

        // Transfer LP tokens to UniswapV2Pair contract
        (bool success1, ) = user.proxy(
            address(pair),
            abi.encodeWithSelector(
                pair.transfer.selector,
                address(pair),
                amount
            )
        );

        // Action:
        (bool success, ) = user.proxy(
            address(pair),
            abi.encodeWithSelector(
                bytes4(keccak256("burn(address)")),
                address(user)
            )
        );

        return (amount, success);
    }

    function _swap(uint256 amount0, uint256 amount1) internal {
        if (!completed) {
            _init(amount0, amount1);
        }

        require(amount0 > 0 && amount1 > 0);

        (uint reserve0Before, uint reserve1Before,) = pair.getReserves();

        uint amount0In = _between(amount0, 1, reserve0Before - 1);
        uint amount1In = _between(amount1, 1, reserve1Before - 1);
    }

    // Providing liquidity

    function test_UniV2_provideLiquidity_IncreasesK(
        uint256 amount0,
        uint256 amount1
    ) public {
        // State before
        uint lpTokenBalanceBefore = pair.balanceOf(address(user));
        (uint reserve0Before, uint reserve1Before, ) = pair.getReserves();
        uint kBefore = reserve0Before * reserve1Before;
        bool success;

        (amount0, amount1, success) = _provideLiquidity(amount0, amount1);

        // Postconditions:
        if (success) {
            (uint reserve0After, uint reserve1After, ) = pair.getReserves();
            uint kAfter = reserve0After * reserve1After;
            assert(kBefore < kAfter);
        }
    }

    function test_UniV2_provideLiquidity_IncreasesLPSupply(
        uint256 amount0,
        uint256 amount1
    ) public {
        // State before
        uint256 lpTokenSupplyBefore = pair.totalSupply();
        bool success;

        (amount0, amount1, success) = _provideLiquidity(amount0, amount1);

        // Postconditions:
        if (success) {
            uint256 lpTokenSupplyAfter = pair.totalSupply();

            assert(lpTokenSupplyBefore < lpTokenSupplyAfter);
        }
    }

    // Fails on unbalanced liquidity? TODO
    /*     function test_UniV2_provideLiquidity_tokenPriceUnchanged(
        uint256 amount0,
        uint256 amount1,
        uint256 amountIn0,
        uint256 amountIn1
    ) public {
        bool success;
        (uint reserve0Before, uint reserve1Before, ) = pair.getReserves();
        amountIn0 = _between(amountIn0, 1, reserve0Before);
        amountIn1 = _between(amountIn1, 1, reserve1Before);

        uint256 amountOut1Before = UniswapV2Library.quote(
            amountIn0,
            reserve0Before,
            reserve1Before
        );
        uint256 amountOut0Before = UniswapV2Library.quote(
            amountIn1,
            reserve1Before,
            reserve0Before
        );

        (amount0, amount1, success) = _provideLiquidity(amount0, amount1);

        if (success) {
            (uint reserve0After, uint reserve1After, ) = pair.getReserves();
            uint256 amountOut1After = UniswapV2Library.quote(
                amountIn0,
                reserve0After,
                reserve1After
            );
            uint256 amountOut0After = UniswapV2Library.quote(
                amountIn1,
                reserve1After,
                reserve0After
            );
            emit AmountsIn(amountOut1After, amountOut1Before);
            emit AmountsIn(amountOut0After, amountOut0Before);
            assert(amountOut1After == amountOut1Before);
            assert(amountOut0After == amountOut0Before);
        }
    } */

    function test_UniV2_provideLiquidity_IncreaseReserves(
        uint256 amount0,
        uint256 amount1
    ) public {
        bool success;

        (uint reserve0Before, uint reserve1Before, ) = pair.getReserves();

        (amount0, amount1, success) = _provideLiquidity(amount0, amount1);

        // Postconditions:
        if (success) {
            (uint reserve0After, uint reserve1After, ) = pair.getReserves();

            assert(reserve0Before < reserve0After);
            assert(reserve1Before < reserve1After);
        }
    }

    function test_UniV2_provideLiquidity_IncreaseUserLPBalance(
        uint256 amount0,
        uint256 amount1
    ) public {
        bool success;
        uint lpTokenBalanceBefore = pair.balanceOf(address(user));

        (amount0, amount1, success) = _provideLiquidity(amount0, amount1);

        if (success) {
            uint lpTokenBalanceAfter = pair.balanceOf(address(user));

            assert(lpTokenBalanceBefore < lpTokenBalanceAfter);
        }
    }

    // Removing liquidity

    function test_UniV2_removeLiquidity_DecreaseK(uint256 amount) public {
        pair.sync();
        // Preconditions
        bool success;
        uint lpTokenBalanceBefore = pair.balanceOf(address(user));
        require(lpTokenBalanceBefore > 0);

        (uint reserve0Before, uint reserve1Before, ) = pair.getReserves();
        uint kBefore = reserve0Before * reserve1Before;

        // Burn liquidity
        (amount, success) = _burnLiquidity(amount, lpTokenBalanceBefore);

        // Postconditions
        if (success) {
            (uint reserve0After, uint reserve1After, ) = pair.getReserves();
            uint kAfter = reserve0After * reserve1After;
            emit KValues(kBefore, kAfter);
            assert(kBefore > kAfter);
        }
    }

    function test_UniV2_removeLiquidity_DecreaseLPSupply(uint256 amount) public {
        pair.sync();
        // Preconditions
        bool success;
        uint lpTokenBalanceBefore = pair.balanceOf(address(user));
        require(lpTokenBalanceBefore > 0);

        uint256 supplyBefore = pair.totalSupply();

        // Burn liquidity
        (amount, success) = _burnLiquidity(amount, lpTokenBalanceBefore);

        // Postconditions
        if (success) {
            uint256 supplyAfter = pair.totalSupply();

            assert(supplyAfter < supplyBefore);
        }
    }
    // TODO
    function test_UniV2_removeLiquidity_tokenPriceUnchanged(uint256 amount) public {}

    function test_UniV2_removeLiquidity_DecreaseReserves(uint256 amount) public {
        pair.sync();

        // Preconditions
        bool success;
        uint lpTokenBalanceBefore = pair.balanceOf(address(user));
        require(lpTokenBalanceBefore > 0);

        (uint reserve0Before, uint reserve1Before, ) = pair.getReserves();

        // Burn liquidity
        (amount, success) = _burnLiquidity(amount, lpTokenBalanceBefore);

        // Postconditions
        if (success) {
            (uint reserve0After, uint reserve1After, ) = pair.getReserves();
            assert(reserve0Before > reserve0After);
            assert(reserve1Before > reserve1After);
        }
    }

    function test_UniV2_removeLiquidity_DecreaseUserLPBalance(uint256 amount) public {
        pair.sync();

        // Preconditions
        bool success;
        uint lpTokenBalanceBefore = pair.balanceOf(address(user));
        require(lpTokenBalanceBefore > 0);

        // Burn liquidity
        (amount, success) = _burnLiquidity(amount, lpTokenBalanceBefore);

        // Postconditions
        if (success) {
            uint lpTokenBalanceAfter = pair.balanceOf(address(user));

            assert(lpTokenBalanceBefore > lpTokenBalanceAfter);
        }
    }

    // Swapping
    function test_UniV2_swap_DoesNotDecreaseK() public {}

    function test_UniV2_swap_PathIndependence() public {}

    function test_UniV2_swap_IncreaseUserOutBalance() public {}

    function test_UniV2_swap_OutPriceIncrease_InPriceDecrease() public {}
}
