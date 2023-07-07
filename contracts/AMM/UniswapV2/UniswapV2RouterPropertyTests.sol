pragma solidity ^0.6.0;

import "./Setup.sol";
import "./libraries/UniswapV2Library.sol";

contract CryticUniswapV2RouterPropertyTests is Setup {
    event AmountsIn(uint amount0, uint amount1);
    event AmountsOut(uint amount0, uint amount1);
    event BalancesBefore(uint balance0, uint balance1);
    event BalancesAfter(uint balance0, uint balance1);
    event ReservesBefore(uint reserve0, uint reserve1);
    event ReservesAfter(uint reserve0, uint reserve1);
    event KValues(uint256 a, uint256 b);
    event AssertionFailed(uint256 a, uint256 b, string reason);

    function _provideLiquidity(
        uint256 amount0,
        uint256 amount1,
        uint256 amount0Min,
        uint256 amount1Min
    ) internal returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        amount0 = _between(amount0, 1000, uint(-1));
        amount1 = _between(amount1, 1000, uint(-1));
        amount0Min = _between(amount0Min, 0, amount0);
        amount1Min = _between(amount1Min, 0, amount1);
        uint256 deadline = block.timestamp.add(1000);

        if (!completed) {
            _init(amount0, amount1);
        }

        hevm.prank(address(user));
        (amountA, amountB, liquidity) = router.addLiquidity(
            address(testToken1),
            address(testToken2),
            amount0,
            amount1,
            amount0Min,
            amount1Min,
            address(user),
            deadline
        );
    }

    function _burnLiquidity(
        uint256 amount,
        uint256 amount0Min,
        uint256 amount1Min
    ) internal returns (uint256 amount0, uint256 amount1) {
        uint256 balance = pair.balanceOf(address(user));
        (uint reserve0, uint reserve1, ) = pair.getReserves();

        amount = _between(amount, 1, balance);
        amount0Min = _between(amount0Min, 0, reserve0);
        amount1Min = _between(amount1Min, 0, reserve1);
        uint256 deadline = block.timestamp.add(1000);

        hevm.prank(address(user));
        (amount0, amount1) = router.removeLiquidity(
            address(testToken1),
            address(testToken2),
            amount,
            amount0Min,
            amount1Min,
            address(user),
            deadline
        );
    }

    function _swapExactTokensForTokens(
        bool zeroForOne,
        uint256 amountIn,
        uint256 amountOutMin
    ) internal returns (uint[] memory amounts) {
        (uint reserve0, uint reserve1, ) = pair.getReserves();

        address[] memory path = new address[](2);
        path[0] = zeroForOne ? address(testToken1) : address(testToken2);
        path[1] = zeroForOne ? address(testToken2) : address(testToken1);
        uint256 deadline = block.timestamp.add(1000);
        amountIn = _between(
            amountIn,
            1,
            UniswapV2ERC20(path[0]).balanceOf(address(user))
        );
        amountOutMin = _between(
            amountOutMin,
            0,
            zeroForOne ? reserve1 : reserve0
        );

        hevm.prank(address(user));
        amounts = router.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            address(user),
            deadline
        );
    }

    function _getTokenPrice(
        bool zeroForOne,
        uint256 inputAmount
    ) internal returns (uint256 amountOut) {
        (uint reserve0, uint reserve1, ) = pair.getReserves();
        amountOut = router.getAmountOut(
            inputAmount,
            zeroForOne ? reserve0 : reserve1,
            zeroForOne ? reserve1 : reserve0
        );
    }

    // Providing liquidity

    function test_UniV2_provideLiquidity_IncreasesK(
        uint256 amount0,
        uint256 amount1,
        uint256 amount0Min,
        uint256 amount1Min
    ) public {
        (uint reserve0Before, uint reserve1Before, ) = pair.getReserves();
        uint kBefore = reserve0Before.mul(reserve1Before);

        _provideLiquidity(amount0, amount1, amount0Min, amount1Min);

        (uint reserve0After, uint reserve1After, ) = pair.getReserves();
        uint kAfter = reserve0After.mul(reserve1After);
        if (kBefore >= kAfter) {
            emit AssertionFailed(kBefore, kAfter, "kBefore is >= kAfter");
        }
    }

    function test_UniV2_provideLiquidity_IncreasesLPSupply(
        uint256 amount0,
        uint256 amount1,
        uint256 amount0Min,
        uint256 amount1Min
    ) public {
        // State before
        uint256 lpTokenSupplyBefore = pair.totalSupply();

        _provideLiquidity(amount0, amount1, amount0Min, amount1Min);

        // Postconditions:
        uint256 lpTokenSupplyAfter = pair.totalSupply();
        assert(lpTokenSupplyBefore < lpTokenSupplyAfter);
    }

    function test_UniV2_provideLiquidity_tokenPriceUnchanged(
        uint256 amount0,
        uint256 amount1,
        uint256 amount0Min,
        uint256 amount1Min,
        bool zeroForOne,
        uint256 amountIn
    ) public {
        UniswapV2ERC20 inToken = zeroForOne ? testToken1 : testToken2;
        uint256 actualAmountIn = _between(
            amountIn,
            1,
            inToken.balanceOf(address(user))
        );
        uint256 amountOutBefore = _getTokenPrice(zeroForOne, actualAmountIn);

        _provideLiquidity(amount0, amount1, amount0Min, amount1Min);

        uint256 amountOutAfter = _getTokenPrice(zeroForOne, actualAmountIn);

        emit AmountsIn(amountOutBefore, amountOutAfter);
        assert(amountOutBefore == amountOutAfter);
    }

    function test_UniV2_provideLiquidity_IncreaseReserves(
        uint256 amount0,
        uint256 amount1,
        uint256 amount0Min,
        uint256 amount1Min
    ) public {
        (uint reserve0Before, uint reserve1Before, ) = pair.getReserves();

        _provideLiquidity(amount0, amount1, amount0Min, amount1Min);

        // Postconditions:
        (uint reserve0After, uint reserve1After, ) = pair.getReserves();

        assert(reserve0Before < reserve0After);
        assert(reserve1Before < reserve1After);
    }

    function test_UniV2_provideLiquidity_IncreaseUserLPBalance(
        uint256 amount0,
        uint256 amount1,
        uint256 amount0Min,
        uint256 amount1Min
    ) public {
        uint lpTokenBalanceBefore = pair.balanceOf(address(user));

        _provideLiquidity(amount0, amount1, amount0Min, amount1Min);

        uint lpTokenBalanceAfter = pair.balanceOf(address(user));
        assert(lpTokenBalanceBefore < lpTokenBalanceAfter);
    }

    // Removing liquidity

    function test_UniV2_removeLiquidity_DecreaseK(
        uint256 amount,
        uint256 amount0Min,
        uint256 amount1Min
    ) public {
        uint lpTokenBalanceBefore = pair.balanceOf(address(user));
        require(lpTokenBalanceBefore > 0);

        (uint reserve0Before, uint reserve1Before, ) = pair.getReserves();
        uint kBefore = reserve0Before.mul(reserve1Before);

        _burnLiquidity(amount, amount0Min, amount1Min);

        (uint reserve0After, uint reserve1After, ) = pair.getReserves();
        uint kAfter = reserve0After.mul(reserve1After);
        if (kBefore <= kAfter) {
            emit AssertionFailed(kBefore, kAfter, "kBefore is <= kAfter");
        }
    }

    function test_UniV2_removeLiquidity_DecreaseLPSupply(
        uint256 amount,
        uint256 amount0Min,
        uint256 amount1Min
    ) public {
        uint lpTokenBalanceBefore = pair.balanceOf(address(user));
        require(lpTokenBalanceBefore > 0);

        // State before
        uint256 lpTokenSupplyBefore = pair.totalSupply();

        _burnLiquidity(amount, amount0Min, amount1Min);

        // Postconditions:
        uint256 lpTokenSupplyAfter = pair.totalSupply();
        assert(lpTokenSupplyBefore > lpTokenSupplyAfter);
    }

    function test_UniV2_removeLiquidity_tokenPriceUnchanged(
        uint256 amount,
        uint256 amount0Min,
        uint256 amount1Min,
        bool zeroForOne,
        uint256 amountIn
    ) public {
        uint lpTokenBalanceBefore = pair.balanceOf(address(user));
        require(lpTokenBalanceBefore > 0);

        UniswapV2ERC20 inToken = zeroForOne ? testToken1 : testToken2;
        uint256 actualAmountIn = _between(
            amountIn,
            1,
            inToken.balanceOf(address(user))
        );
        uint256 amountOutBefore = _getTokenPrice(zeroForOne, actualAmountIn);

        _burnLiquidity(amount, amount0Min, amount1Min);

        uint256 amountOutAfter = _getTokenPrice(zeroForOne, actualAmountIn);

        emit AmountsIn(amountOutBefore, amountOutAfter);
        assert(amountOutBefore == amountOutAfter);
    }

    function test_UniV2_removeLiquidity_DecreaseReserves(
        uint256 amount,
        uint256 amount0Min,
        uint256 amount1Min
    ) public {
        uint lpTokenBalanceBefore = pair.balanceOf(address(user));
        require(lpTokenBalanceBefore > 0);

        (uint reserve0Before, uint reserve1Before, ) = pair.getReserves();

        _burnLiquidity(amount, amount0Min, amount1Min);

        // Postconditions:
        (uint reserve0After, uint reserve1After, ) = pair.getReserves();

        assert(reserve0Before > reserve0After);
        assert(reserve1Before > reserve1After);
    }

    function test_UniV2_removeLiquidity_DecreaseUserLPBalance(
        uint256 amount,
        uint256 amount0Min,
        uint256 amount1Min
    ) public {
        uint lpTokenBalanceBefore = pair.balanceOf(address(user));
        require(lpTokenBalanceBefore > 0);

        _burnLiquidity(amount, amount0Min, amount1Min);

        uint lpTokenBalanceAfter = pair.balanceOf(address(user));
        assert(lpTokenBalanceBefore > lpTokenBalanceAfter);
    }

    // Swapping
    function test_UniV2_swapExactTokensForTokens_DoesNotDecreaseK(
        bool zeroForOne,
        uint256 amountIn,
        uint256 amountOutMin
    ) public {
        (uint reserve0Before, uint reserve1Before, ) = pair.getReserves();
        require(reserve0Before > 0 && reserve1Before > 0);
        uint kBefore = reserve0Before.mul(reserve1Before);

        _swapExactTokensForTokens(zeroForOne, amountIn, amountOutMin);

        (uint reserve0After, uint reserve1After, ) = pair.getReserves();
        uint kAfter = reserve0After.mul(reserve1After);
        if (kBefore > kAfter) {
            emit AssertionFailed(kBefore, kAfter, "kBefore is > kAfter");
        }
    }

    function test_UniV2_swapExactTokensForTokens_PathIndependence(
        bool zeroForOne,
        uint256 amountIn,
        uint256 amountOutMin
    ) public {
        (uint reserve0Before, uint reserve1Before, ) = pair.getReserves();
        require(reserve0Before > 0 && reserve1Before > 0);

        uint256 balanceBefore0 = testToken1.balanceOf(address(user));
        uint256 balanceBefore1 = testToken2.balanceOf(address(user));
        uint256[] memory amounts = new uint256[](2);

        amounts = _swapExactTokensForTokens(zeroForOne, amountIn, amountOutMin);
        _swapExactTokensForTokens(!zeroForOne, amounts[1], 0);

        uint256 balanceAfter0 = testToken1.balanceOf(address(user));
        uint256 balanceAfter1 = testToken2.balanceOf(address(user));

        assert(balanceAfter0 <= balanceBefore0);
        assert(balanceAfter1 <= balanceBefore1);
    }

    function test_UniV2_swapExactTokensForTokens_IncreaseUserOutBalance(
        bool zeroForOne,
        uint256 amountIn,
        uint256 amountOutMin
    ) public {
        (uint reserve0Before, uint reserve1Before, ) = pair.getReserves();
        require(reserve0Before > 0 && reserve1Before > 0);

        UniswapV2ERC20 outToken = zeroForOne ? testToken2 : testToken1;
        uint256 balanceBefore = outToken.balanceOf(address(user));

        _swapExactTokensForTokens(zeroForOne, amountIn, amountOutMin);

        uint256 balanceAfter = outToken.balanceOf(address(user));
        assert(balanceAfter > balanceBefore);
    }

    function test_UniV2_swapExactTokensForTokens_OutPriceIncrease_InPriceDecrease(
        bool zeroForOne,
        uint256 amountIn,
        uint256 amountOutMin
    ) public {
        (uint reserve0Before, uint reserve1Before, ) = pair.getReserves();
        require(reserve0Before > 0 && reserve1Before > 0);
        
        UniswapV2ERC20 inToken = zeroForOne ? testToken1 : testToken2;
        UniswapV2ERC20 outToken = zeroForOne ? testToken2 : testToken1;

        uint256 actualAmountIn0 = _between(
            amountIn,
            1,
            inToken.balanceOf(address(user))
        );
        uint256 actualAmountIn1 = _between(
            amountIn,
            1,
            outToken.balanceOf(address(user))
        );
        uint256 amountOut1Before = _getTokenPrice(zeroForOne, actualAmountIn0);
        uint256 amountOut0Before = _getTokenPrice(!zeroForOne, actualAmountIn1);

        _swapExactTokensForTokens(zeroForOne, amountIn, amountOutMin);

        uint256 amountOut1After = _getTokenPrice(zeroForOne, actualAmountIn0);
        uint256 amountOut0After = _getTokenPrice(!zeroForOne, actualAmountIn1);

        assert(amountOut1Before > amountOut1After);
        assert(amountOut0Before < amountOut0After);
    }

    fallback() external payable {}
}
