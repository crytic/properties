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

    function _swap(
        bool zeroForOne,
        uint256 amount0,
        uint256 amount1
    ) internal returns (bool) {
        if (!completed) {
            _init(amount0, amount1);
        }

        uint balance0Before = testToken1.balanceOf(address(user));
        uint balance1Before = testToken2.balanceOf(address(user));

        (uint reserve0Before, uint reserve1Before, ) = pair.getReserves();

        uint amount0In = _between(amount0, 1, balance0Before);
        uint amount1In = _between(amount1, 1, balance1Before);

        uint amount0Out;
        uint amount1Out;

        /**
         * Precondition of UniswapV2Pair.swap is that we transfer the token we are swapping in first.
         * So, we pick the larger of the two input amounts to transfer, and also use
         * the Uniswap library to determine how much of the other we will receive in return.
         */
        if (zeroForOne) {
            amount1In = 0;
            amount1Out = UniswapV2Library.getAmountOut(
                amount0In,
                reserve0Before,
                reserve1Before
            );
            require(amount1Out > 0);

            (bool success1, ) = user.proxy(
                address(testToken1),
                abi.encodeWithSelector(
                    testToken1.transfer.selector,
                    address(pair),
                    amount0In
                )
            );
            require(success1);
        } else {
            amount0In = 0;
            amount0Out = UniswapV2Library.getAmountOut(
                amount1In,
                reserve1Before,
                reserve0Before
            );
            require(amount0Out > 0);

            (bool success1, ) = user.proxy(
                address(testToken2),
                abi.encodeWithSelector(
                    testToken2.transfer.selector,
                    address(pair),
                    amount1In
                )
            );
            require(success1);
        }

        // Action:
        (bool success2, ) = user.proxy(
            address(pair),
            abi.encodeWithSelector(
                pair.swap.selector,
                amount0Out,
                amount1Out,
                address(user),
                ""
            )
        );
        return success2;
    }

    function _getTokenPrice(
        bool zeroForOne,
        uint256 inputAmount
    ) internal returns (uint256 amountOut) {
        (uint reserve0, uint reserve1, ) = pair.getReserves();
        amountOut = UniswapV2Library.getAmountOut(
            inputAmount,
            zeroForOne ? reserve0 : reserve1,
            zeroForOne ? reserve1 : reserve0
        );
    }

    // Providing liquidity

    function test_UniV2_provideLiquidity_IncreasesK(
        uint256 amount0,
        uint256 amount1
    ) public {
        // State before
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

    function test_UniV2_provideLiquidity_tokenPriceUnchanged(
        uint256 amount0,
        uint256 amount1,
        bool zeroForOne,
        uint256 amountIn
    ) public {
        bool success;
        UniswapV2ERC20 inToken = zeroForOne ? testToken1 : testToken2;
        uint256 actualAmountIn = _between(
            amountIn,
            1,
            inToken.balanceOf(address(user))
        );
        uint256 amountOutBefore = _getTokenPrice(zeroForOne, actualAmountIn);

        (amount0, amount1, success) = _provideLiquidity(amount0, amount1);

        if (success) {
            uint256 amountOutAfter = _getTokenPrice(zeroForOne, actualAmountIn);

            emit AmountsIn(amountOutBefore, amountOutAfter);
            assert(amountOutBefore == amountOutAfter);
        }
    }

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

    function test_UniV2_removeLiquidity_DecreaseLPSupply(
        uint256 amount
    ) public {
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

    function test_UniV2_removeLiquidity_tokenPriceUnchanged(
        uint256 amount,
        bool zeroForOne,
        uint256 amountIn
    ) public {
        bool success;
        uint lpTokenBalanceBefore = pair.balanceOf(address(user));

        UniswapV2ERC20 inToken = zeroForOne ? testToken1 : testToken2;
        uint256 actualAmountIn = _between(
            amountIn,
            1,
            inToken.balanceOf(address(user))
        );
        uint256 amountOutBefore = _getTokenPrice(zeroForOne, actualAmountIn);

        // Burn liquidity
        (amount, success) = _burnLiquidity(amount, lpTokenBalanceBefore);

        if (success) {
            uint256 amountOutAfter = _getTokenPrice(zeroForOne, actualAmountIn);

            emit AmountsIn(amountOutBefore, amountOutAfter);
            assert(amountOutBefore == amountOutAfter);
        }
    }

    function test_UniV2_removeLiquidity_DecreaseReserves(
        uint256 amount
    ) public {
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

    function test_UniV2_removeLiquidity_DecreaseUserLPBalance(
        uint256 amount
    ) public {
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
    function test_UniV2_swap_DoesNotDecreaseK(
        bool zeroForOne,
        uint256 amount0,
        uint256 amount1
    ) public {
        pair.skim(address(this));

        require(zeroForOne ? amount0 > 0 : amount1 > 0);
        (uint reserve0Before, uint reserve1Before, ) = pair.getReserves();
        require(reserve0Before > 0 && reserve1Before > 0);
        uint kBefore = reserve0Before * reserve1Before;

        bool success = _swap(zeroForOne, amount0, amount1);

        if (success) {
            (uint reserve0After, uint reserve1After, ) = pair.getReserves();
            uint kAfter = reserve0After * reserve1After;
            assert(kAfter >= kBefore);
        }
    }

    function test_UniV2_swap_PathIndependence(
        bool zeroForOne,
        uint256 amount0,
        uint256 amount1
    ) public {}

    function test_UniV2_swap_IncreaseUserOutBalance(
        bool zeroForOne,
        uint256 amount0,
        uint256 amount1
    ) public {
        pair.skim(address(this));
        UniswapV2ERC20 outToken = zeroForOne ? testToken2 : testToken1;
        uint256 outBalanceBefore = outToken.balanceOf(address(user));

        (uint reserve0Before, uint reserve1Before, ) = pair.getReserves();
        require(reserve0Before > 0 && reserve1Before > 0);

        bool success = _swap(zeroForOne, amount0, amount1);

        if (success) {
            uint256 outBalanceAfter = outToken.balanceOf(address(user));

            (uint reserve0After, uint reserve1After, ) = pair.getReserves();
            uint kAfter = reserve0After * reserve1After;
            assert(outBalanceAfter > outBalanceBefore);
        }
    }

    function test_UniV2_swap_OutPriceIncrease_InPriceDecrease(
        bool zeroForOne,
        uint256 amountIn
    ) public {
        bool success;
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

        bool success = _swap(zeroForOne, amountIn, amountIn);

        uint256 amountOut1After = _getTokenPrice(zeroForOne, actualAmountIn0);
        uint256 amountOut0After = _getTokenPrice(!zeroForOne, actualAmountIn1);

        assert(amountOut1Before > amountOut1After);
        assert(amountOut0Before < amountOut0After);
    }

    fallback() external payable {}
}
