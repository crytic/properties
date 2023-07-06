pragma solidity ^0.8.19;

import { SD59x18 } from "@prb-math-v3/SD59x18.sol";
import {add, sub, eq, gt, gte, lt, lte, lshift, rshift} from "@prb-math-v3/sd59x18/Helpers.sol";
import {convert} from "@prb-math-v3/sd59x18/Conversions.sol";
import {msb} from "@prb-math-v3/Common.sol";
import {intoUint128, intoUint256} from "@prb-math-v3/sd59x18/Casting.sol";
import {mul, div, abs, ln, exp, exp2, log2, sqrt, pow, avg, inv, log10, floor, powu, gm} from "@prb-math-v3/sd59x18/Math.sol";
import "./utils/AssertionHelperSD.sol";

contract CryticPRBMath59x18Propertiesv3 is AssertionHelperSD {

    /* ================================================================
       59x18 fixed-point constants used for testing specific values.
       This assumes that PRBMath library's convert(x) works as expected.
       ================================================================ */
    SD59x18 internal ZERO_FP = convert(0);
    SD59x18 internal ONE_FP = convert(1);
    SD59x18 internal MINUS_ONE_FP = convert(-1);
    SD59x18 internal TWO_FP = convert(2);
    SD59x18 internal THREE_FP = convert(3);
    SD59x18 internal EIGHT_FP = convert(8);
    SD59x18 internal THOUSAND_FP = convert(1000);
    SD59x18 internal MINUS_SIXTY_FOUR_FP = convert(-64);
    SD59x18 internal EPSILON = SD59x18.wrap(1);
    SD59x18 internal ONE_TENTH_FP = convert(1).div(convert(10));

    /* ================================================================
       Constants used for precision loss calculations
       ================================================================ */
    uint256 internal REQUIRED_SIGNIFICANT_DIGITS = 9;
    SD59x18 internal LOG2_PRECISION_LOSS = SD59x18.wrap(1);

    /* ================================================================
       Integer representations maximum values.
       These constants are used for testing edge cases or limits for 
       possible values.
       ================================================================ */
    /// @dev The unit number, which gives the decimal precision of SD59x18.
    int256 constant uUNIT = 1e18;
    SD59x18 constant UNIT = SD59x18.wrap(1e18);

    /// @dev The minimum value an SD59x18 number can have.
    int256 constant uMIN_SD59x18 = -57896044618658097711785492504343953926634992332820282019728_792003956564819968;
    SD59x18 constant MIN_SD59x18 = SD59x18.wrap(uMIN_SD59x18);

    /// @dev The maximum value an SD59x18 number can have.
    int256 constant uMAX_SD59x18 = 57896044618658097711785492504343953926634992332820282019728_792003956564819967;
    SD59x18 constant MAX_SD59x18 = SD59x18.wrap(uMAX_SD59x18);

    /// @dev The maximum input permitted in {exp2}.
    int256 constant uEXP2_MAX_INPUT = 192e18 - 1;
    SD59x18 constant EXP2_MAX_INPUT = SD59x18.wrap(uEXP2_MAX_INPUT);

    /// @dev The maximum input permitted in {exp}.
    int256 constant uEXP_MAX_INPUT = 133_084258667509499440;
    SD59x18 constant EXP_MAX_INPUT = SD59x18.wrap(uEXP_MAX_INPUT);

    /// @dev Euler's number as an SD59x18 number.
    SD59x18 constant E = SD59x18.wrap(2_718281828459045235);

    int256 constant uMAX_SQRT = uMAX_SD59x18 / uUNIT;
    SD59x18 constant MAX_SQRT = SD59x18.wrap(uMAX_SQRT);

    SD59x18 internal constant MAX_PERMITTED_EXP2 = SD59x18.wrap(192e18 - 1);
    SD59x18 internal constant MIN_PERMITTED_EXP2 = SD59x18.wrap(-59_794705707972522261);

    SD59x18 internal constant MAX_PERMITTED_EXP = SD59x18.wrap(133_084258667509499440);
    SD59x18 internal constant MIN_PERMITTED_EXP = SD59x18.wrap(-41_446531673892822322);
    
    SD59x18 internal constant MAX_PERMITTED_POW = SD59x18.wrap(2 ** 192 * 10 ** 18 - 1);
    /// @dev Half the UNIT number.
    int256 constant uHALF_UNIT = 0.5e18;
    SD59x18 constant HALF_UNIT = SD59x18.wrap(uHALF_UNIT);

    /// @dev log2(10) as an SD59x18 number.
    int256 constant uLOG2_10 = 3_321928094887362347;
    SD59x18 constant LOG2_10 = SD59x18.wrap(uLOG2_10);

    /// @dev log2(e) as an SD59x18 number.
    int256 constant uLOG2_E = 1_442695040888963407;
    SD59x18 constant LOG2_E = SD59x18.wrap(uLOG2_E);

    /* ================================================================
       Events used for debugging or showing information.
       ================================================================ */
    event Value(string reason, SD59x18 val);
    event LogErr(bytes error);


    /* ================================================================
       Helper functions.
       ================================================================ */

    // Check that there are remaining significant digits after a multiplication
    // Uses functions from the library under test!
    function significant_digits_are_lost_in_mult(SD59x18 a, SD59x18 b) public pure returns (bool) {
        int256 la = convert(floor(log10(abs(a))));
        int256 lb = convert(floor(log10(abs(b))));

        return(la + lb < -18);
    }

    // Return how many significant digits will remain after multiplying a and b
    // Uses functions from the library under test!
    function significant_digits_after_mult(SD59x18 a, SD59x18 b) public pure returns (uint256) {
        int256 la = convert(floor(log10(abs(a))));
        int256 lb = convert(floor(log10(abs(b))));
        int256 prec = la + lb;

        if (prec < -18) return 0;
        else return(18 + absInt(prec));
    }

    // Return how many significant digits will be lost after multiplying a and b
    // Uses functions from the library under test!
    function significant_digits_lost_in_mult(SD59x18 a, SD59x18 b) public pure returns (uint256) {
        int256 la = convert(floor(log10(abs(a))));
        int256 lb = convert(floor(log10(abs(b))));

        if (la > 0 && lb > 0) {
            return 0;
        } else {
            return absInt(la) < absInt(lb) ? uint256(-la) : uint256(-lb);
        }
    }

    // Return the absolute value of the input
    function absInt(int256 a) public pure returns (uint256) {
        return a >= 0 ? uint256(a) : uint256(-a);
    }

    /* ================================================================
       Library wrappers.
       These functions allow calling the PRBMathSD59x18 library.
       ================================================================ */
    function debug(string calldata x, SD59x18 y) public {
        emit Value(x, y);
    }

    // Wrapper for external try/catch calls
    function helpersAdd(SD59x18 x, SD59x18 y) public pure returns (SD59x18) {
       return add(x,y);
    }

    // Wrapper for external try/catch calls
    function helpersSub(SD59x18 x, SD59x18 y) public pure returns (SD59x18) {
       return sub(x,y);
    }

    // Wrapper for external try/catch calls
    function helpersMul(SD59x18 x, SD59x18 y) public pure returns (SD59x18) {
       return mul(x,y);
    }

    function helpersDiv(SD59x18 x, SD59x18 y) public pure returns (SD59x18) {
        return div(x,y);
    }

    function neg(SD59x18 x) public pure returns (SD59x18) {
       return SD59x18.wrap(-SD59x18.unwrap(x));
    }

    function helpersAbs(SD59x18 x) public pure returns (SD59x18) {
        return abs(x);
    }

    function helpersLn(SD59x18 x) public pure returns (SD59x18) {
        return ln(x);
    }

    function helpersExp(SD59x18 x) public pure returns (SD59x18) {
        return exp(x);
    }

    function helpersExp2(SD59x18 x) public pure returns (SD59x18) {
        return exp2(x);
    }

    function helpersLog2(SD59x18 x) public pure returns (SD59x18) {
        return log2(x);
    }

    function helpersSqrt(SD59x18 x) public pure returns (SD59x18) {
        return sqrt(x);
    }

    function helpersPow(SD59x18 x, SD59x18 y) public pure returns (SD59x18) {
        return pow(x, y);
    }

    function helpersPowu(SD59x18 x, uint256 y) public pure returns (SD59x18) {
        return powu(x, y);
    }

    function helpersAvg(SD59x18 x, SD59x18 y) public pure returns (SD59x18) {
        return avg(x, y);
    }

    function helpersInv(SD59x18 x) public pure returns (SD59x18) {
        return inv(x);
    }

    function helpersLog10(SD59x18 x) public pure returns (SD59x18) {
        return log10(x);
    }

    function helpersFloor(SD59x18 x) public pure returns (SD59x18) {
        return floor(x);
    }

    function helpersGm(SD59x18 x, SD59x18 y) public pure returns (SD59x18) {
        return gm(x,y);
    }

    /* ================================================================

                        TESTS FOR FUNCTION add()

       ================================================================ */

    /* ================================================================
       Tests for arithmetic properties.
       These should make sure that the implemented function complies
       with math rules and expected behaviour.
       ================================================================ */

    // Test for commutative property
    // x + y == y + x
    function add_test_commutative(SD59x18 x, SD59x18 y) public {
        SD59x18 x_y = x.add(y);
        SD59x18 y_x = y.add(x);

        assertEq(x_y, y_x);
    }

    // Test for associative property
    // (x + y) + z == x + (y + z)
    function add_test_associative(SD59x18 x, SD59x18 y, SD59x18 z) public {
        SD59x18 x_y = x.add(y);
        SD59x18 y_z = y.add(z);
        SD59x18 xy_z = x_y.add(z);
        SD59x18 x_yz = x.add(y_z);

        assertEq(xy_z, x_yz);
    }

    // Test for identity operation
    // x + 0 == x (equivalent to x + (-x) == 0)
    function add_test_identity(SD59x18 x) public {
        SD59x18 x_0 = x.add(ZERO_FP);

        assertEq(x, x_0);
        assertEq(x.sub(x), ZERO_FP);
    }

    // Test that the result increases or decreases depending
    // on the value to be added
    function add_test_values(SD59x18 x, SD59x18 y) public {
        SD59x18 x_y = x.add(y);

        if (y.gte(ZERO_FP)) {
            assertGte(x_y, x);
        } else {
            assertLt(x_y, x);
        }
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These should make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // The result of the addition must be between the maximum
    // and minimum allowed values for SD59x18
    function add_test_range(SD59x18 x, SD59x18 y) public {
        try this.helpersAdd(x, y) returns (SD59x18 result) {
            assertLte(result, MAX_SD59x18);
            assertGte(result, MIN_SD59x18);
        } catch {
            // If it reverts, just ignore
        }
    }

    // Adding zero to the maximum value shouldn't revert, as it is valid
    // Moreover, the result must be MAX_SD59x18
    function add_test_maximum_value() public {
        try this.helpersAdd(MAX_SD59x18, ZERO_FP) returns (SD59x18 result) {
            // Expected behaviour, does not revert
            assertEq(result, MAX_SD59x18);
        } catch {
            assert(false);
        }
    }

    // Adding one to the maximum value should revert, as it is out of range
    function add_test_maximum_value_plus_one() public {
        try this.helpersAdd(MAX_SD59x18, ONE_FP) {
            assert(false);
        } catch {
            // Expected behaviour, reverts
        }
    }

    // Adding zero to the minimum value shouldn't revert, as it is valid
    // Moreover, the result must be MIN_SD59x18
    function add_test_minimum_value() public {
        try this.helpersAdd(MIN_SD59x18, ZERO_FP) returns (SD59x18 result) {
            // Expected behaviour, does not revert
            assertEq(result, MIN_SD59x18);
        } catch {
            assert(false);
        }
    }

    // Adding minus one to the maximum value should revert, as it is out of range
    function add_test_minimum_value_plus_negative_one() public {
        try this.helpersAdd(MIN_SD59x18, MINUS_ONE_FP) {
            assert(false);
        } catch {
            // Expected behaviour, reverts
        }
    }

    /* ================================================================

                        TESTS FOR FUNCTION sub()

       ================================================================ */

    /* ================================================================
       Tests for arithmetic properties.
       These should make sure that the implemented function complies
       with math rules and expected behaviour.
       ================================================================ */

    // Test equivalence to addition
    // x - y == x + (-y)
    function sub_test_equivalence_to_addition(SD59x18 x, SD59x18 y) public {
        SD59x18 minus_y = neg(y);
        SD59x18 addition = x.add(minus_y);
        SD59x18 subtraction = x.sub(y);

        assertEq(addition, subtraction);
    }

    // Test for non-commutative property
    // x - y == -(y - x)
    function sub_test_non_commutative(SD59x18 x, SD59x18 y) public {
        SD59x18 x_y = x.sub(y);
        SD59x18 y_x = y.sub(x);
        
        assertEq(x_y, neg(y_x));
    }

    // Test for identity operation
    // x - 0 == x  (equivalent to x - x == 0)
    function sub_test_identity(SD59x18 x) public {
        SD59x18 x_0 = x.sub(ZERO_FP);

        assertEq(x_0, x);
        assertEq(x.sub(x), ZERO_FP);
    }

    // Test for neutrality over addition and subtraction
    // (x - y) + y == (x + y) - y == x
    function sub_test_neutrality(SD59x18 x, SD59x18 y) public {
        SD59x18 x_minus_y = x.sub(y);
        SD59x18 x_plus_y = x.add(y);

        SD59x18 x_minus_y_plus_y = x_minus_y.add(y);
        SD59x18 x_plus_y_minus_y = x_plus_y.sub(y);
        
        assertEq(x_minus_y_plus_y, x_plus_y_minus_y);
        assertEq(x_minus_y_plus_y, x);
    }

    // Test that the result increases or decreases depending
    // on the value to be subtracted
    function sub_test_values(SD59x18 x, SD59x18 y) public {
        SD59x18 x_y = x.sub(y);

        if (y.gte(ZERO_FP)) {
            assertLte(x_y, x);
        } else {
            assertGt(x_y, x);
        }
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // The result of the subtraction must be between the maximum
    // and minimum allowed values for SD59x18
    function sub_test_range(SD59x18 x, SD59x18 y) public {
        try this.helpersSub(x, y) returns (SD59x18 result) {
            assertLte(result, MAX_SD59x18);
            assertGte(result, MIN_SD59x18);
        } catch {
            // If it reverts, just ignore
        }
    }

    // Subtracting zero from the maximum value shouldn't revert, as it is valid
    // Moreover, the result must be MAX_SD59x18
    function sub_test_maximum_value() public {
        try this.helpersSub(MAX_SD59x18, ZERO_FP) returns (SD59x18 result) {
            // Expected behaviour, does not revert
            assertEq(result, MAX_SD59x18);
        } catch {
            assert(false);
        }
    }

    // Subtracting minus one from the maximum value should revert, 
    // as it is out of range
    function sub_test_maximum_value_minus_neg_one() public {
        try this.helpersSub(MAX_SD59x18, MINUS_ONE_FP) {
            assert(false);
        } catch {
            // Expected behaviour, reverts
        }
    }

    // Subtracting zero from the minimum value shouldn't revert, as it is valid
    // Moreover, the result must be MIN_SD59x18
    function sub_test_minimum_value() public {
        try this.helpersSub(MIN_SD59x18, ZERO_FP) returns (SD59x18 result) {
            // Expected behaviour, does not revert
            assertEq(result, MIN_SD59x18);
        } catch {
            assert(false);
        }
    }

    // Subtracting one from the minimum value should revert, as it is out of range
    function sub_test_minimum_value_minus_one() public {
        try this.helpersSub(MIN_SD59x18, ONE_FP) {
            assert(false);
        } catch {
            // Expected behaviour, reverts
        }
    }

    /* ================================================================

                        TESTS FOR FUNCTION mul()

       ================================================================ */

    /* ================================================================
       Tests for arithmetic properties.
       These should make sure that the implemented function complies
       with math rules and expected behaviour.
       ================================================================ */

    // Test for commutative property
    // x * y == y * x
    function mul_test_commutative(SD59x18 x, SD59x18 y) public {
        require(x.gt(MIN_SD59x18) && y.gt(MIN_SD59x18));
        SD59x18 x_y = x.mul(y);
        SD59x18 y_x = y.mul(x);

        assertEq(x_y, y_x);
    }

    // Test for associative property
    // (x * y) * z == x * (y * z)
    function mul_test_associative(SD59x18 x, SD59x18 y, SD59x18 z) public {
        require(x.gt(MIN_SD59x18) && y.gt(MIN_SD59x18) && z.gt(MIN_SD59x18));
        SD59x18 x_y = x.mul(y);
        SD59x18 y_z = y.mul(z);
        SD59x18 xy_z = x_y.mul(z);
        SD59x18 x_yz = x.mul(y_z);

        require(xy_z.neq(ZERO_FP) && x_yz.neq(ZERO_FP));

        // Checks that at least 9 digits of precision are left after multiplication
        require(significant_digits_after_mult(x, y) > REQUIRED_SIGNIFICANT_DIGITS);
        require(significant_digits_after_mult(y, z) > REQUIRED_SIGNIFICANT_DIGITS);
        require(significant_digits_after_mult(x_y, z) > REQUIRED_SIGNIFICANT_DIGITS);
        require(significant_digits_after_mult(x, y_z) > REQUIRED_SIGNIFICANT_DIGITS);

        uint256 digitsLost = significant_digits_lost_in_mult(x, y);
        digitsLost += significant_digits_lost_in_mult(x, z);
        
        assertEqWithinDecimalPrecision(xy_z, x_yz, digitsLost);
    }

    // Test for distributive property
    // x * (y + z) == x * y + x * z
    function mul_test_distributive(SD59x18 x, SD59x18 y, SD59x18 z) public {
        require(x.gt(MIN_SD59x18) && y.gt(MIN_SD59x18) && z.gt(MIN_SD59x18));
        SD59x18 y_plus_z = y.add(z);
        SD59x18 x_times_y_plus_z = x.mul(y_plus_z);

        SD59x18 x_times_y = x.mul(y);
        SD59x18 x_times_z = x.mul(z);

        require(add(x_times_y, x_times_z).neq(ZERO_FP) && x_times_y_plus_z.neq(ZERO_FP));
        assertEqWithinTolerance(add(x_times_y, x_times_z), x_times_y_plus_z, ONE_TENTH_FP, "0.1%");
    }


    // Test for identity operation
    // x * 1 == x  (also check that x * 0 == 0)
    function mul_test_identity(SD59x18 x) public {
        require(x.gt(MIN_SD59x18));
        SD59x18 x_1 = x.mul(ONE_FP);
        SD59x18 x_0 = x.mul(ZERO_FP);

        assertEq(x_0, ZERO_FP);
        assertEq(x_1, x);
    }


    // If x is positive and y is >= 1, the result should be larger than or equal to x
    // If x is positive and y is < 1, the result should be smaller than x
    function mul_test_x_positive(SD59x18 x, SD59x18 y) public {
        require(x.gte(ZERO_FP));

        SD59x18 x_y = x.mul(y);

        if (y.gte(ONE_FP)) {
            assertGte(x_y, x);
        } else {
            assertLte(x_y, x);
        }
    }

    // If x is negative and y is >= 1, the result should be smaller than or equal to x
    // If x is negative and y is < 1, the result should be larger than or equal to x
    function mul_test_x_negative(SD59x18 x, SD59x18 y) public {
        require(x.lte(ZERO_FP) && y.neq(ZERO_FP));

        SD59x18 x_y = x.mul(y);

        if (y.gte(ONE_FP)) {
            assertLte(x_y, x);
        } else {
            assertGte(x_y, x);
        }
    }
    
    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // The result of the multiplication must be between the maximum
    // and minimum allowed values for SD59x18
    function mul_test_range(SD59x18 x, SD59x18 y) public {
        require(x.gt(MIN_SD59x18) && y.gt(MIN_SD59x18));

        try this.helpersMul(x, y) returns(SD59x18 result) {
            assertLte(result, MAX_SD59x18);
            assertGte(result, MIN_SD59x18);
        } catch {
            // If it reverts, just ignore
        }
    }

    // Multiplying the maximum value times one shouldn't revert, as it is valid
    // Moreover, the result must be MAX_SD59x18
    function mul_test_maximum_value() public {
        try this.helpersMul(MAX_SD59x18, ONE_FP) returns (SD59x18 result) {
            // Expected behaviour, does not revert
            assertEq(result, MAX_SD59x18);
        } catch {
            assert(false);
        }
    }

    // Multiplying the minimum value times one shouldn't revert, as it is valid
    // Moreover, the result must be MIN_SD59x18
    function mul_test_minimum_value() public {
        try this.helpersMul(MIN_SD59x18.add(ONE_FP), ONE_FP) returns (SD59x18 result) {
            // Expected behaviour, does not revert
            assertEq(result, MIN_SD59x18.add(ONE_FP));
        } catch {
            assert(false);
        }
    }

    /* ================================================================

                        TESTS FOR FUNCTION div()

       ================================================================ */

    /* ================================================================
       Tests for arithmetic properties.
       These should make sure that the implemented function complies
       with math rules and expected behaviour.
       ================================================================ */

    // Test for identity property
    // x / 1 == x (equivalent to x / x == 1)
    function div_test_division_identity_x_div_1(SD59x18 x) public {
        require(x.gt(MIN_SD59x18));
        SD59x18 div_1 = div(x, ONE_FP);

        assertEq(x, div_1);
    }

    // Test for identity property
    // x/x should not revert unless x == 0 || x == MIN_SD59x18
    function div_test_division_identity_x_div_x(SD59x18 x) public {
        SD59x18 div_x;

        try this.helpersDiv(x, x) {
            // This should always equal one
            div_x = div(x, x);
            assertEq(div_x, ONE_FP);
        } catch {
            // There are a couple of allowed cases for a revert:
            // 1. x == 0
            // 2. x == MIN_SD59x18
            // 3. when the result overflows
            assert(x.eq(ZERO_FP) || x.eq(MIN_SD59x18));
        }
    }

    // Test for negative divisor
    // x / -y == -(x / y)
    function div_test_negative_divisor(SD59x18 x, SD59x18 y) public {
        require(x.gt(MIN_SD59x18) && y.gt(MIN_SD59x18));
        require(y.lt(ZERO_FP));

        SD59x18 x_y = div(x, y);
        SD59x18 x_minus_y = div(x, neg(y));

        assertEq(x_y, neg(x_minus_y));
    }

    // Test for division with 0 as numerator
    // 0 / x = 0
    function div_test_division_num_zero(SD59x18 x) public {
        require(x.gt(MIN_SD59x18));
        require(x.neq(ZERO_FP));

        SD59x18 div_0 = div(ZERO_FP, x);

        assertEq(ZERO_FP, div_0);
    }

    // Test that the absolute value of the result increases or
    // decreases depending on the denominator's absolute value
    function div_test_values(SD59x18 x, SD59x18 y) public {
        require(x.gt(MIN_SD59x18) && y.gt(MIN_SD59x18));
        require(y.neq(ZERO_FP));

        SD59x18 x_y = abs(div(x, y));

        if (abs(y).gte(ONE_FP)) {
            assertLte(x_y, abs(x));
        } else {
            assertGte(x_y, abs(x));
        }
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */


    // Test for division by zero
    function div_test_div_by_zero(SD59x18 x) public {
        require(x.gt(MIN_SD59x18));
        try this.helpersDiv(x, ZERO_FP) {
            // Unexpected, this should revert
            assert(false);
        } catch {
            // Expected revert
        }
    }

    // Test for division by a large value, the result should be less than one
    function div_test_maximum_denominator(SD59x18 x) public {
        require(x.gt(MIN_SD59x18));
        SD59x18 div_large = div(x, MAX_SD59x18);

        assertLte(abs(div_large), ONE_FP);
    }

    // Test for division of a large value
    // This should revert if |x| < 1 as it would return a value higher than max
    function div_test_maximum_numerator(SD59x18 y) public {
        SD59x18 div_large;

        try this.helpersDiv(MAX_SD59x18, y) {
            // If it didn't revert, then |x| >= 1
            div_large = div(MAX_SD59x18, y);

            assertGte(abs(y), ONE_FP);
        } catch {
            // Expected revert as result is higher than max
        }
    }

    // Test for values in range
    function div_test_range(SD59x18 x, SD59x18 y) public {
        require(x.gt(MIN_SD59x18) && y.gt(MIN_SD59x18));
        SD59x18 result;

        try this.helpersDiv(x, y) {
            // If it returns a value, it must be in range
            result = div(x, y);
            assertLte(result, MAX_SD59x18);
            assertGte(result, MIN_SD59x18);
        } catch {
            // Otherwise, it should revert
        }
    }

    /* ================================================================

                        TESTS FOR FUNCTION neg()

       ================================================================ */

    /* ================================================================
       Tests for mathematical properties.
       These should make sure that the implemented function complies
       with math rules and expected behaviour.
       ================================================================ */

    // Test for the double negation
    // -(-x) == x
    function neg_test_double_negation(SD59x18 x) public {
        SD59x18 double_neg = neg(neg(x));

        assertEq(x, double_neg);
    }

    // Test for the identity operation
    // x + (-x) == 0
    function neg_test_identity(SD59x18 x) public {
        SD59x18 neg_x = neg(x);

        assertEq(add(x, neg_x), ZERO_FP);
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // Test for the zero-case
    // -0 == 0
    function neg_test_zero() public {
        SD59x18 neg_x = neg(ZERO_FP);

        assertEq(neg_x, ZERO_FP);
    }

    // Test for the maximum value case
    // Since this is implementation-dependant, we will actually test with MAX_SD59x18-EPS
    function neg_test_maximum() public {
        try this.neg(sub(MAX_SD59x18, EPSILON)) {
            // Expected behaviour, does not revert
        } catch {
            assert(false);
        }
    }

    // Test for the minimum value case
    // Since this is implementation-dependant, we will actually test with MIN_SD59x18+EPS
    function neg_test_minimum() public {
        try this.neg(add(MIN_SD59x18, EPSILON)) {
            // Expected behaviour, does not revert
        } catch {
            assert(false);
        }
    }

    /* ================================================================

                        TESTS FOR FUNCTION abs()

       ================================================================ */

    /* ================================================================
       Tests for mathematical properties.
       These should make sure that the implemented function complies
       with math rules and expected behaviour.
       ================================================================ */


    // Test that the absolute value is always positive
    function abs_test_positive(SD59x18 x) public {
        require(x.gt(MIN_SD59x18));
        SD59x18 abs_x = abs(x);

        assertGte(abs_x, ZERO_FP);
    }

    // Test that the absolute value of a number equals the
    // absolute value of the negative of the same number
    function abs_test_negative(SD59x18 x) public {
        require(x.gt(MIN_SD59x18));

        SD59x18 abs_x = abs(x);
        SD59x18 abs_minus_x = abs(neg(x));

        assertEq(abs_x, abs_minus_x);
    }

    // Test the multiplicativeness property
    // | x * y | == |x| * |y|
    function abs_test_multiplicativeness(SD59x18 x, SD59x18 y) public {
        require(x.gt(MIN_SD59x18) && y.gt(MIN_SD59x18));

        SD59x18 abs_x = abs(x);
        SD59x18 abs_y = abs(y);
        SD59x18 abs_xy = abs(mul(x, y));
        SD59x18 abs_x_abs_y = mul(abs_x, abs_y);

        // Failure if all significant digits are lost
        require(significant_digits_are_lost_in_mult(abs_x, abs_y) == false);

        // Assume a tolerance of two bits of precision
        assertEqWithinBitPrecision(abs_xy, abs_x_abs_y, 2);
    }

    // Test the subadditivity property
    // | x + y | <= |x| + |y|
    function abs_test_subadditivity(SD59x18 x, SD59x18 y) public {
        require(x.gt(MIN_SD59x18) && y.gt(MIN_SD59x18));

        SD59x18 abs_x = abs(x);
        SD59x18 abs_y = abs(y);
        SD59x18 abs_xy = abs(add(x, y));

        assertLte(abs_xy, add(abs_x, abs_y));
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // Test the zero-case | 0 | = 0
    function abs_test_zero() public {
        SD59x18 abs_zero;

        try this.helpersAbs(ZERO_FP) {
            // If it doesn't revert, the value must be zero
            abs_zero = this.helpersAbs(ZERO_FP);
            assertEq(abs_zero, ZERO_FP);
        } catch {
            // Unexpected, the function must not revert here
            assert(false);
        }
    }

    // Test the maximum value
    function abs_test_maximum() public {
        SD59x18 abs_max;

        try this.helpersAbs(MAX_SD59x18) {
            // If it doesn't revert, the value must be MAX_SD59x18
            abs_max = this.helpersAbs(MAX_SD59x18);
            assertEq(abs_max, MAX_SD59x18);
        } catch {
            assert(false);
        }
    }

    // Test the minimum value
    function abs_test_minimum_revert() public {
        SD59x18 abs_min;

        try this.helpersAbs(MIN_SD59x18) {
            // It should always revert for MIN_SD59x18
            assert(false);
        } catch {}
    }

    // Test the minimum value
    function abs_test_minimum_allowed() public {
        SD59x18 abs_min;
        SD59x18 input = MIN_SD59x18.add(SD59x18.wrap(1));

        try this.helpersAbs(input) {
            // If it doesn't revert, the value must be the negative of MIN_SD59x18 + 1
            abs_min = this.helpersAbs(input);
            assertEq(abs_min, neg(input));
        } catch {
            assert(false);
        }
    }

    /* ================================================================

                        TESTS FOR FUNCTION inv()

       ================================================================ */

    /* ================================================================
       Tests for mathematical properties.
       These should make sure that the implemented function complies
       with math rules and expected behaviour.
       ================================================================ */

    // Test that the inverse of the inverse is close enough to the
    // original number
    function inv_test_double_inverse(SD59x18 x) public {
        require(x.neq(ZERO_FP));
        require(inv(x).neq(ZERO_FP));

        SD59x18 double_inv_x = inv(inv(x));

        // The maximum loss of precision will be 2 * log10(x) digits rounded up
        uint256 loss = 2 * significant_digits_lost_in_mult(x, inv(x))+ 2;

        assertEqWithinDecimalPrecision(x, double_inv_x, loss);
    }

    // Test equivalence with division
    function inv_test_division(SD59x18 x) public {
        require(x.neq(ZERO_FP));

        SD59x18 inv_x = inv(x);
        SD59x18 div_1_x = div(ONE_FP, x);

        assertEq(inv_x, div_1_x);
    }

    // Test the anticommutativity of the division
    // x / y == 1 / (y / x)
    function inv_test_division_noncommutativity(
        SD59x18 x,
        SD59x18 y
    ) public {
        require(x.neq(ZERO_FP) && y.neq(ZERO_FP));

        SD59x18 x_y = div(x, y);
        SD59x18 y_x = div(y, x);

        assertEqWithinTolerance(x_y, inv(y_x), ONE_FP, "1%");
    }

    // Test the multiplication of inverses
    // 1/(x * y) == 1/x * 1/y
    function inv_test_multiplication(SD59x18 x, SD59x18 y) public {
        require(x.neq(ZERO_FP) && y.neq(ZERO_FP));

        SD59x18 inv_x = inv(x);
        SD59x18 inv_y = inv(y);
        SD59x18 inv_x_times_inv_y = mul(inv_x, inv_y);

        SD59x18 x_y = mul(x, y);
        SD59x18 inv_x_y = inv(x_y);

        assertEqWithinTolerance(inv_x_y, inv_x_times_inv_y, ONE_FP, "1%");
    }

    // Test identity property
    function inv_test_identity(SD59x18 x) public {
        require(x.neq(ZERO_FP));

        SD59x18 inv_x = inv(x);
        SD59x18 identity = mul(inv_x, x);

        // They should agree with a tolerance of one percent
        assertEqWithinTolerance(identity, ONE_FP, ONE_FP, "1%");
    }

    // Test that the absolute value of the result is in range zero-one
    // if x is greater than one, else, the absolute value of the result
    // must be greater than one
    function inv_test_values(SD59x18 x) public {
        require(x.neq(ZERO_FP));

        SD59x18 abs_inv_x = abs(inv(x));

        if (abs(x).gte(ONE_FP)) {
            assertLte(abs_inv_x, ONE_FP);
        } else {
            assertGt(abs_inv_x, ONE_FP);
        }
    }

    // Test that the result has the same sign as the argument.
    // Since inv() rounds towards zero, we are checking the zero case as well
    function inv_test_sign(SD59x18 x) public {
        require(x.neq(ZERO_FP));

        SD59x18 inv_x = inv(x);

        if (x.gt(ZERO_FP)) {
            assertGte(inv_x, ZERO_FP);
        } else {
            assertLte(inv_x, ZERO_FP);
        }
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // Test the zero-case, should revert
    function inv_test_zero() public {
        try this.helpersInv(ZERO_FP) {
            // Unexpected, the function must revert
            assert(false);
        } catch {}
    }

    // Test the maximum value case, should not revert, and be close to zero
    function inv_test_maximum() public {
        SD59x18 inv_maximum;

        try this.helpersInv(MAX_SD59x18) {
            inv_maximum = this.helpersInv(MAX_SD59x18);
            assertEqWithinBitPrecision(inv_maximum, ZERO_FP, 10);
        } catch {
            // Unexpected, the function must not revert
            assert(false);
        }
    }

    // Test the minimum value case, should not revert, and be close to zero
    function inv_test_minimum() public {
        SD59x18 inv_minimum;

        try this.helpersInv(MIN_SD59x18) {
            inv_minimum = this.helpersInv(MIN_SD59x18);
            assertEqWithinBitPrecision(abs(inv_minimum), ZERO_FP, 10);
        } catch {
            // Unexpected, the function must not revert
            assert(false);
        }
    }

    /* ================================================================

                        TESTS FOR FUNCTION avg()

       ================================================================ */

    /* ================================================================
        Tests for arithmetic properties.
       These should make sure that the implemented function complies
       with math rules and expected behaviour.
       ================================================================ */

    // Test that the result is between the two operands
    // avg(x, y) >= min(x, y) && avg(x, y) <= max(x, y)
    function avg_test_values_in_range(SD59x18 x, SD59x18 y) public {
        SD59x18 avg_xy = avg(x, y);

        if (x.gte(y)) {
            assertGte(avg_xy, y);
            assertLte(avg_xy, x);
        } else {
            assertGte(avg_xy, x);
            assertLte(avg_xy, y);
        }
    }

    // Test that the average of the same number is itself
    // avg(x, x) == x
    function avg_test_one_value(SD59x18 x) public {
        SD59x18 avg_x = avg(x, x);

        assertEq(avg_x, x);
    }

    // Test that the order of operands is irrelevant
    // avg(x, y) == avg(y, x)
    function avg_test_operand_order(SD59x18 x, SD59x18 y) public {
        SD59x18 avg_xy = avg(x, y);
        SD59x18 avg_yx = avg(y, x);

        assertEq(avg_xy, avg_yx);
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // Test for the maximum value
    function avg_test_maximum() public {
        SD59x18 result;

        // This may revert due to overflow depending on implementation
        // If it doesn't revert, the result must be MAX_SD59x18
        try this.helpersAvg(MAX_SD59x18, MAX_SD59x18) {
            result = this.helpersAvg(MAX_SD59x18, MAX_SD59x18);
            assertEq(result, MAX_SD59x18);
        } catch {
            assert(false);
        }
    }

    // Test for the minimum value
    function avg_test_minimum() public {
        SD59x18 result;

        // This may revert due to overflow depending on implementation
        // If it doesn't revert, the result must be MIN_SD59x18
        try this.helpersAvg(MIN_SD59x18, MIN_SD59x18) {
            result = this.helpersAvg(MIN_SD59x18, MIN_SD59x18);
            assertEq(result, MIN_SD59x18);
        } catch {
            assert(false);
        }
    }

    /* ================================================================

                        TESTS FOR FUNCTION pow()

       ================================================================ */

    /* ================================================================
       Tests for arithmetic properties.
       These should make sure that the implemented function complies
       with math rules and expected behaviour.
       ================================================================ */

    // Test for zero exponent
    // x ** 0 == 1
    function pow_test_zero_exponent(SD59x18 x) public {
        require(x.gte(ZERO_FP) && x.lte(MAX_PERMITTED_POW));
        SD59x18 x_pow_0 = pow(x, ZERO_FP);

        assertEq(x_pow_0, ONE_FP);
    }

    // Test for zero base
    // 0 ** a == 0 (for positive a)
    function pow_test_zero_base_non_zero_exponent(SD59x18 a) public {
        require(a.gt(ZERO_FP));
        SD59x18 zero_pow_a = pow(ZERO_FP, a);

        assertEq(zero_pow_a, ZERO_FP);
    }

    // Test for zero base
    // 0 ** 0 == 1
    function pow_test_zero_base_zero_exponent() public {
        SD59x18 zero_pow_a = pow(ZERO_FP, ZERO_FP);

        assertEq(zero_pow_a, ONE_FP);
    }

    // Test for exponent one
    // x ** 1 == x
    function pow_test_one_exponent(SD59x18 x) public {
        require(x.gte(ZERO_FP) && x.lte(MAX_PERMITTED_POW));
        SD59x18 x_pow_1 = pow(x, ONE_FP);

        assertEq(x_pow_1, x);
    }

    // Test for base one
    // 1 ** a == 1
    function pow_test_base_one(SD59x18 a) public {
        SD59x18 one_pow_a = pow(ONE_FP, a);

        assertEq(one_pow_a, ONE_FP);
    }


    // Test for product of powers of the same base
    // x ** a * x ** b == x ** (a + b)
    function pow_test_product_same_base(
        SD59x18 x,
        SD59x18 a,
        SD59x18 b
    ) public {
        require(x.gte(ZERO_FP) && x.lte(MAX_PERMITTED_POW));
        require(a.gte(MIN_PERMITTED_EXP2) && b.gte(MIN_PERMITTED_EXP2));

        SD59x18 x_a = pow(x, a);
        SD59x18 x_b = pow(x, b);
        SD59x18 x_ab = pow(x, a.add(b));

        assertEqWithinDecimalPrecision(mul(x_a, x_b), x_ab, 9);
    }

    // Test for power of an exponentiation
    // (x ** a) ** b == x ** (a * b)
    function pow_test_power_of_an_exponentiation(
        SD59x18 x,
        SD59x18 a,
        SD59x18 b
    ) public {
        require(x.gte(ZERO_FP) && x.lte(MAX_PERMITTED_POW));
        require(a.mul(b).neq(ZERO_FP));
        require(a.gte(MIN_PERMITTED_EXP2) && b.gte(MIN_PERMITTED_EXP2));

        SD59x18 x_a = pow(x, a);
        SD59x18 x_a_b = pow(x_a, b);
        SD59x18 x_ab = pow(x, a.mul(b));
        require(x_a_b.neq(ZERO_FP) && x_ab.neq(ZERO_FP));

        assertEqWithinDecimalPrecision(x_a_b, x_ab, 9);
    }

    // Test for power of a product
    // (x * y) ** a == x ** a * y ** a
    function pow_test_product_power(
        SD59x18 x,
        SD59x18 y,
        SD59x18 a
    ) public {
        require(x.gte(ZERO_FP) && x.lte(MAX_PERMITTED_POW));
        require(y.gte(ZERO_FP) && y.lte(MAX_PERMITTED_POW));

        require(a.gt(convert(2 ** 32))); // to avoid massive loss of precision

        SD59x18 x_y = mul(x, y);
        SD59x18 xy_a = pow(x_y, a);

        SD59x18 x_a = pow(x, a);
        SD59x18 y_a = pow(y, a);

        assertEqWithinBitPrecision(mul(x_a, y_a), xy_a, 10);
    }

    // Test for result being greater than or lower than the argument, depending on
    // its absolute value and the value of the exponent
    function pow_test_positive_exponent(SD59x18 x, SD59x18 a) public {
        require(x.gte(ZERO_FP) && a.gte(ZERO_FP));

        SD59x18 x_a = pow(x, a);

        if (abs(x).gte(ONE_FP)) {
            assertGte(abs(x_a), ONE_FP);
        }

        if (abs(x).lte(ONE_FP)) {
            assertLte(abs(x_a), ONE_FP);
        }
    }

    // Test for result being greater than or lower than the argument, depending on
    // its absolute value and the value of the exponent
    function pow_test_negative_exponent(SD59x18 x, SD59x18 a) public {
        require(x.gte(ZERO_FP) && a.lte(ZERO_FP));

        SD59x18 x_a = pow(x, a);

        if (abs(x).gte(ONE_FP)) {
            assertLte(abs(x_a), ONE_FP);
        }

        if (abs(x).lte(ONE_FP)) {
            assertGte(abs(x_a), ONE_FP);
        }
    }

    // Test for result sign: if the exponent is even, sign is positive
    // if the exponent is odd, preserves the sign of the base
    function pow_test_sign(SD59x18 x, SD59x18 a) public {
        require(x.gte(ZERO_FP));

        SD59x18 x_a = pow(x, a);

        // This prevents the case where a small negative number gets
        // rounded down to zero and thus changes sign
        require(x_a.neq(ZERO_FP));

        // If the exponent is even
        if (a.mod(convert(2)).eq(ZERO_FP)) {
            assertEq(x_a, abs(x_a));
        } else {
            // x_a preserves x sign
            if (x.lt(ZERO_FP)) {
                assertLt(x_a, ZERO_FP);
            } else {
                assertGt(x_a, ZERO_FP);
            }
        }
    }

    // pow(2, a) == exp2(a)
    function pow_test_exp2_equivalence(SD59x18 a) public {
        SD59x18 pow_result = pow(convert(2), a);
        SD59x18 exp2_result = exp2(a);

        assertEq(pow_result, exp2_result);
    }

    // Power is strictly increasing
    // x > y && a >= 0 --> pow(x, a) >= pow(y, a)
    function pow_test_strictly_increasing(SD59x18 x, SD59x18 y, SD59x18 a) public {
        require(x.gt(y) && x.lte(MAX_PERMITTED_POW));
        require(a.gte(ZERO_FP));

        SD59x18 x_a = pow(x, a);
        SD59x18 y_a = pow(y, a);

        assertGte(x_a, y_a);
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // Test for maximum base and exponent > 1
    function pow_test_maximum_base(SD59x18 a) public {
        require(a.gt(ONE_FP));

        try this.helpersPow(MAX_SD59x18, a) {
            // Unexpected, should revert because of overflow
            assert(false);
        } catch {
            // Expected revert
        }
    }

    // Test for abs(base) < 1 and high exponent
    function pow_test_high_exponent(SD59x18 x, SD59x18 a) public {
        require(abs(x).lt(ONE_FP) && a.gt(convert(2 ** 32)));

        SD59x18 result = pow(x, a);

        assertEq(result, ZERO_FP);
    }

    /* ================================================================

                        TESTS FOR FUNCTION sqrt()

       ================================================================ */

    /* ================================================================
       Tests for arithmetic properties.
       These should make sure that the implemented function complies
       with math rules and expected behaviour.
       ================================================================ */

    // Test for the inverse operation
    // sqrt(x) * sqrt(x) == x
    function sqrt_test_inverse_mul(SD59x18 x) public {
        require(x.gte(ZERO_FP));

        SD59x18 sqrt_x = sqrt(x);
        SD59x18 sqrt_x_squared = mul(sqrt_x, sqrt_x);

        // Precision loss is at most half the bits of the operand
        assertEqWithinBitPrecision(sqrt_x_squared, x, (intoUint256(log2(x)) >> 1) + 2);
    }

    // Test for the inverse operation
    // sqrt(x) ** 2 == x
    function sqrt_test_inverse_pow(SD59x18 x) public {
        require(x.gte(ZERO_FP));

        SD59x18 sqrt_x = sqrt(x);
        SD59x18 sqrt_x_squared = pow(sqrt_x, convert(2));

        // Precision loss is at most half the bits of the operand
        assertEqWithinBitPrecision(sqrt_x_squared, x, (intoUint256(log2(x)) >> 1) + 2);
    }

    // Test for distributive property respect to the multiplication
    // sqrt(x) * sqrt(y) == sqrt(x * y)
    function sqrt_test_distributive(SD59x18 x, SD59x18 y) public {
        require(x.gte(ZERO_FP) && y.gte(ZERO_FP));

        SD59x18 sqrt_x = sqrt(x);
        SD59x18 sqrt_y = sqrt(y);
        SD59x18 sqrt_x_sqrt_y = mul(sqrt_x, sqrt_y);
        SD59x18 sqrt_xy = sqrt(mul(x, y));

        // Ensure we have enough significant digits for the result to be meaningful
        require(significant_digits_after_mult(x, y) > REQUIRED_SIGNIFICANT_DIGITS);
        require(
            significant_digits_after_mult(sqrt_x, sqrt_y) >
                REQUIRED_SIGNIFICANT_DIGITS
        );

        // Allow an error of up to one tenth of a percent
        assertEqWithinTolerance(sqrt_x_sqrt_y, sqrt_xy, ONE_TENTH_FP, "0.1%");
    }

    // Test that sqrt is strictly increasing
    // x >= 0 && y > x --> sqrt(y) >= sqrt(x)
    function sqrt_test_strictly_increasing(SD59x18 x, SD59x18 y) public {
        require(x.gte(ZERO_FP) && x.lte(MAX_SQRT.sub(SD59x18.wrap(1))));
        require(y.gt(x) && y.lte(MAX_SQRT));

        SD59x18 sqrt_x = sqrt(x);
        SD59x18 sqrt_y = sqrt(y);

        assertGte(sqrt_y, sqrt_x);
    }

    // Square root of perfect square should be equal to x
    // sqrt(x * x) == x
    function sqrt_test_square(SD59x18 x) public {
        require(x.gt(ONE_FP));

        SD59x18 square_x = x.mul(x);
        SD59x18 sqrt_square_x = sqrt(square_x);

        uint256 loss = significant_digits_lost_in_mult(x, x);

        assertEqWithinDecimalPrecision(sqrt_square_x, x, loss);
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */


    // Test for zero case
    function sqrt_test_zero() public {
        assertEq(sqrt(ZERO_FP), ZERO_FP);
    }

    // Test for maximum value
    function sqrt_test_maximum() public {
        try this.helpersSqrt(MAX_SQRT) {
            // Expected behaviour, MAX_SQRT is positive, and operation
            // should not revert as the result is in range
        } catch {
            // Unexpected, should not revert
            assert(false);
        }
    }

    // Test for minimum value
    function sqrt_test_minimum() public {
        try this.helpersSqrt(MIN_SD59x18) {
            // Unexpected, should revert. MIN_SD59x18 is negative.
            assert(false);
        } catch {
            // Expected behaviour, revert
        }
    }

    // Test for negative operands
    function sqrt_test_negative(SD59x18 x) public {
        require(x.lt(ZERO_FP));

        try this.helpersSqrt(x) {
            // Unexpected, should revert
            assert(false);
        } catch {
            // Expected behaviour, revert
        }
    }

    /* ================================================================

                        TESTS FOR FUNCTION log2()

       ================================================================ */

    /* ================================================================
       Tests for arithmetic properties.
       These should make sure that the implemented function complies
       with math rules and expected behaviour.
       ================================================================ */

    // Test for distributive property respect to multiplication
    // log2(x * y) = log2(x) + log2(y)
    function log2_test_distributive_mul(SD59x18 x, SD59x18 y) public {
        require(x.gt(ZERO_FP) && y.gt(ZERO_FP));
        SD59x18 log2_x = log2(x);
        SD59x18 log2_y = log2(y);
        SD59x18 log2_x_log2_y = add(log2_x, log2_y);

        SD59x18 xy = mul(x, y);
        SD59x18 log2_xy = log2(xy);

        // Ensure we have enough significant digits for the result to be meaningful
        require(significant_digits_after_mult(x, y) > REQUIRED_SIGNIFICANT_DIGITS);

        // The maximum loss of precision is given by the formula:
        // | log10(x) + log10(y) |
        uint256 loss = significant_digits_lost_in_mult(x, y) + 2;

        assertEqWithinDecimalPrecision(log2_x_log2_y, log2_xy, loss);
    }

    // Test for logarithm of a power
    // log2(x ** y) = y * log2(x)
    function log2_test_power(SD59x18 x, SD59x18 y) public {
        require(x.gt(ZERO_FP));
        SD59x18 x_y = pow(x, y);
        require(x_y.gt(ZERO_FP));
        SD59x18 log2_x_y = log2(x_y);
        SD59x18 y_log2_x = mul(log2(x), y);

        assertEqWithinTolerance(y_log2_x, log2_x_y, ONE_FP, "1%");
    }

    // Base 2 logarithm is strictly increasing
    // y > 0 && x > y --> log2(x) > log2(y)
    function log2_test_strictly_increasing(SD59x18 x, SD59x18 y) public {
        require(y.gt(ZERO_FP) && x.gt(y));
        
        SD59x18 log2_x = log2(x);
        SD59x18 log2_y = log2(y);
        
        assertGte(log2_x, log2_y);
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // Test for zero case, should revert
    function log2_test_zero() public {
        try this.helpersLog2(ZERO_FP) {
            // Unexpected, should revert
            assert(false);
        } catch {
            // Expected revert, log(0) is not defined
        }
    }

    // Test for maximum value case, should return a positive number
    function log2_test_maximum() public {
        SD59x18 result;

        try this.helpersLog2(MAX_SD59x18) {
            // Expected, should not revert and the result must be > 0
            result = this.helpersLog2(MAX_SD59x18);
            assertGt(result, ZERO_FP);
        } catch {
            // Unexpected
            assert(false);
        }
    }

    // Test for negative values, should revert as log2 is not defined
    function log2_test_negative(SD59x18 x) public {
        require(x.lt(ZERO_FP));

        try this.helpersLog2(x) {
            // Unexpected, should revert
            assert(false);
        } catch {
            // Expected
        }
    }

    /* ================================================================

                        TESTS FOR FUNCTION ln()

       ================================================================ */

    /* ================================================================
       Tests for arithmetic properties.
       These should make sure that the implemented function complies
       with math rules and expected behaviour.
       ================================================================ */

    // Test for distributive property respect to multiplication
    // ln(x * y) = ln(x) + ln(y)
    function ln_test_distributive_mul(SD59x18 x, SD59x18 y) public {
        require(x.gt(ZERO_FP) && y.gt(ZERO_FP));

        SD59x18 ln_x = ln(x);
        SD59x18 ln_y = ln(y);
        SD59x18 ln_x_ln_y = add(ln_x, ln_y);

        SD59x18 xy = mul(x, y);
        SD59x18 ln_xy = ln(xy);

        require(significant_digits_after_mult(x, y) > REQUIRED_SIGNIFICANT_DIGITS);

        // The maximum loss of precision is given by the formula:
        // | log2(x) + log2(y) |
        uint256 loss = significant_digits_lost_in_mult(x, y) + 2;

        assertEqWithinDecimalPrecision(ln_x_ln_y, ln_xy, loss);
    }

    // Test for logarithm of a power
    // ln(x ** y) = y * ln(x)
    function ln_test_power(SD59x18 x, SD59x18 y) public {
        require(x.gt(ZERO_FP));
        SD59x18 x_y = pow(x, y);
        SD59x18 ln_x_y = ln(x_y);

        SD59x18 y_ln_x = mul(ln(x), y);

        require(significant_digits_after_mult(ln(x), y) > REQUIRED_SIGNIFICANT_DIGITS);

        assertEqWithinTolerance(ln_x_y, y_ln_x, ONE_FP, "1%");
    }

    // Natural logarithm is strictly increasing
    // y > 0 && x > y --> log2(x) > log2(y)
    function ln_test_strictly_increasing(SD59x18 x, SD59x18 y) public {
        require(y.gt(ZERO_FP) && x.gt(y));
        
        SD59x18 log2_x = ln(x);
        SD59x18 log2_y = ln(y);

        assertGte(log2_x, log2_y);
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // Test for zero case, should revert
    function ln_test_zero() public {
        try this.helpersLn(ZERO_FP) {
            // Unexpected, should revert
            assert(false);
        } catch {
            // Expected revert, log(0) is not defined
        }
    }

    // Test for maximum value case, should return a positive number
    function ln_test_maximum() public {
        SD59x18 result;

        try this.helpersLn(MAX_SD59x18) {
            // Expected, should not revert and the result must be > 0
            result = this.helpersLn(MAX_SD59x18);
            assertGt(result, ZERO_FP);
        } catch {
            // Unexpected
            assert(false);
        }
    }

    // Test for negative values, should revert as ln is not defined
    function ln_test_negative(SD59x18 x) public {
        require(x.lt(ZERO_FP));

        try this.helpersLn(x) {
            // Unexpected, should revert
            assert(false);
        } catch {
            // Expected
        }
    }

    /* ================================================================

                        TESTS FOR FUNCTION exp2()

       ================================================================ */

    /* ================================================================
       Tests for arithmetic properties.
       These should make sure that the implemented function complies
       with math rules and expected behaviour.
       ================================================================ */

    // Test for equality with pow(2, x) for integer x
    // pow(2, x) == exp2(x)
    function exp2_test_equivalence_pow(SD59x18 x) public {
        require(x.lte(MAX_PERMITTED_EXP2));
        SD59x18 exp2_x = exp2(x);
        SD59x18 pow_2_x = pow(TWO_FP, x);

        assertEq(exp2_x, pow_2_x);
    }

    // Test for inverse function
    // If y = log2(x) then exp2(y) == x
    function exp2_test_inverse(SD59x18 x) public {
        require(x.lte(MAX_PERMITTED_EXP2) && x.gt(ZERO_FP));
        SD59x18 log2_x = log2(x);
        SD59x18 exp2_x = exp2(log2_x);

        assertEqWithinDecimalPrecision(x, exp2_x, 9);
    }

    // Test for negative exponent
    // exp2(-x) == inv( exp2(x) )
    function exp2_test_negative_exponent(SD59x18 x) public {
        require(x.lt(ZERO_FP) && x.neq(MIN_SD59x18));

        SD59x18 exp2_x = exp2(x);
        SD59x18 exp2_minus_x = exp2(neg(x));

        assertEqWithinDecimalPrecision(exp2_x, inv(exp2_minus_x), 2);
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // Test for zero case
    // exp2(0) == 1
    function exp2_test_zero() public {
        SD59x18 exp_zero = exp2(ZERO_FP);
        assertEq(exp_zero, ONE_FP);
    }

    // Test for maximum value. This should overflow as it won't fit
    // in the data type
    function exp2_test_maximum() public {
        try this.helpersExp2(MAX_SD59x18) {
            // Unexpected, should revert
            assert(false);
        } catch {
            // Expected revert
        }
    }

        // Test for maximum value. This should overflow as it won't fit
    // in the data type
    function exp2_test_maximum_permitted() public {
        try this.helpersExp2(MAX_PERMITTED_EXP2) {
            // Should always pass
        } catch {
            // Should never revert
            assert(false);
        }
    }

    // Test for minimum value. This should return zero since
    // 2 ** -x == 1 / 2 ** x that tends to zero as x increases
    function exp2_test_minimum() public {
        SD59x18 result;

        try this.helpersExp2(MIN_SD59x18) {
            // Expected, should not revert, check that value is zero
            result = exp2(MIN_SD59x18);
            assertEq(result, ZERO_FP);
        } catch {
            // Unexpected revert
            assert(false);
        }
    }

    /* ================================================================

                        TESTS FOR FUNCTION exp()

       ================================================================ */

    /* ================================================================
       Tests for arithmetic properties.
       These should make sure that the implemented function complies
       with math rules and expected behaviour.
       ================================================================ */

    // Test for inverse function
    // If y = ln(x) then exp(y) == x
    function exp_test_inverse(SD59x18 x) public {
        require(x.lte(MAX_PERMITTED_EXP));
        SD59x18 ln_x = ln(x);
        SD59x18 exp_x = exp(ln_x);
        SD59x18 log10_x = log10(x);

        assertEqWithinDecimalPrecision(x, exp_x, 9);
    }

    // Test for negative exponent
    // exp(-x) == inv( exp(x) )
    function exp_test_negative_exponent(SD59x18 x) public {
        require(x.lt(ZERO_FP) && x.neq(MIN_SD59x18));

        SD59x18 exp_x = exp(x);
        SD59x18 exp_minus_x = exp(neg(x));

        // Result should be within 4 bits precision for the worst case
        assertEqWithinBitPrecision(exp_x, inv(exp_minus_x), 4);
    }

    // Test that exp strictly increases
    function exp_test_strictly_increasing(SD59x18 x, SD59x18 y) public {
        require(x.lte(MAX_PERMITTED_EXP));
        require(y.gt(x) && y.lte(MAX_PERMITTED_EXP));

        SD59x18 exp_x = exp(x);
        SD59x18 exp_y = exp(y);

        assertGte(exp_y, exp_x);
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // Test for zero case
    // exp(0) == 1
    function exp_test_zero() public {
        SD59x18 exp_zero = exp(ZERO_FP);
        assertEq(exp_zero, ONE_FP);
    }

    // Test for maximum value. This should overflow as it won't fit
    // in the data type
    function exp_test_maximum() public {
        try this.helpersExp(MAX_SD59x18) {
            // Unexpected, should revert
            assert(false);
        } catch {
            // Expected revert
        }
    }

    // Test for maximum value. This should overflow as it won't fit
    // in the data type
    function exp_test_maximum_permitted() public {
        try this.helpersExp(MAX_PERMITTED_EXP) {
            // Expected to always succeed
        } catch {
            // Unexpected, should revert
            assert(false);
        }
    }

    // Test for minimum value. This should return zero since
    // e ** -x == 1 / e ** x that tends to zero as x increases
    function exp_test_minimum() public {
        SD59x18 result;

        try this.helpersExp(MIN_SD59x18) {
            // Expected, should not revert, check that value is zero
            result = exp(MIN_SD59x18);
            assertEq(result, ZERO_FP);
        } catch {
            // Unexpected revert
            assert(false);
        }
    }

    /* ================================================================

                        TESTS FOR FUNCTION powu()

       ================================================================ */

    /* ================================================================
       Tests for arithmetic properties.
       These should make sure that the implemented function complies
       with math rules and expected behaviour.
       ================================================================ */

    // Test for zero exponent
    // x ** 0 == 1
    function powu_test_zero_exponent(SD59x18 x) public {
        require(x.gt(MIN_SD59x18));
        require(x.lte(MAX_SD59x18));
        SD59x18 x_pow_0 = powu(x, 0);

        assertEq(x_pow_0, ONE_FP);
    }

    // Test for zero base
    // 0 ** y == 0 (for positive y)
    function powu_test_zero_base(uint256 y) public {
        require(y != 0);

        SD59x18 zero_pow_y = powu(ZERO_FP, y);

        assertEq(zero_pow_y, ZERO_FP);
    }

    // Test for exponent one
    // x ** 1 == x
    function powu_test_one_exponent(SD59x18 x) public {
        require(x.gt(MIN_SD59x18));
        require(x.lte(MAX_SD59x18));
        SD59x18 x_pow_1 = powu(x, 1);

        assertEq(x_pow_1, x);
    }

    // Test for base one
    // 1 ** x == 1
    function powu_test_base_one(uint256 y) public {
        SD59x18 one_pow_y = powu(ONE_FP, y);

        assertEq(one_pow_y, ONE_FP);
    }

    // Test for product of powers of the same base
    // x ** a * x ** b == x ** (a + b)
    function powu_test_product_same_base(
        SD59x18 x,
        uint256 a,
        uint256 b
    ) public {
        require(x.gt(MIN_SD59x18));
        require(x.lte(MAX_SD59x18));

        SD59x18 x_a = powu(x, a);
        SD59x18 x_b = powu(x, b);
        SD59x18 x_ab = powu(x, a + b);

        assertEqWithinDecimalPrecision(mul(x_a, x_b), x_ab, 10);
    }

    // Test for power of an exponentiation
    // (x ** a) ** b == x ** (a * b)
    function powu_test_power_of_an_exponentiation(
        SD59x18 x,
        uint256 a,
        uint256 b
    ) public {
        require(x.gt(MIN_SD59x18));
        require(x.lte(MAX_SD59x18));

        SD59x18 x_a = powu(x, a);
        SD59x18 x_a_b = powu(x_a, b);
        SD59x18 x_ab = powu(x, a * b);

        assertEqWithinDecimalPrecision(x_a_b, x_ab, 10);
    }

    // Test for power of a product
    // (x * y) ** a == x ** a * y ** a
    function powu_test_product_power(
        SD59x18 x,
        SD59x18 y,
        uint256 a
    ) public {
        require(x.gt(MIN_SD59x18) && y.gt(MIN_SD59x18));
        require(x.lte(MAX_SD59x18) && y.lte(MAX_SD59x18));

        require(a > 2 ** 32); // to avoid massive loss of precision

        SD59x18 x_y = mul(x, y);
        SD59x18 xy_a = powu(x_y, a);

        SD59x18 x_a = powu(x, a);
        SD59x18 y_a = powu(y, a);

        assertEqWithinDecimalPrecision(mul(x_a, y_a), xy_a, 10);
    }

    // Test for result being greater than or lower than the argument, depending on
    // its absolute value and the value of the exponent
    function powu_test_values(SD59x18 x, uint256 a) public {
        require(x.neq(ZERO_FP));
        require(x.neq(MIN_SD59x18));

        SD59x18 x_a = powu(x, a);

        if (abs(x).gte(ONE_FP)) {
            assertGte(abs(x_a), ONE_FP);
        }

        if (abs(x).lte(ONE_FP)) {
            assertLte(abs(x_a), ONE_FP);
        }
    }

    // Test for result sign: if the exponent is even, sign is positive
    // if the exponent is odd, preserves the sign of the base
    function powu_test_sign(SD59x18 x, uint256 a) public {
        require(x.neq(ZERO_FP) && a != 0);

        SD59x18 x_a = powu(x, a);

        // This prevents the case where a small negative number gets
        // rounded down to zero and thus changes sign
        require(x_a.neq(ZERO_FP));

        // If the exponent is even
        if (a % 2 == 0) {
            assertEq(x_a, abs(x_a));
        } else {
            // x_a preserves x sign
            if (x.lt(ZERO_FP)) {
                assertLt(x_a, ZERO_FP);
            } else {
                assertGt(x_a, ZERO_FP);
            }
        }
    }

    // Unsigned power is strictly increasing
    // y > MIN && x > y && a > 0 && y != 0 --> powu(x, a) >= powu(y, a)
    function powu_test_strictly_increasing(
        SD59x18 x,
        SD59x18 y,
        uint256 a
    ) public {
        require(x.gt(y) && y.gt(MIN_SD59x18) && y.neq(ZERO_FP));
        require(x.lte(MAX_SD59x18));
        require(a > 0);

        SD59x18 x_a = powu(x, a);
        SD59x18 y_a = powu(y, a);
        
        assertGte(x_a, y_a);
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // Test for maximum base and exponent > 1
    function powu_test_maximum_base(uint256 a) public {
        require(a > 1);

        try this.helpersPowu(MAX_SD59x18, a) {
            // Unexpected, should revert because of overflow
            assert(false);
        } catch {
            // Expected revert
        }
    }

    // Test for abs(base) < 1 and high exponent
    function powu_test_high_exponent(SD59x18 x, uint256 a) public {
        require(abs(x).lt(ONE_FP) && a > 2 ** 32);

        SD59x18 result = powu(x, a);

        assertEq(result, ZERO_FP);
    }

    /* ================================================================

                        TESTS FOR FUNCTION log10()

       ================================================================ */

    /* ================================================================
       Tests for arithmetic properties.
       These should make sure that the implemented function complies
       with math rules and expected behaviour.
       ================================================================ */

    // Test for distributive property respect to multiplication
    // log10(x * y) = log10(x) + log10(y)
    function log10_test_distributive_mul(SD59x18 x, SD59x18 y) public {
        require(x.gt(ZERO_FP) && y.gt(ZERO_FP));
        SD59x18 log10_x = log10(x);
        SD59x18 log10_y = log10(y);
        SD59x18 log10_x_log10_y = add(log10_x, log10_y);

        SD59x18 xy = mul(x, y);
        SD59x18 log10_xy = log10(xy);

        // Ensure we have enough significant digits for the result to be meaningful
        require(significant_digits_after_mult(x, y) > REQUIRED_SIGNIFICANT_DIGITS);

        assertEqWithinTolerance(log10_x_log10_y, log10_xy, ONE_FP, "1%");
    }

    // Test for logarithm of a power
    // log10(x ** y) = y * log10(x)
    function log10_test_power(SD59x18 x, SD59x18 y) public {
        require(x.gt(ZERO_FP) && y.gt(ZERO_FP));
        SD59x18 x_y = pow(x, y);
        SD59x18 log10_x_y = log10(x_y);
        SD59x18 y_log10_x = mul(log10(x), y);
 
        assertEqWithinTolerance(log10_x_y, y_log10_x, ONE_FP, "1%");
    }

    // Base 10 logarithm is strictly increasing
    // x > y && y > 0 --> log10(x) > log10(y)
    function log10_is_increasing(SD59x18 x, SD59x18 y) public {
        require(y.gt(ZERO_FP) && x.gt(y));
        
        SD59x18 log2_x = log10(x);
        SD59x18 log2_y = log10(y);

        assertGt(log2_x, log2_y);
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // Test for zero case, should revert
    function log10_test_zero() public {
        try this.helpersLog10(ZERO_FP) {
            // Unexpected, should revert
            assert(false);
        } catch {
            // Expected revert, log(0) is not defined
        }
    }

    // Test for maximum value case, should return a positive number
    function log10_test_maximum() public {
        SD59x18 result;

        try this.helpersLog10(MAX_SD59x18) {
            // Expected, should not revert and the result must be > 0
            result = this.helpersLog10(MAX_SD59x18);
            assertGt(result, ZERO_FP);
        } catch {
            // Unexpected
            assert(false);
        }
    }

    // Test for negative values, should revert as log10 is not defined
    function log10_test_negative(SD59x18 x) public {
        require(x.lt(ZERO_FP));

        try this.helpersLog10(x) {
            // Unexpected, should revert
            assert(false);
        } catch {
            // Expected
        }
    }

    /* ================================================================

                        TESTS FOR FUNCTION gm()

       ================================================================ */

    /* ================================================================
       Tests for arithmetic properties.
       These should make sure that the implemented function complies
       with math rules and expected behaviour.
       ================================================================ */

    // The product of the values should be equal to the geometric mean
    // raised to the power of N (numbers in the set)
    function gm_test_product(SD59x18 x, SD59x18 y) public {
        bool x_sign = x.gt(ZERO_FP);
        bool y_sign = y.gt(ZERO_FP);
        require(x_sign = y_sign);

        SD59x18 x_mul_y = x.mul(y);
        SD59x18 gm_squared = pow(gm(x,y), TWO_FP);

        assertEqWithinTolerance(x_mul_y, gm_squared, ONE_TENTH_FP, "0.1%");
    }

    // The geometric mean for a set of positive numbers is less than the
    // arithmetic mean of that set, as long as the values of the set are not equal
    function gm_test_positive_set_avg(SD59x18 x, SD59x18 y) public {
        require(x.gte(ZERO_FP) && y.gte(ZERO_FP) && x.neq(y));

        SD59x18 gm_x_y = gm(x, y);
        SD59x18 avg_x_y = avg(x, y);

        assertLte(gm_x_y, avg_x_y);
    }

    // The geometric mean of a set of positive equal numbers should be
    // equal to the arithmetic mean
    function gm_test_positive_equal_set_avg(SD59x18 x) public {
        require(x.gte(ZERO_FP));

        SD59x18 gm_x = gm(x, x);
        SD59x18 avg_x = avg(x, x);

        assertEq(gm_x, avg_x);
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // Test for zero case, should return 0
    function gm_test_zero(SD59x18 x) public {
        require(x.gte(ZERO_FP));

        try this.helpersGm(x, ZERO_FP) {
            SD59x18 result = gm(x, ZERO_FP);
            assertEq(result, ZERO_FP);
        } catch {
            // Unexpected, should not revert
            assert(false);
        }
    }

    // Test for single negative input
    function gm_test_negative(SD59x18 x, SD59x18 y) public {
        require(x.gt(ZERO_FP) && y.lt(ZERO_FP));

        try this.helpersGm(x, y) {
            // Unexpected, should revert
            assert(false);
        } catch {
            // Expected revert, gm of a negative product is not defined
        }
    }

}