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

    function _provideLiquidity(
        uint256 amount0,
        uint256 amount1
    ) internal returns (uint256, uint256, bool) {

    }

    function _burnLiquidity(
        uint256 amount,
        uint256 balance
    ) internal returns (uint256, bool) {

    }

    function _swap(bool zeroForOne, uint256 amount0, uint256 amount1) internal returns(bool) {

    }

    // Providing liquidity

    function test_UniV2_provideLiquidity_IncreasesK(
        uint256 amount0,
        uint256 amount1
    ) public {
 
    }

    function test_UniV2_provideLiquidity_IncreasesLPSupply(
        uint256 amount0,
        uint256 amount1
    ) public {

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

    }

    function test_UniV2_provideLiquidity_IncreaseUserLPBalance(
        uint256 amount0,
        uint256 amount1
    ) public {

    }

    // Removing liquidity

    function test_UniV2_removeLiquidity_DecreaseK(uint256 amount) public {

    }

    function test_UniV2_removeLiquidity_DecreaseLPSupply(uint256 amount) public {

    }
    // TODO
    function test_UniV2_removeLiquidity_tokenPriceUnchanged(uint256 amount) public {}

    function test_UniV2_removeLiquidity_DecreaseReserves(uint256 amount) public {

    }

    function test_UniV2_removeLiquidity_DecreaseUserLPBalance(uint256 amount) public {

    }

    // Swapping
    function test_UniV2_swap_DoesNotDecreaseK(bool zeroForOne, uint256 amount0, uint256 amount1) public {

    }

    function test_UniV2_swap_PathIndependence() public {}

    function test_UniV2_swap_IncreaseUserOutBalance() public {}

    function test_UniV2_swap_OutPriceIncrease_InPriceDecrease() public {}
}
