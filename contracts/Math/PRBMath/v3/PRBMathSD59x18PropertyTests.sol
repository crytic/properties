pragma solidity ^0.8.19;

import { SD59x18 } from "@prb/math/src/SD59x18.sol";
import {add, sub, eq, gt, gte, lt, lte, lshift, rshift} from "@prb/math/src/sd59x18/Helpers.sol";
import {convert} from "@prb/math/src/sd59x18/Conversions.sol";
import {msb} from "@prb/math/src/Common.sol";
import {intoUint128, intoUint256} from "@prb/math/src/sd59x18/Casting.sol";
import {mul, div, abs, ln, exp, exp2, log2, sqrt, pow, avg, inv, log10, floor} from "@prb/math/src/sd59x18/Math.sol";

contract CryticPRBMath59x18Propertiesv3 {

    event AssertionFailed(SD59x18 result);
    event AssertionFailed(SD59x18 result1, SD59x18 result2);

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
    SD59x18 internal ONE_TENTH_FP = convert(1);

    /* ================================================================
       Constants used for precision loss calculations
       ================================================================ */
    uint256 internal REQUIRED_SIGNIFICANT_BITS = 10;

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
    event Value(string reason, int256 val);
    event LogErr(bytes error);


    /* ================================================================
       Helper functions.
       ================================================================ */

    // These functions allows to compare a and b for equality, discarding
    // the last precision_bits bits.
    // Uses functions from the library under test!
    function equal_within_precision(SD59x18 a, SD59x18 b, uint256 precision_bits) public pure returns(bool) {
        SD59x18 max = gt(a , b) ? a : b;
        SD59x18 min = gt(a , b) ? b : a;
        SD59x18 r = rshift(sub(max, min), precision_bits);
        
        return (eq(r, convert(0)));
    }

    function equal_within_precision_u(uint256 a, uint256 b, uint256 precision_bits) public pure returns(bool) {
        uint256 max = (a > b) ? a : b;
        uint256 min = (a > b) ? b : a;
        uint256 r = (max - min) >> precision_bits;
        
        return (r == 0);
    }

    // This function determines if the relative error between a and b is less
    // than error_percent % (expressed as a 59x18 value)
    // Uses functions from the library under test!
    function equal_within_tolerance(SD59x18 a, SD59x18 b, SD59x18 error_percent) public pure returns(bool) {
        SD59x18 tol_value = abs(mul(a, div(error_percent, convert(100))));

        return (lte(abs(sub(b, a)), tol_value));
    }

    // Check that there are remaining significant digits after a multiplication
    // Uses functions from the library under test!
    function significant_digits_lost_in_mult(SD59x18 a, SD59x18 b) public pure returns (bool) {
        int256 la = convert(floor(log10(abs(a))));
        int256 lb = convert(floor(log10(abs(b))));

        return(la + lb < -18);
    }

    // Return how many significant bits will remain after multiplying a and b
    // Uses functions from the library under test!
    function significant_digits_after_mult(SD59x18 a, SD59x18 b) public pure returns (uint256) {
        int256 la = convert(floor(log10(abs(a))));
        int256 lb = convert(floor(log10(abs(b))));
        int256 prec = la + lb;

        if (prec < -18) return 0;
        else return(18 + uint256(prec));
    }

    // Returns true if the n most significant bits of a and b are almost equal 
    // Uses functions from the library under test!
    function equal_most_significant_digits_within_precision(SD59x18 a, SD59x18 b, uint256 bits) public view returns (bool) {
        // Get the number of bits in a and b
        // Since log(x) returns in the interval [-64, 63), add 64 to be in the interval [0, 127)
        uint256 a_bits = uint256(int256(convert(log2(a)) + 64));
        uint256 b_bits = uint256(int256(convert(log2(b)) + 64));

        // a and b lengths may differ in 1 bit, so the shift should take into account the longest
        uint256 shift_bits = (a_bits > b_bits) ? (a_bits - bits) : (b_bits - bits);

        // Get the _bits_ most significant bits of a and b
        uint256 a_msb = most_significant_bits(a, bits) >> shift_bits;
        uint256 b_msb = most_significant_bits(b, bits) >> shift_bits;

        // See if they are equal within 1 bit precision
        // This could be modified to get the precision as a parameter to the function
        return equal_within_precision_u(a_msb, b_msb, 1);
    }

    // Return the i most significant bits from |n|. If n has less than i significant bits, return |n|
    // Uses functions from the library under test!
    function most_significant_bits(
        SD59x18 n,
        uint256 i
    ) public view returns (uint256) {
        if (n.eq(MIN_SD59x18)) return 0;
        
        // Create a mask consisting of i bits set to 1
        uint256 mask = (2 ** i) - 1;

        // Get the positive value of n
        uint256 value = (n.gt(ZERO_FP)) ? intoUint256(n) : intoUint256(neg(n));

        // Get the position of the MSB set to 1 of n
        uint256 pos = msb(value);

        // Shift the mask to match the rightmost 1-set bit
        if (pos > i) {
            mask <<= (pos - i);
        }

        return (value & mask);
    }

    /* function compute_max_log_error(SD59x18 x) public view returns (SD59x18 result) {
        int256 xInt = SD59x18.unwrap(x);

        unchecked {
        // This works because of:
        //
        // $$
        // log_2{x} = -log_2{\frac{1}{x}}
        // $$
        int256 sign;
        if (xInt >= uUNIT) {
            sign = 1;
        } else {
            sign = -1;
            // Do the fixed-point inversion inline to save gas. The numerator is UNIT * UNIT.
            xInt = 1e36 / xInt;
        }

        // Calculate the integer part of the logarithm and add it to the result and finally calculate $y = x * 2^(-n)$.
        uint256 n = msb(uint256(xInt / uUNIT));

        // This is $y = x * 2^{-n}$.
        int256 y = xInt >> n;

        // If y is 1, the fractional part is zero.
        if (y == uUNIT) {
            return 0;
        }

        // Calculate the fractional part via the iterative approximation.
        // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
        int256 DOUBLE_UNIT = 2e18;
        int256 sum;
        for (int256 delta = uHALF_UNIT; delta > 0; delta >>= 1) {
            y = (y * y) / uUNIT;

            // Is $y^2 > 2$ and so in the range [2,4)?
            if (y >= DOUBLE_UNIT) {
                // Add the 2^{-m} factor to the logarithm.
                sum += delta;

                // Corresponds to z/2 on Wikipedia.
                y >>= 1;
            }
        }

        int256 maxError = 2 ** (-sum);
        result = convert(maxError);
    }
    } */

    /* ================================================================
       Library wrappers.
       These functions allow calling the PRBMathSD59x18 library.
       ================================================================ */
    function debug(string calldata x, int256 y) public {
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
    function add_test_commutative(SD59x18 x, SD59x18 y) public pure {
        SD59x18 x_y = x.add(y);
        SD59x18 y_x = y.add(x);

        assert(x_y.eq(y_x));
    }

    // Test for associative property
    // (x + y) + z == x + (y + z)
    function add_test_associative(SD59x18 x, SD59x18 y, SD59x18 z) public pure {
        SD59x18 x_y = x.add(y);
        SD59x18 y_z = y.add(z);
        SD59x18 xy_z = x_y.add(z);
        SD59x18 x_yz = x.add(y_z);

        assert(xy_z.eq(x_yz));
    }

    // Test for identity operation
    // x + 0 == x (equivalent to x + (-x) == 0)
    function add_test_identity(SD59x18 x) public view {
        SD59x18 x_0 = x.add(ZERO_FP);

        assert(x.eq(x_0));
        assert(x.sub(x).eq(ZERO_FP));
    }

    // Test that the result increases or decreases depending
    // on the value to be added
    function add_test_values(SD59x18 x, SD59x18 y) public view {
        SD59x18 x_y = x.add(y);

        if (y.gte(ZERO_FP)) {
            assert(x_y.gte(x));
        } else {
            assert(x_y.lt(x));
        }
    }


    /* ================================================================
       Tests for overflow and edge cases.
       These should make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // The result of the addition must be between the maximum
    // and minimum allowed values for SD59x18
    function add_test_range(SD59x18 x, SD59x18 y) public view {
        try this.helpersAdd(x, y) returns (SD59x18 result) {
            assert(result.lte(MAX_SD59x18) && result.gte(MIN_SD59x18));
        } catch {
            // If it reverts, just ignore
        }
    }

    // Adding zero to the maximum value shouldn't revert, as it is valid
    // Moreover, the result must be MAX_SD59x18
    function add_test_maximum_value() public view {
        try this.helpersAdd(MAX_SD59x18, ZERO_FP) returns (SD59x18 result) {
            // Expected behaviour, does not revert
            assert(result.eq(MAX_SD59x18));
        } catch {
            assert(false);
        }
    }

    // Adding one to the maximum value should revert, as it is out of range
    function add_test_maximum_value_plus_one() public view {
        try this.helpersAdd(MAX_SD59x18, ONE_FP) {
            assert(false);
        } catch {
            // Expected behaviour, reverts
        }
    }

    // Adding zero to the minimum value shouldn't revert, as it is valid
    // Moreover, the result must be MIN_SD59x18
    function add_test_minimum_value() public view {
        try this.helpersAdd(MIN_SD59x18, ZERO_FP) returns (SD59x18 result) {
            // Expected behaviour, does not revert
            assert(result.eq(MIN_SD59x18));
        } catch {
            assert(false);
        }
    }

    // Adding minus one to the maximum value should revert, as it is out of range
    function add_test_minimum_value_plus_negative_one() public view {
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
    function sub_test_equivalence_to_addition(SD59x18 x, SD59x18 y) public pure {
        SD59x18 minus_y = neg(y);
        SD59x18 addition = x.add(minus_y);
        SD59x18 subtraction = x.sub(y);

        assert(addition.eq(subtraction));
    }

    // Test for non-commutative property
    // x - y == -(y - x)
    function sub_test_non_commutative(SD59x18 x, SD59x18 y) public pure {
        SD59x18 x_y = x.sub(y);
        SD59x18 y_x = y.sub(x);
        
        assert(x_y.eq(neg(y_x)));
    }

    // Test for identity operation
    // x - 0 == x  (equivalent to x - x == 0)
    function sub_test_identity(SD59x18 x) public view {
        SD59x18 x_0 = x.sub(ZERO_FP);

        assert(x_0.eq(x));
        assert(x.sub(x).eq(ZERO_FP));
    }

    // Test for neutrality over addition and subtraction
    // (x - y) + y == (x + y) - y == x
    function sub_test_neutrality(SD59x18 x, SD59x18 y) public pure {
        SD59x18 x_minus_y = x.sub(y);
        SD59x18 x_plus_y = x.add(y);

        SD59x18 x_minus_y_plus_y = x_minus_y.add(y);
        SD59x18 x_plus_y_minus_y = x_plus_y.sub(y);
        
        assert(x_minus_y_plus_y.eq(x_plus_y_minus_y));
        assert(x_minus_y_plus_y.eq(x));
    }

    // Test that the result increases or decreases depending
    // on the value to be subtracted
    function sub_test_values(SD59x18 x, SD59x18 y) public view {
        SD59x18 x_y = x.sub(y);

        if (y.gte(ZERO_FP)) {
            assert(x_y.lte(x));
        } else {
            assert(x_y.gt(x));
        }
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // The result of the subtraction must be between the maximum
    // and minimum allowed values for SD59x18
    function sub_test_range(SD59x18 x, SD59x18 y) public view {
        try this.helpersSub(x, y) returns (SD59x18 result) {
            assert(result.lte(MAX_SD59x18) && result.gte(MIN_SD59x18));
        } catch {
            // If it reverts, just ignore
        }
    }

    // Subtracting zero from the maximum value shouldn't revert, as it is valid
    // Moreover, the result must be MAX_SD59x18
    function sub_test_maximum_value() public view {
        try this.helpersSub(MAX_SD59x18, ZERO_FP) returns (SD59x18 result) {
            // Expected behaviour, does not revert
            assert(result.eq(MAX_SD59x18));
        } catch {
            assert(false);
        }
    }

    // Subtracting minus one from the maximum value should revert, 
    // as it is out of range
    function sub_test_maximum_value_minus_neg_one() public view {
        try this.helpersSub(MAX_SD59x18, MINUS_ONE_FP) {
            assert(false);
        } catch {
            // Expected behaviour, reverts
        }
    }

    // Subtracting zero from the minimum value shouldn't revert, as it is valid
    // Moreover, the result must be MIN_SD59x18
    function sub_test_minimum_value() public view {
        try this.helpersSub(MIN_SD59x18, ZERO_FP) returns (SD59x18 result) {
            // Expected behaviour, does not revert
            assert(result.eq(MIN_SD59x18));
        } catch {
            assert(false);
        }
    }

    // Subtracting one from the minimum value should revert, as it is out of range
    function sub_test_minimum_value_minus_one() public view {
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
    function mul_test_commutative(SD59x18 x, SD59x18 y) public pure {
        SD59x18 x_y = x.mul(y);
        SD59x18 y_x = y.mul(x);

        assert(x_y.eq(y_x));
    }

    // Test for associative property
    // (x * y) * z == x * (y * z)
    function mul_test_associative(SD59x18 x, SD59x18 y, SD59x18 z) public view {
        SD59x18 x_y = x.mul(y);
        SD59x18 y_z = y.mul(z);
        SD59x18 xy_z = x_y.mul(z);
        SD59x18 x_yz = x.mul(y_z);

        // todo check if this should not be used
        // Failure if all significant digits are lost
        /*require(significant_bits_after_mult(x, y) > REQUIRED_SIGNIFICANT_BITS);
        require(significant_bits_after_mult(y, z) > REQUIRED_SIGNIFICANT_BITS);
        require(significant_bits_after_mult(x_y, z) > REQUIRED_SIGNIFICANT_BITS);
        require(significant_bits_after_mult(x, y_z) > REQUIRED_SIGNIFICANT_BITS);*/

        //assert(equal_within_tolerance(xy_z, x_yz, ONE_TENTH_FP));
        assert(xy_z.eq(x_yz));
    }

    // Test for distributive property
    // x * (y + z) == x * y + x * z
    function mul_test_distributive(SD59x18 x, SD59x18 y, SD59x18 z) public view {
        SD59x18 y_plus_z = y.add(z);
        SD59x18 x_times_y_plus_z = x.mul(y_plus_z);

        SD59x18 x_times_y = x.mul(y);
        SD59x18 x_times_z = x.mul(z);

        // todo check if this should not be used
        // Failure if all significant digits are lost
        /*require(significant_bits_after_mult(x, y) > REQUIRED_SIGNIFICANT_BITS);
        require(significant_bits_after_mult(x, z) > REQUIRED_SIGNIFICANT_BITS);
        require(significant_bits_after_mult(x, y_plus_z) > REQUIRED_SIGNIFICANT_BITS);

        assert(equal_within_tolerance(add(x_times_y, x_times_z), x_times_y_plus_z, ONE_TENTH_FP));*/
        assert(x_times_y.add(x_times_z).eq(x_times_y_plus_z));
    }

    // Test for identity operation
    // x * 1 == x  (also check that x * 0 == 0)
    function mul_test_identity(SD59x18 x) public view {
        SD59x18 x_1 = x.mul(ONE_FP);
        SD59x18 x_0 = x.mul(ZERO_FP);

        assert(x_0.eq(ZERO_FP));
        assert(x_1.eq(x));
    }

    // Test that the result increases or decreases depending
    // on the value to be added
    function mul_test_values(SD59x18 x, SD59x18 y) public view {
        require(x.neq(ZERO_FP) && y.neq(ZERO_FP));

        SD59x18 x_y = x.mul(y);

        //require(significant_digits_lost_in_mult(x, y) == false);

        if (x.gte(ZERO_FP)) {
            if (y.gte(ONE_FP)) {
                assert(x_y.gte(x));
            } else {
                assert(x_y.lte(x));
            }
        } else {
            if (y.gte(ONE_FP)) {
                assert(x_y.lte(x));
            } else {
                assert(x_y.gte(x));
            }
        }
    }
    

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // The result of the multiplication must be between the maximum
    // and minimum allowed values for SD59x18
    function mul_test_range(SD59x18 x, SD59x18 y) public view {
        try this.helpersMul(x, y) returns(SD59x18 result) {
            assert(result.lte(MAX_SD59x18) && result.gte(MIN_SD59x18));
        } catch {
            // If it reverts, just ignore
        }
    }

    // Multiplying the maximum value times one shouldn't revert, as it is valid
    // Moreover, the result must be MAX_SD59x18
    function mul_test_maximum_value() public view {
        try this.helpersMul(MAX_SD59x18, ONE_FP) returns (SD59x18 result) {
            // Expected behaviour, does not revert
            assert(result.eq(MAX_SD59x18));
        } catch {
            assert(false);
        }
    }

    // Multiplying the minimum value times one shouldn't revert, as it is valid
    // Moreover, the result must be MIN_SD59x18
    function mul_test_minimum_value() public view {
        try this.helpersMul(MIN_SD59x18.add(ONE_FP), ONE_FP) returns (SD59x18 result) {
            // Expected behaviour, does not revert
            assert(result.eq(MIN_SD59x18));
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

    /// Requirements:
    /// - Refer to the requirements in {Common.mulDiv}.
    /// - None of the inputs can be `MIN_SD59x18`.
    /// - The denominator must not be zero.
    /// - The result must fit in SD59x18.

    // Test for identity property
    // x / 1 == x (equivalent to x / x == 1)
    // Moreover, x/x should not revert unless x == 0
    function div_test_division_identity(SD59x18 x) public view {
        SD59x18 div_1 = div(x, ONE_FP);
        assert(x.eq(div_1));

        SD59x18 div_x;

        try this.helpersDiv(x, x) {
            // This should always equal one
            div_x = div(x, x);
            assert(div_x.eq(ONE_FP));
        } catch {
            // The only allowed case to revert is if x == 0
            assert(x.eq(ZERO_FP));
        }
    }


    // Test for negative divisor
    // x / -y == -(x / y)
    function div_test_negative_divisor(SD59x18 x, SD59x18 y) public view {
        require(y.lt(ZERO_FP));

        SD59x18 x_y = div(x, y);
        SD59x18 x_minus_y = div(x, neg(y));

        assert(x_y.eq(neg(x_minus_y)));
    }

    // Test for division with 0 as numerator
    // 0 / x = 0
    function div_test_division_num_zero(SD59x18 x) public view {
        require(x.neq(ZERO_FP));

        SD59x18 div_0 = div(ZERO_FP, x);

        assert(ZERO_FP.eq(div_0));
    }

    // Test that the absolute value of the result increases or
    // decreases depending on the denominator's absolute value
    function div_test_values(SD59x18 x, SD59x18 y) public view {
        require(y.neq(ZERO_FP));

        SD59x18 x_y = abs(div(x, y));

        if (abs(y).gte(ONE_FP)) {
            assert(x_y.lte(abs(x)));
        } else {
            assert(x_y.gte(abs(x)));
        }
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // Test for division by zero
    function div_test_div_by_zero(SD59x18 x) public view {
        try this.helpersDiv(x, ZERO_FP) {
            // Unexpected, this should revert
            assert(false);
        } catch {
            // Expected revert
        }
    }

    // Test for division by a large value, the result should be less than one
    function div_test_maximum_denominator(SD59x18 x) public view {
        SD59x18 div_large = div(x, MAX_SD59x18);

        assert(abs(div_large).lte(ONE_FP));
    }

    // Test for division of a large value
    // This should revert if |x| < 1 as it would return a value higher than max
    function div_test_maximum_numerator(SD59x18 x) public view {
        SD59x18 div_large;

        try this.helpersDiv(MAX_SD59x18, x) {
            // If it didn't revert, then |x| >= 1
            div_large = div(MAX_SD59x18, x);

            assert(abs(x).gte(ONE_FP));
        } catch {
            // Expected revert as result is higher than max
        }
    }

    // Test for values in range
    function div_test_range(SD59x18 x, SD59x18 y) public view {
        SD59x18 result;

        try this.helpersDiv(x, y) {
            // If it returns a value, it must be in range
            result = div(x, y);
            assert(result.lte(MAX_SD59x18) && result.gte(MIN_SD59x18));
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
    function neg_test_double_negation(SD59x18 x) public pure {
        SD59x18 double_neg = neg(neg(x));

        assert(x.eq(double_neg));
    }

    // Test for the identity operation
    // x + (-x) == 0
    function neg_test_identity(SD59x18 x) public view {
        SD59x18 neg_x = neg(x);

        assert(add(x, neg_x).eq(ZERO_FP));
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // Test for the zero-case
    // -0 == 0
    function neg_test_zero() public view {
        SD59x18 neg_x = neg(ZERO_FP);

        assert(neg_x.eq(ZERO_FP));
    }

    // todo check what is used for SD59x18
    // Test for the maximum value case
    // Since this is implementation-dependant, we will actually test with MAX_SD59x18-EPS
    function neg_test_maximum() public view {
        try this.neg(sub(MAX_SD59x18, EPSILON)) {
            // Expected behaviour, does not revert
        } catch {
            assert(false);
        }
    }

    // todo check what is used for SD59x18
    // Test for the minimum value case
    // Since this is implementation-dependant, we will actually test with MIN_SD59x18+EPS
    function neg_test_minimum() public view {
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

    /// @dev Requirements:
    /// - x must be greater than `MIN_SD59x18`.

    // Test that the absolute value is always positive
    function abs_test_positive(SD59x18 x) public view {
        SD59x18 abs_x = abs(x);

        assert(abs_x.gte(ZERO_FP));
    }

    // Test that the absolute value of a number equals the
    // absolute value of the negative of the same number
    function abs_test_negative(SD59x18 x) public pure {
        SD59x18 abs_x = abs(x);
        SD59x18 abs_minus_x = abs(neg(x));

        assert(abs_x.eq(abs_minus_x));
    }

    // Test the multiplicativeness property
    // | x * y | == |x| * |y|
    function abs_test_multiplicativeness(SD59x18 x, SD59x18 y) public pure {
        SD59x18 abs_x = abs(x);
        SD59x18 abs_y = abs(y);
        SD59x18 abs_xy = abs(mul(x, y));
        SD59x18 abs_x_abs_y = mul(abs_x, abs_y);

        // Failure if all significant digits are lost
        require(significant_digits_lost_in_mult(abs_x, abs_y) == false);

        // Assume a tolerance of two bits of precision
        assert(equal_within_precision(abs_xy, abs_x_abs_y, 2));
    }

    // Test the subadditivity property
    // | x + y | <= |x| + |y|
    function abs_test_subadditivity(SD59x18 x, SD59x18 y) public pure {
        SD59x18 abs_x = abs(x);
        SD59x18 abs_y = abs(y);
        SD59x18 abs_xy = abs(add(x, y));

        assert(abs_xy.lte(add(abs_x, abs_y)));
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // Test the zero-case | 0 | = 0
    function abs_test_zero() public view {
        SD59x18 abs_zero;

        try this.helpersAbs(ZERO_FP) {
            // If it doesn't revert, the value must be zero
            abs_zero = this.helpersAbs(ZERO_FP);
            assert(abs_zero.eq(ZERO_FP));
        } catch {
            // Unexpected, the function must not revert here
            assert(false);
        }
    }

    // Test the maximum value
    function abs_test_maximum() public view {
        SD59x18 abs_max;

        try this.helpersAbs(MAX_SD59x18) {
            // If it doesn't revert, the value must be MAX_SD59x18
            abs_max = this.helpersAbs(MAX_SD59x18);
            assert(abs_max.eq(MAX_SD59x18));
        } catch {}
    }

    // Test the minimum value
    function abs_test_minimum() public view {
        SD59x18 abs_min;

        try this.helpersAbs(MIN_SD59x18) {
            // If it doesn't revert, the value must be the negative of MIN_SD59x18
            abs_min = this.helpersAbs(MIN_SD59x18);
            assert(abs_min.eq(neg(MIN_SD59x18)));
        } catch {}
    }

    /* ================================================================

                        TESTS FOR FUNCTION inv()

       ================================================================ */

    /* ================================================================
       Tests for mathematical properties.
       These should make sure that the implemented function complies
       with math rules and expected behaviour.
       ================================================================ */

    /// - x must not be zero.

    // Test that the inverse of the inverse is close enough to the
    // original number
    function inv_test_double_inverse(SD59x18 x) public view {
        require(x.neq(ZERO_FP));

        SD59x18 double_inv_x = inv(inv(x));

        // The maximum loss of precision will be 2 * log2(x) bits rounded up
        uint256 loss = 2 * intoUint256(log2(x)) + 2;

        assert(equal_within_precision(x, double_inv_x, loss));
    }

    // Test equivalence with division
    function inv_test_division(SD59x18 x) public view {
        require(x.neq(ZERO_FP));

        SD59x18 inv_x = inv(x);
        SD59x18 div_1_x = div(ONE_FP, x);

        assert(inv_x.eq(div_1_x));
    }

    // Test the anticommutativity of the division
    // x / y == 1 / (y / x)
    function inv_test_division_noncommutativity(
        SD59x18 x,
        SD59x18 y
    ) public view {
        require(x.neq(ZERO_FP) && y.neq(ZERO_FP));

        SD59x18 x_y = div(x, y);
        SD59x18 y_x = div(y, x);

        require(
            significant_digits_after_mult(x, inv(y)) > REQUIRED_SIGNIFICANT_BITS
        );
        require(
            significant_digits_after_mult(y, inv(x)) > REQUIRED_SIGNIFICANT_BITS
        );
        assert(equal_within_tolerance(x_y, inv(y_x), ONE_TENTH_FP));
    }

    // Test the multiplication of inverses
    // 1/(x * y) == 1/x * 1/y
    function inv_test_multiplication(SD59x18 x, SD59x18 y) public view {
        require(x.neq(ZERO_FP) && y.neq(ZERO_FP));

        SD59x18 inv_x = inv(x);
        SD59x18 inv_y = inv(y);
        SD59x18 inv_x_times_inv_y = mul(inv_x, inv_y);

        SD59x18 x_y = mul(x, y);
        SD59x18 inv_x_y = inv(x_y);

        require(significant_digits_after_mult(x, y) > REQUIRED_SIGNIFICANT_BITS);
        require(
            significant_digits_after_mult(inv_x, inv_y) > REQUIRED_SIGNIFICANT_BITS
        );

        // The maximum loss of precision is given by the formula:
        // 2 * | log2(x) - log2(y) | + 1
        uint256 loss = 2 * intoUint256(abs(log2(x).sub(log2(y)))) + 1;

        assert(equal_within_precision(inv_x_y, inv_x_times_inv_y, loss));
    }

    // Test identity property
    // Intermediate result should have at least REQUIRED_SIGNIFICANT_BITS
    function inv_test_identity(SD59x18 x) public view {
        require(x.neq(ZERO_FP));

        SD59x18 inv_x = inv(x);
        SD59x18 identity = mul(inv_x, x);

        require(
            significant_digits_after_mult(x, inv_x) > REQUIRED_SIGNIFICANT_BITS
        );

        // They should agree with a tolerance of one tenth of a percent
        assert(equal_within_tolerance(identity, ONE_FP, ONE_TENTH_FP));
    }

    // Test that the absolute value of the result is in range zero-one
    // if x is greater than one, else, the absolute value of the result
    // must be greater than one
    function inv_test_values(SD59x18 x) public view {
        require(x.neq(ZERO_FP));

        SD59x18 abs_inv_x = abs(inv(x));

        if (abs(x).gte(ONE_FP)) {
            assert(abs_inv_x.lte(ONE_FP));
        } else {
            assert(abs_inv_x.gt(ONE_FP));
        }
    }

    // Test that the result has the same sign as the argument.
    // Since inv() rounds towards zero, we are checking the zero case as well
    function inv_test_sign(SD59x18 x) public {
        require(x.neq(ZERO_FP));

        SD59x18 inv_x = inv(x);

        if (x.gt(ZERO_FP)) {
            assert(inv_x.gte(ZERO_FP));
        } else {
            assert(inv_x.lte(ZERO_FP));
        }
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // Test the zero-case, should revert
    function inv_test_zero() public view {
        try this.helpersInv(ZERO_FP) {
            // Unexpected, the function must revert
            assert(false);
        } catch {}
    }

    // Test the maximum value case, should not revert, and be close to zero
    function inv_test_maximum() public view {
        SD59x18 inv_maximum;

        try this.helpersInv(MAX_SD59x18) {
            inv_maximum = this.helpersInv(MAX_SD59x18);
            assert(equal_within_precision(inv_maximum, ZERO_FP, 10));
        } catch {
            // Unexpected, the function must not revert
            assert(false);
        }
    }

    // Test the minimum value case, should not revert, and be close to zero
    function inv_test_minimum() public view {
        SD59x18 inv_minimum;

        try this.helpersInv(MIN_SD59x18) {
            inv_minimum = this.helpersInv(MIN_SD59x18);
            assert(equal_within_precision(abs(inv_minimum), ZERO_FP, 10));
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
    function avg_test_values_in_range(SD59x18 x, SD59x18 y) public pure {
        SD59x18 avg_xy = avg(x, y);

        if (x.gte(y)) {
            assert(avg_xy.gte(y) && avg_xy.lte(x));
        } else {
            assert(avg_xy.gte(x) && avg_xy.lte(y));
        }
    }

    // Test that the average of the same number is itself
    // avg(x, x) == x
    function avg_test_one_value(SD59x18 x) public pure {
        SD59x18 avg_x = avg(x, x);

        assert(avg_x.eq(x));
    }

    // Test that the order of operands is irrelevant
    // avg(x, y) == avg(y, x)
    function avg_test_operand_order(SD59x18 x, SD59x18 y) public pure {
        SD59x18 avg_xy = avg(x, y);
        SD59x18 avg_yx = avg(y, x);

        assert(avg_xy.eq(avg_yx));
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // Test for the maximum value
    function avg_test_maximum() public view {
        SD59x18 result;

        // This may revert due to overflow depending on implementation
        // If it doesn't revert, the result must be MAX_SD59x18
        try this.helpersAvg(MAX_SD59x18, MAX_SD59x18) {
            result = this.helpersAvg(MAX_SD59x18, MAX_SD59x18);
            assert(result.eq(MAX_SD59x18));
        } catch {}
    }

    // Test for the minimum value
    function avg_test_minimum() public view {
        SD59x18 result;

        // This may revert due to overflow depending on implementation
        // If it doesn't revert, the result must be MIN_SD59x18
        try this.helpersAvg(MIN_SD59x18, MIN_SD59x18) {
            result = this.helpersAvg(MIN_SD59x18, MIN_SD59x18);
            assert(result.eq(MIN_SD59x18));
        } catch {}
    }

    /* ================================================================

                        TESTS FOR FUNCTION pow()

       ================================================================ */

    /* ================================================================
       Tests for arithmetic properties.
       These should make sure that the implemented function complies
       with math rules and expected behaviour.
       ================================================================ */

/* pow.t.sol
├── when the base is zero
│  ├── when the exponent is zero
│  │  └── it should return the unit number
│  └── when the exponent is not zero
│     └── it should return zero
└── when the base is not zero
   ├── when the base is the unit number       
   │  └── it should return the unit number
   └── when the base is not the unit number
      ├── when the exponent is zero
      │  └── it should return the base
      └── when the exponent is not zero
         ├── when the exponent is the unit number
         │  └── it should return the base
         └── when the exponent is not the unit number
            ├── when the exponent is negative
            │  └── it should return the correct value
            └── when the exponent is positive
               └── it should return the correct value */

    // Test for zero exponent
    // x ** 0 == 1
    function pow_test_zero_exponent(SD59x18 x) public view {
        SD59x18 x_pow_0 = pow(x, ZERO_FP);

        assert(x_pow_0.eq(ONE_FP));
    }

    // Test for zero base
    // 0 ** x == 0 (for positive x)
    function pow_test_zero_base(SD59x18 x) public view {
        require(x.neq(ZERO_FP));

        SD59x18 zero_pow_x = pow(ZERO_FP, x);

        assert(zero_pow_x.eq(ZERO_FP));
    }

    // Test for exponent one
    // x ** 1 == x
    function pow_test_one_exponent(SD59x18 x) public view {
        SD59x18 x_pow_1 = pow(x, ONE_FP);

        assert(x_pow_1.eq(x));
    }

    // Test for base one
    // 1 ** x == 1
    function pow_test_base_one(SD59x18 x) public view {
        SD59x18 one_pow_x = pow(ONE_FP, x);

        assert(one_pow_x.eq(ONE_FP));
    }

    // Test for product of powers of the same base
    // x ** a * x ** b == x ** (a + b)
    function pow_test_product_same_base(
        SD59x18 x,
        SD59x18 a,
        SD59x18 b
    ) public view {
        require(x.neq(ZERO_FP));

        SD59x18 x_a = pow(x, a);
        SD59x18 x_b = pow(x, b);
        SD59x18 x_ab = pow(x, a.add(b));

        assert(equal_within_precision(mul(x_a, x_b), x_ab, 2));
    }

    // Test for power of an exponentiation
    // (x ** a) ** b == x ** (a * b)
    function pow_test_power_of_an_exponentiation(
        SD59x18 x,
        SD59x18 a,
        SD59x18 b
    ) public view {
        require(x.neq(ZERO_FP));

        SD59x18 x_a = pow(x, a);
        SD59x18 x_a_b = pow(x_a, b);
        SD59x18 x_ab = pow(x, a.mul(b));

        assert(equal_within_precision(x_a_b, x_ab, 2));
    }

    // Test for power of a product
    // (x * y) ** a == x ** a * y ** a
    function pow_test_product_power(
        SD59x18 x,
        SD59x18 y,
        SD59x18 a
    ) public view {
        require(x.neq(ZERO_FP) && y.neq(ZERO_FP));
        // todo this should probably be changed
        require(a.gt(convert(2 ** 32))); // to avoid massive loss of precision

        SD59x18 x_y = mul(x, y);
        SD59x18 xy_a = pow(x_y, a);

        SD59x18 x_a = pow(x, a);
        SD59x18 y_a = pow(y, a);

        assert(equal_within_precision(mul(x_a, y_a), xy_a, 2));
    }

    // Test for result being greater than or lower than the argument, depending on
    // its absolute value and the value of the exponent
    function pow_test_values(SD59x18 x, SD59x18 a) public view {
        require(x.neq(ZERO_FP));
        require(x.neq(MIN_SD59x18) && a.neq(MIN_SD59x18));

        SD59x18 x_a = pow(x, a);

        if (abs(x).gte(ONE_FP)) {
            assert(abs(x_a).gte(ONE_FP));
        }

        if (abs(x).lte(ONE_FP)) {
            assert(abs(x_a).lte(ONE_FP));
        }
    }

    // Test for result sign: if the exponent is even, sign is positive
    // if the exponent is odd, preserves the sign of the base
    function pow_test_sign(SD59x18 x, SD59x18 a) public view {
        require(x.neq(ZERO_FP) && a.neq(ZERO_FP));

        SD59x18 x_a = pow(x, a);

        // This prevents the case where a small negative number gets
        // rounded down to zero and thus changes sign
        require(x_a.neq(ZERO_FP));

        // todo should I unwrap here?
        // If the exponent is even
        if (a.mod(convert(2)).eq(ZERO_FP)) {
            assert(x_a.eq(abs(x_a)));
        } else {
            // x_a preserves x sign
            if (x.lt(ZERO_FP)) {
                assert(x_a.lt(ZERO_FP));
            } else {
                assert(x_a.gt(ZERO_FP));
            }
        }
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // Test for maximum base and exponent > 1
    function pow_test_maximum_base(SD59x18 a) public view {
        require(a.gt(ONE_FP));

        try this.helpersPow(MAX_SD59x18, a) {
            // Unexpected, should revert because of overflow
            assert(false);
        } catch {
            // Expected revert
        }
    }

    // Test for abs(base) < 1 and high exponent
    function pow_test_high_exponent(SD59x18 x, SD59x18 a) public view {
        require(abs(x).lt(ONE_FP) && a.gt(convert(2 ** 64)));

        SD59x18 result = pow(x, a);

        assert(result.eq(ZERO_FP));
    }

    /* ================================================================

                        TESTS FOR FUNCTION sqrt()

       ================================================================ */

    /* ================================================================
       Tests for arithmetic properties.
       These should make sure that the implemented function complies
       with math rules and expected behaviour.
       ================================================================ */

    /// Notes:
    /// - Only the positive root is returned.
    /// - The result is rounded toward zero.
    ///
    /// Requirements:
    /// - x cannot be negative, since complex numbers are not supported.
    /// - x must be less than `MAX_SD59x18 / UNIT`.

    // Test for the inverse operation
    // sqrt(x) * sqrt(x) == x
    function sqrt_test_inverse_mul(SD59x18 x) public view {
        require(x.lte(ZERO_FP));

        SD59x18 sqrt_x = sqrt(x);
        SD59x18 sqrt_x_squared = mul(sqrt_x, sqrt_x);

        // Precision loss is at most half the bits of the operand
        assert(
            equal_within_precision(
                sqrt_x_squared,
                x,
                (intoUint256(log2(x)) >> 1) + 2
            )
        );
    }

    // Test for the inverse operation
    // sqrt(x) ** 2 == x
    function sqrt_test_inverse_pow(SD59x18 x) public view {
        require(x.gte(ZERO_FP));

        SD59x18 sqrt_x = sqrt(x);
        SD59x18 sqrt_x_squared = pow(sqrt_x, convert(2));

        // Precision loss is at most half the bits of the operand
        assert(
            equal_within_precision(
                sqrt_x_squared,
                x,
                (intoUint256(log2(x)) >> 1) + 2
            )
        );
    }

    // Test for distributive property respect to the multiplication
    // sqrt(x) * sqrt(y) == sqrt(x * y)
    function sqrt_test_distributive(SD59x18 x, SD59x18 y) public view {
        require(x.gte(ZERO_FP) && y.gte(ZERO_FP));

        SD59x18 sqrt_x = sqrt(x);
        SD59x18 sqrt_y = sqrt(y);
        SD59x18 sqrt_x_sqrt_y = mul(sqrt_x, sqrt_y);
        SD59x18 sqrt_xy = sqrt(mul(x, y));

        // Ensure we have enough significant digits for the result to be meaningful
        require(significant_digits_after_mult(x, y) > REQUIRED_SIGNIFICANT_BITS);
        require(
            significant_digits_after_mult(sqrt_x, sqrt_y) >
                REQUIRED_SIGNIFICANT_BITS
        );

        // Allow an error of up to one tenth of a percent
        assert(equal_within_tolerance(sqrt_x_sqrt_y, sqrt_xy, ONE_TENTH_FP));
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // Test for zero case
    function sqrt_test_zero() public view {
        assert(sqrt(ZERO_FP).eq(ZERO_FP));
    }

    // Test for maximum value
    function sqrt_test_maximum() public view {
        try this.helpersSqrt(MAX_SQRT) {
            // Expected behaviour, MAX_SD59x18 is positive, and operation
            // should not revert as the result is in range
        } catch {
            // Unexpected, should not revert
            assert(false);
        }
    }

    // Test for minimum value
    function sqrt_test_minimum() public view {
        try this.helpersSqrt(MIN_SD59x18) {
            // Unexpected, should revert. MIN_SD59x18 is negative.
            assert(false);
        } catch {
            // Expected behaviour, revert
        }
    }

    // Test for negative operands
    function sqrt_test_negative(SD59x18 x) public view {
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

    /// Requirements:
    /// - x must be greater than zero.

    // Test for distributive property respect to multiplication
    // log2(x * y) = log2(x) + log2(y)
    function log2_test_distributive_mul(SD59x18 x, SD59x18 y) public view {
        SD59x18 log2_x = log2(x);
        SD59x18 log2_y = log2(y);
        SD59x18 log2_x_log2_y = add(log2_x, log2_y);

        SD59x18 xy = mul(x, y);
        SD59x18 log2_xy = log2(xy);

        // Ensure we have enough significant digits for the result to be meaningful
        require(significant_digits_after_mult(x, y) > REQUIRED_SIGNIFICANT_BITS);

        // The maximum loss of precision is given by the formula:
        // | log2(x) + log2(y) |
        uint256 loss = intoUint256(abs(log2(x).add(log2(y))));

        assert(equal_within_precision(log2_x_log2_y, log2_xy, loss));
    }

    // Test for logarithm of a power
    // log2(x ** y) = y * log2(x)
    function log2_test_power(SD59x18 x, SD59x18 y) public pure {
        SD59x18 x_y = pow(x, y);
        SD59x18 log2_x_y = log2(x_y);
        SD59x18 y_log2_x = mul(log2(x), y);

        assert(y_log2_x.eq(log2_x_y));
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // Test for zero case, should revert
    function log2_test_zero() public view {
        try this.helpersLog2(ZERO_FP) {
            // Unexpected, should revert
            assert(false);
        } catch {
            // Expected revert, log(0) is not defined
        }
    }

    // Test for maximum value case, should return a positive number
    function log2_test_maximum() public view {
        SD59x18 result;

        try this.helpersLog2(MAX_SD59x18) {
            // Expected, should not revert and the result must be > 0
            result = this.helpersLog2(MAX_SD59x18);
            assert(result.gt(ZERO_FP));
        } catch {
            // Unexpected
            assert(false);
        }
    }

    // Test for negative values, should revert as log2 is not defined
    function log2_test_negative(SD59x18 x) public view {
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

    /// Requirements:
    /// - x must be greater than zero.

    // Test for distributive property respect to multiplication
    // ln(x * y) = ln(x) + ln(y)
    function ln_test_distributive_mul(SD59x18 x, SD59x18 y) public view {
        require(x.gt(ZERO_FP) && y.gt(ZERO_FP));

        SD59x18 ln_x = ln(x);
        SD59x18 ln_y = ln(y);
        SD59x18 ln_x_ln_y = add(ln_x, ln_y);

        SD59x18 xy = mul(x, y);
        SD59x18 ln_xy = ln(xy);

        require(significant_digits_after_mult(x, y) > REQUIRED_SIGNIFICANT_BITS);

        // The maximum loss of precision is given by the formula:
        // | log2(x) + log2(y) |
        uint256 loss = intoUint256(abs(log2(x).add(log2(y))));

        assert(equal_within_precision(ln_x_ln_y, ln_xy, loss));
    }

    // Test for logarithm of a power
    // ln(x ** y) = y * ln(x)
    function ln_test_power(SD59x18 x, SD59x18 y) public {
        require(x.gt(ZERO_FP));
        SD59x18 x_y = pow(x, y);
        SD59x18 ln_x_y = ln(x_y);

        SD59x18 y_ln_x = mul(ln(x), y);

        uint256 loss = intoUint256(abs(log2(x).add(log2(y))));

        assert(equal_within_precision(ln_x_y, y_ln_x, loss));
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // Test for zero case, should revert
    function ln_test_zero() public view {
        try this.helpersLn(ZERO_FP) {
            // Unexpected, should revert
            assert(false);
        } catch {
            // Expected revert, log(0) is not defined
        }
    }

    // Test for maximum value case, should return a positive number
    function ln_test_maximum() public view {
        SD59x18 result;

        try this.helpersLn(MAX_SD59x18) {
            // Expected, should not revert and the result must be > 0
            result = this.helpersLn(MAX_SD59x18);
            assert(result.gt(ZERO_FP));
        } catch {
            // Unexpected
            assert(false);
        }
    }

    // Test for negative values, should revert as ln is not defined
    function ln_test_negative(SD59x18 x) public view {
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

    /// Notes:
    /// - If x is less than -59_794705707972522261, the result is zero.
    ///
    /// Requirements:
    /// - x must be less than 192e18.
    /// - The result must fit in SD59x18.

    // Test for equality with pow(2, x) for integer x
    // pow(2, x) == exp2(x)
    function exp2_test_equivalence_pow(SD59x18 x) public view {
        SD59x18 exp2_x = exp2(x);
        SD59x18 pow_2_x = pow(TWO_FP, x);

        assert(exp2_x.eq(pow_2_x));
    }

    // Test for inverse function
    // If y = log2(x) then exp2(y) == x
    function exp2_test_inverse(SD59x18 x) public view {
        SD59x18 log2_x = log2(x);
        SD59x18 exp2_x = exp2(log2_x);

        // todo is this the correct number of bits?
        uint256 bits = 50;

        if (log2_x.lt(ZERO_FP)) {
            bits = intoUint256(convert(int256(bits)).add(log2_x));
        }

        assert(equal_most_significant_digits_within_precision(x, exp2_x, bits));
    }

    // Test for negative exponent
    // exp2(-x) == inv( exp2(x) )
    function exp2_test_negative_exponent(SD59x18 x) public view {
        require(x.lt(ZERO_FP) && x.neq(MIN_SD59x18));

        SD59x18 exp2_x = exp2(x);
        SD59x18 exp2_minus_x = exp2(neg(x));

        // Result should be within 4 bits precision for the worst case
        assert(equal_within_precision(exp2_x, inv(exp2_minus_x), 4));
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // Test for zero case
    // exp2(0) == 1
    function exp2_test_zero() public view {
        SD59x18 exp_zero = exp2(ZERO_FP);
        assert(exp_zero.eq(ONE_FP));
    }

    // Test for maximum value. This should overflow as it won't fit
    // in the data type
    function exp2_test_maximum() public view {
        try this.helpersExp2(MAX_SD59x18) {
            // Unexpected, should revert
            assert(false);
        } catch {
            // Expected revert
        }
    }

    // Test for minimum value. This should return zero since
    // 2 ** -x == 1 / 2 ** x that tends to zero as x increases
    function exp2_test_minimum() public view {
        SD59x18 result;

        try this.helpersExp2(MIN_SD59x18) {
            // Expected, should not revert, check that value is zero
            result = exp2(MIN_SD59x18);
            assert(result.eq(ZERO_FP));
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

    /// Requirements:
    /// - The result must fit in SD59x18..
    /// - x must be less than 133_084258667509499441.

    // Test for inverse function
    // If y = ln(x) then exp(y) == x
    function exp_test_inverse(SD59x18 x) public view {
        SD59x18 ln_x = ln(x);
        SD59x18 exp_x = exp(ln_x);
        SD59x18 log2_x = log2(x);

        uint256 bits = 48;

        if (log2_x.lt(ZERO_FP)) {
            bits = intoUint256(convert(int256(bits)).add(log2_x));
        }

        assert(equal_most_significant_digits_within_precision(x, exp_x, bits));
    }

    // Test for negative exponent
    // exp(-x) == inv( exp(x) )
    function exp_test_negative_exponent(SD59x18 x) public view {
        require(x.lt(ZERO_FP) && x.neq(MIN_SD59x18));

        SD59x18 exp_x = exp(x);
        SD59x18 exp_minus_x = exp(neg(x));

        // Result should be within 4 bits precision for the worst case
        assert(equal_within_precision(exp_x, inv(exp_minus_x), 4));
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // Test for zero case
    // exp(0) == 1
    function exp_test_zero() public view {
        SD59x18 exp_zero = exp(ZERO_FP);
        assert(exp_zero.eq(ONE_FP));
    }

    // Test for maximum value. This should overflow as it won't fit
    // in the data type
    function exp_test_maximum() public view {
        try this.helpersExp(MAX_SD59x18) {
            // Unexpected, should revert
            assert(false);
        } catch {
            // Expected revert
        }
    }

    // Test for minimum value. This should return zero since
    // e ** -x == 1 / e ** x that tends to zero as x increases
    function exp_test_minimum() public view {
        SD59x18 result;

        try this.helpersExp(MIN_SD59x18) {
            // Expected, should not revert, check that value is zero
            result = exp(MIN_SD59x18);
            assert(result.eq(ZERO_FP));
        } catch {
            // Unexpected revert
            assert(false);
        }
    }

}