pragma solidity ^0.8.19;

import { UD60x18 } from "@prb/math/src/UD60x18.sol";
import {add, sub, eq, gt, gte, lt, lte, lshift, rshift} from "@prb/math/src/ud60x18/Helpers.sol";
import {convert} from "@prb/math/src/ud60x18/Conversions.sol";
import {msb} from "@prb/math/src/Common.sol";
import {intoUint128, intoUint256} from "@prb/math/src/ud60x18/Casting.sol";
import {mul, div, ln, exp, exp2, log2, sqrt, pow, avg, inv, log10, floor, powu} from "@prb/math/src/ud60x18/Math.sol";

contract CryticPRBMath60x18Propertiesv3 {

    event AssertionFailed(UD60x18 result);
    event AssertionFailed(UD60x18 result1, UD60x18 result2);

    /* ================================================================
       59x18 fixed-point constants used for testing specific values.
       This assumes that PRBMath library's convert(x) works as expected.
       ================================================================ */
    UD60x18 internal ZERO_FP = convert(0);
    UD60x18 internal ONE_FP = convert(1);
    UD60x18 internal TWO_FP = convert(2);
    UD60x18 internal THREE_FP = convert(3);
    UD60x18 internal EIGHT_FP = convert(8);
    UD60x18 internal THOUSAND_FP = convert(1000);
    UD60x18 internal EPSILON = UD60x18.wrap(1);
    UD60x18 internal ONE_TENTH_FP = convert(1).div(convert(10));

    /* ================================================================
       Constants used for precision loss calculations
       ================================================================ */
    uint256 internal REQUIRED_SIGNIFICANT_DIGITS = 10;

    /* ================================================================
       Integer representations maximum values.
       These constants are used for testing edge cases or limits for 
       possible values.
       ================================================================ */
    /// @dev Euler's number as an UD60x18 number.
    UD60x18 constant E = UD60x18.wrap(2_718281828459045235);

    /// @dev Half the UNIT number.
    uint256 constant uHALF_UNIT = 0.5e18;
    UD60x18 constant HALF_UNIT = UD60x18.wrap(uHALF_UNIT);

    /// @dev log2(10) as an UD60x18 number.
    uint256 constant uLOG2_10 = 3_321928094887362347;
    UD60x18 constant LOG2_10 = UD60x18.wrap(uLOG2_10);

    /// @dev log2(e) as an UD60x18 number.
    uint256 constant uLOG2_E = 1_442695040888963407;
    UD60x18 constant LOG2_E = UD60x18.wrap(uLOG2_E);

    /// @dev The maximum value an UD60x18 number can have.
    uint256 constant uMAX_UD60x18 = 115792089237316195423570985008687907853269984665640564039457_584007913129639935;
    UD60x18 constant MAX_UD60x18 = UD60x18.wrap(uMAX_UD60x18);

    /// @dev The maximum whole value an UD60x18 number can have.
    uint256 constant uMAX_WHOLE_UD60x18 = 115792089237316195423570985008687907853269984665640564039457_000000000000000000;
    UD60x18 constant MAX_WHOLE_UD60x18 = UD60x18.wrap(uMAX_WHOLE_UD60x18);

    /// @dev PI as an UD60x18 number.
    UD60x18 constant PI = UD60x18.wrap(3_141592653589793238);

    /// @dev The unit amount that implies how many trailing decimals can be represented.
    uint256 constant uUNIT = 1e18;
    UD60x18 constant UNIT = UD60x18.wrap(uUNIT);

    /// @dev Zero as an UD60x18 number.
    UD60x18 constant ZERO = UD60x18.wrap(0);

    UD60x18 internal constant MAX_PERMITTED_EXP2 = UD60x18.wrap(192e18 - 1);
    UD60x18 internal constant MAX_PERMITTED_EXP = UD60x18.wrap(133_084258667509499440);
    UD60x18 internal constant MAX_PERMITTED_EXPONENT_POW = UD60x18.wrap(2 ** 192 * 10 ** 18 - 1);
    UD60x18 internal constant MAX_PERMITTED_SQRT = UD60x18.wrap(115792089237316195423570985008687907853269_984665640564039457);



    /* ================================================================
       Events used for debugging or showing information.
       ================================================================ */
    event Value(string reason, int256 val);
    event LogErr(bytes error);


    /* ================================================================
       Helper functions.
       ================================================================ */

    // @audit not checking for overflows
    // These functions allows to compare a and b for equality, discarding
    // the last precision_bits bits.
    // Uses functions from the library under test!
    function equal_within_precision(UD60x18 a, UD60x18 b, uint256 precision_bits) public pure returns(bool) {
        UD60x18 max = gt(a , b) ? a : b;
        UD60x18 min = gt(a , b) ? b : a;
        UD60x18 r = rshift(sub(max, min), precision_bits);
        
        return (eq(r, convert(0)));
    }

    // @audit not checking for overflows
    function equal_within_precision_u(uint256 a, uint256 b, uint256 precision_bits) public pure returns(bool) {
        uint256 max = (a > b) ? a : b;
        uint256 min = (a > b) ? b : a;
        uint256 r = (max - min) >> precision_bits;
        
        return (r == 0);
    }

    // This function determines if the relative error between a and b is less
    // than error_percent % (expressed as a 59x18 value)
    // Uses functions from the library under test!
    function equal_within_tolerance(UD60x18 a, UD60x18 b, UD60x18 error_percent) public pure returns(bool) {
        UD60x18 tol_value = mul(a, div(error_percent, convert(100)));

        return (lte(sub(b, a), tol_value));
    }

    // @audit precision can never be negative
    // Check that there are remaining significant digits after a multiplication
    // Uses functions from the library under test!
    function significant_digits_lost_in_mult(UD60x18 a, UD60x18 b) public pure returns (bool) {
        uint256 la = convert(floor(log10(a)));
        uint256 lb = convert(floor(log10(b)));

        return(la + lb < 18);
    }

    // @audit precision can never be negative
    // Return how many significant bits will remain after multiplying a and b
    // Uses functions from the library under test!
    function significant_digits_after_mult(UD60x18 a, UD60x18 b) public pure returns (uint256) {
        uint256 la = convert(floor(log10(a)));
        uint256 lb = convert(floor(log10(b)));
        uint256 prec = la + lb;

        if (prec < 18) return 0;
        else return(18 + uint256(prec));
    }

    // Returns true if the n most significant bits of a and b are almost equal 
    // Uses functions from the library under test!
    function equal_most_significant_digits_within_precision(UD60x18 a, UD60x18 b, uint256 bits) public view returns (bool) {
        // Get the number of bits in a and b
        // Since log(x) returns in the interval [-64, 63), add 64 to be in the interval [0, 127)
        uint256 a_bits = uint256(int256(convert(log2(a))));
        uint256 b_bits = uint256(int256(convert(log2(b))));

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
        UD60x18 n,
        uint256 i
    ) public view returns (uint256) {
        if (n.eq(ZERO_FP)) return 0;
        
        // Create a mask consisting of i bits set to 1
        uint256 mask = (2 ** i) - 1;

        // Get the positive value of n
        uint256 value = intoUint256(n);

        // Get the position of the MSB set to 1 of n
        uint256 pos = msb(value);

        // Shift the mask to match the rightmost 1-set bit
        if (pos > i) {
            mask <<= (pos - i);
        }

        return (value & mask);
    }

    /* function compute_max_log_error(UD60x18 x) public view returns (UD60x18 result) {
        int256 xInt = UD60x18.unwrap(x);

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
       These functions allow calling the PRBMathUD60x18 library.
       ================================================================ */
    function debug(string calldata x, int256 y) public {
        emit Value(x, y);
    }

    // Wrapper for external try/catch calls
    function helpersAdd(UD60x18 x, UD60x18 y) public pure returns (UD60x18) {
       return add(x,y);
    }

    // Wrapper for external try/catch calls
    function helpersSub(UD60x18 x, UD60x18 y) public pure returns (UD60x18) {
       return sub(x,y);
    }

    // Wrapper for external try/catch calls
    function helpersMul(UD60x18 x, UD60x18 y) public pure returns (UD60x18) {
       return mul(x,y);
    }

    function helpersDiv(UD60x18 x, UD60x18 y) public pure returns (UD60x18) {
        return div(x,y);
    }

    function helpersLn(UD60x18 x) public pure returns (UD60x18) {
        return ln(x);
    }

    function helpersExp(UD60x18 x) public pure returns (UD60x18) {
        return exp(x);
    }

    function helpersExp2(UD60x18 x) public pure returns (UD60x18) {
        return exp2(x);
    }

    function helpersLog2(UD60x18 x) public pure returns (UD60x18) {
        return log2(x);
    }

    function helpersSqrt(UD60x18 x) public pure returns (UD60x18) {
        return sqrt(x);
    }

    function helpersPow(UD60x18 x, UD60x18 y) public pure returns (UD60x18) {
        return pow(x, y);
    }

    function helpersPowu(UD60x18 x, uint256 y) public pure returns (UD60x18) {
        return powu(x, y);
    }

    function helpersAvg(UD60x18 x, UD60x18 y) public pure returns (UD60x18) {
        return avg(x, y);
    }

    function helpersInv(UD60x18 x) public pure returns (UD60x18) {
        return inv(x);
    }

    function helpersLog10(UD60x18 x) public pure returns (UD60x18) {
        return log10(x);
    }

    function helpersFloor(UD60x18 x) public pure returns (UD60x18) {
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

    // @audit-ok
    // Test for commutative property
    // x + y == y + x
    function add_test_commutative(UD60x18 x, UD60x18 y) public pure {
        UD60x18 x_y = x.add(y);
        UD60x18 y_x = y.add(x);

        assert(x_y.eq(y_x));
    }

    // @audit-ok
    // Test for associative property
    // (x + y) + z == x + (y + z)
    function add_test_associative(UD60x18 x, UD60x18 y, UD60x18 z) public pure {
        UD60x18 x_y = x.add(y);
        UD60x18 y_z = y.add(z);
        UD60x18 xy_z = x_y.add(z);
        UD60x18 x_yz = x.add(y_z);

        assert(xy_z.eq(x_yz));
    }

    // @audit-ok
    // Test for identity operation
    // x + 0 == x (equivalent to x + (-x) == 0)
    function add_test_identity(UD60x18 x) public view {
        UD60x18 x_0 = x.add(ZERO_FP);

        assert(x.eq(x_0));
        assert(x.sub(x).eq(ZERO_FP));
    }

    // @audit-ok
    // Test that the result increases or decreases depending
    // on the value to be added
    function add_test_values(UD60x18 x, UD60x18 y) public view {
        UD60x18 x_y = x.add(y);

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

    // @audit-ok
    // The result of the addition must be between the maximum
    // and minimum allowed values for UD60x18
    function add_test_range(UD60x18 x, UD60x18 y) public view {
        try this.helpersAdd(x, y) returns (UD60x18 result) {
            assert(result.lte(MAX_UD60x18) && result.gte(ZERO_FP));
        } catch {
            // If it reverts, just ignore
        }
    }

    // @audit-ok
    // Adding zero to the maximum value shouldn't revert, as it is valid
    // Moreover, the result must be MAX_UD60x18
    function add_test_maximum_value() public view {
        try this.helpersAdd(MAX_UD60x18, ZERO_FP) returns (UD60x18 result) {
            // Expected behaviour, does not revert
            assert(result.eq(MAX_UD60x18));
        } catch {
            assert(false);
        }
    }

    // @audit-ok
    // Adding one to the maximum value should revert, as it is out of range
    function add_test_maximum_value_plus_one() public view {
        try this.helpersAdd(MAX_UD60x18, ONE_FP) {
            assert(false);
        } catch {
            // Expected behaviour, reverts
        }
    }

    // @audit-ok
    // Adding zero to the minimum value shouldn't revert, as it is valid
    // Moreover, the result must be MIN_UD60x18
    function add_test_minimum_value() public view {
        try this.helpersAdd(ZERO_FP, ZERO_FP) returns (UD60x18 result) {
            // Expected behaviour, does not revert
            assert(result.eq(ZERO_FP));
        } catch {
            assert(false);
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

    // @audit-ok
    // Test for identity operation
    // x - 0 == x  (equivalent to x - x == 0)
    function sub_test_identity(UD60x18 x) public view {
        UD60x18 x_0 = x.sub(ZERO_FP);

        assert(x_0.eq(x));
        assert(x.sub(x).eq(ZERO_FP));
    }

    // @audit-ok
    // Test for neutrality over addition and subtraction
    // (x - y) + y == (x + y) - y == x
    function sub_test_neutrality(UD60x18 x, UD60x18 y) public pure {
        UD60x18 x_minus_y = x.sub(y);
        UD60x18 x_plus_y = x.add(y);

        UD60x18 x_minus_y_plus_y = x_minus_y.add(y);
        UD60x18 x_plus_y_minus_y = x_plus_y.sub(y);
        
        assert(x_minus_y_plus_y.eq(x_plus_y_minus_y));
        assert(x_minus_y_plus_y.eq(x));
    }

    // @audit-ok
    // Test that the result always decreases
    function sub_test_values(UD60x18 x, UD60x18 y) public view {
        UD60x18 x_y = x.sub(y);

        assert(x_y.lte(x));
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // @audit-ok
    // The result of the subtraction must be between the maximum
    // and minimum allowed values for UD60x18
    function sub_test_range(UD60x18 x, UD60x18 y) public view {
        try this.helpersSub(x, y) returns (UD60x18 result) {
            assert(result.lte(MAX_UD60x18) && result.gte(ZERO_FP));
        } catch {
            // If it reverts, just ignore
        }
    }

    // @audit-ok
    // Subtracting zero from the maximum value shouldn't revert, as it is valid
    // Moreover, the result must be MAX_UD60x18
    function sub_test_maximum_value() public view {
        try this.helpersSub(MAX_UD60x18, ZERO_FP) returns (UD60x18 result) {
            // Expected behaviour, does not revert
            assert(result.eq(MAX_UD60x18));
        } catch {
            assert(false);
        }
    }

    // @audit-ok
    // Subtracting zero from the minimum value shouldn't revert, as it is valid
    // Moreover, the result must be MIN_UD60x18
    function sub_test_minimum_value() public view {
        try this.helpersSub(ZERO_FP, ZERO_FP) returns (UD60x18 result) {
            // Expected behaviour, does not revert
            assert(result.eq(ZERO_FP));
        } catch {
            assert(false);
        }
    }

    // @audit-ok
    // Subtracting one from the minimum value should revert, as it is out of range
    function sub_test_minimum_value_minus_one() public view {
        try this.helpersSub(ZERO_FP, ONE_FP) {
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

    // @audit-ok
    // Test for commutative property
    // x * y == y * x
    function mul_test_commutative(UD60x18 x, UD60x18 y) public pure {
        UD60x18 x_y = x.mul(y);
        UD60x18 y_x = y.mul(x);

        assert(x_y.eq(y_x));
    }

    // @audit - No guarantee of precision
    // Test for associative property
    // (x * y) * z == x * (y * z)
    function mul_test_associative(UD60x18 x, UD60x18 y, UD60x18 z) public view {
        UD60x18 x_y = x.mul(y);
        UD60x18 y_z = y.mul(z);
        UD60x18 xy_z = x_y.mul(z);
        UD60x18 x_yz = x.mul(y_z);

        // todo check if this should not be used
        // Failure if all significant digits are lost
        require(significant_digits_after_mult(x, y) > REQUIRED_SIGNIFICANT_DIGITS);
        require(significant_digits_after_mult(y, z) > REQUIRED_SIGNIFICANT_DIGITS);
        require(significant_digits_after_mult(x_y, z) > REQUIRED_SIGNIFICANT_DIGITS);
        require(significant_digits_after_mult(x, y_z) > REQUIRED_SIGNIFICANT_DIGITS);

        assert(equal_within_tolerance(xy_z, x_yz, ONE_TENTH_FP));
        //assert(xy_z.eq(x_yz));
    }

    // @audit - No guarantee of precision
    // Test for distributive property
    // x * (y + z) == x * y + x * z
    function mul_test_distributive(UD60x18 x, UD60x18 y, UD60x18 z) public view {
        UD60x18 y_plus_z = y.add(z);
        UD60x18 x_times_y_plus_z = x.mul(y_plus_z);

        UD60x18 x_times_y = x.mul(y);
        UD60x18 x_times_z = x.mul(z);

        // todo check if this should not be used
        // Failure if all significant digits are lost
        require(significant_digits_after_mult(x, y) > REQUIRED_SIGNIFICANT_DIGITS);
        require(significant_digits_after_mult(x, z) > REQUIRED_SIGNIFICANT_DIGITS);
        require(significant_digits_after_mult(x, y_plus_z) > REQUIRED_SIGNIFICANT_DIGITS);

        assert(equal_within_tolerance(add(x_times_y, x_times_z), x_times_y_plus_z, ONE_TENTH_FP));
        //assert(x_times_y.add(x_times_z).eq(x_times_y_plus_z));
    }

    // @audit-ok
    // Test for identity operation
    // x * 1 == x  (also check that x * 0 == 0)
    function mul_test_identity(UD60x18 x) public view {
        UD60x18 x_1 = x.mul(ONE_FP);
        UD60x18 x_0 = x.mul(ZERO_FP);

        assert(x_0.eq(ZERO_FP));
        assert(x_1.eq(x));
    }

    // @audit - No guarantee of precision
    // Test that the result increases or decreases depending
    // on the value to be added
    function mul_test_values(UD60x18 x, UD60x18 y) public view {
        UD60x18 x_y = x.mul(y);

        //require(significant_digits_lost_in_mult(x, y) == false);

        if (y.gte(ONE_FP)) {
            assert(x_y.gte(x));
        } else {
            assert(x_y.lte(x));
        }
    }
    

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // @audit-ok
    // The result of the multiplication must be between the maximum
    // and minimum allowed values for UD60x18
    function mul_test_range(UD60x18 x, UD60x18 y) public view {
        try this.helpersMul(x, y) returns(UD60x18 result) {
            assert(result.lte(MAX_UD60x18));
        } catch {
            // If it reverts, just ignore
        }
    }

    // @audit-ok
    // Multiplying the maximum value times one shouldn't revert, as it is valid
    // Moreover, the result must be MAX_UD60x18
    function mul_test_maximum_value() public view {
        try this.helpersMul(MAX_UD60x18, ONE_FP) returns (UD60x18 result) {
            // Expected behaviour, does not revert
            assert(result.eq(MAX_UD60x18));
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

    // @audit-ok
    // Test for identity property
    // x / 1 == x (equivalent to x / x == 1)
    // Moreover, x/x should not revert unless x == 0
    function div_test_division_identity(UD60x18 x) public view {
        UD60x18 div_1 = div(x, ONE_FP);
        assert(x.eq(div_1));

        UD60x18 div_x;

        try this.helpersDiv(x, x) {
            // This should always equal one
            div_x = div(x, x);
            assert(div_x.eq(ONE_FP));
        } catch {
            // Only valid case for revert is x == 0
            assert(x.eq(ZERO_FP));
        }
    }

    // @audit-ok
    // Test for division with 0 as numerator
    // 0 / x = 0
    function div_test_division_num_zero(UD60x18 x) public view {
        require(x.neq(ZERO_FP));

        UD60x18 div_0 = div(ZERO_FP, x);

        assert(ZERO_FP.eq(div_0));
    }

    // @audit-ok
    // Test that the value of the result increases or
    // decreases depending on the denominator's value
    function div_test_values(UD60x18 x, UD60x18 y) public view {
        require(y.neq(ZERO_FP));

        UD60x18 x_y = div(x, y);

        if (y.gte(ONE_FP)) {
            assert(x_y.lte(x));
        } else {
            assert(x_y.gte(x));
        }
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // @audit-ok
    // Test for division by zero
    function div_test_div_by_zero(UD60x18 x) public view {
        try this.helpersDiv(x, ZERO_FP) {
            // Unexpected, this should revert
            assert(false);
        } catch {
            // Expected revert
        }
    }

    // @audit-ok
    // Test for division by a large value, the result should be less than one
    function div_test_maximum_denominator(UD60x18 x) public view {
        UD60x18 div_large = div(x, MAX_UD60x18);

        assert(div_large.lte(ONE_FP));
    }

    // @audit-ok
    // Test for division of a large value
    // This should revert if |x| < 1 as it would return a value higher than max
    function div_test_maximum_numerator(UD60x18 x) public view {
        UD60x18 div_large;

        try this.helpersDiv(MAX_UD60x18, x) {
            // If it didn't revert, then |x| >= 1
            div_large = div(MAX_UD60x18, x);

            assert(x.gte(ONE_FP));
        } catch {
            // Expected revert as result is higher than max
        }
    }

    // @audit-ok
    // Test for values in range
    function div_test_range(UD60x18 x, UD60x18 y) public view {
        UD60x18 result;

        try this.helpersDiv(x, y) {
            // If it returns a value, it must be in range
            result = div(x, y);
            assert(result.lte(MAX_UD60x18));
        } catch {
            // Otherwise, it should revert
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

    // @audit-ok
    // Test that the inverse of the inverse is close enough to the
    // original number
    function inv_test_double_inverse(UD60x18 x) public view {
        require(x.neq(ZERO_FP));

        UD60x18 double_inv_x = inv(inv(x));

        // The maximum loss of precision will be 2 * log2(x) bits rounded up
        uint256 loss = 2 * intoUint256(log2(x)) + 2;

        assert(equal_within_precision(x, double_inv_x, loss));
    }

    // @audit-ok
    // Test equivalence with division
    function inv_test_division(UD60x18 x) public view {
        require(x.neq(ZERO_FP));

        UD60x18 inv_x = inv(x);
        UD60x18 div_1_x = div(ONE_FP, x);

        assert(inv_x.eq(div_1_x));
    }

    // @audit check if loss is correct
    // Test the anticommutativity of the division
    // x / y == 1 / (y / x)
    function inv_test_division_noncommutativity(
        UD60x18 x,
        UD60x18 y
    ) public view {
        require(x.neq(ZERO_FP) && y.neq(ZERO_FP));

        UD60x18 x_y = div(x, y);
        UD60x18 y_x = div(y, x);

        require(
            significant_digits_after_mult(x, inv(y)) > REQUIRED_SIGNIFICANT_DIGITS
        );
        require(
            significant_digits_after_mult(y, inv(x)) > REQUIRED_SIGNIFICANT_DIGITS
        );
        assert(equal_within_tolerance(x_y, inv(y_x), ONE_TENTH_FP));
    }

    // @audit check if loss is correct
    // Test the multiplication of inverses
    // 1/(x * y) == 1/x * 1/y
    function inv_test_multiplication(UD60x18 x, UD60x18 y) public view {
        require(x.neq(ZERO_FP) && y.neq(ZERO_FP));

        UD60x18 inv_x = inv(x);
        UD60x18 inv_y = inv(y);
        UD60x18 inv_x_times_inv_y = mul(inv_x, inv_y);

        UD60x18 x_y = mul(x, y);
        UD60x18 inv_x_y = inv(x_y);

        require(significant_digits_after_mult(x, y) > REQUIRED_SIGNIFICANT_DIGITS);
        require(
            significant_digits_after_mult(inv_x, inv_y) > REQUIRED_SIGNIFICANT_DIGITS
        );

        // The maximum loss of precision is given by the formula:
        // 2 * | log2(x) - log2(y) | + 1
        uint256 loss = 2 * intoUint256(log2(x).sub(log2(y))) + 1;

        assert(equal_within_precision(inv_x_y, inv_x_times_inv_y, loss));
    }

    // @audit-ok
    // Test identity property
    // Intermediate result should have at least REQUIRED_SIGNIFICANT_DIGITS
    function inv_test_identity(UD60x18 x) public view {
        require(x.neq(ZERO_FP));

        UD60x18 inv_x = inv(x);
        UD60x18 identity = mul(inv_x, x);

        require(
            significant_digits_after_mult(x, inv_x) > REQUIRED_SIGNIFICANT_DIGITS
        );

        // They should agree with a tolerance of one tenth of a percent
        assert(equal_within_tolerance(identity, ONE_FP, ONE_TENTH_FP));
    }

    // @audit-ok
    // Test that the value of the result is in range zero-one
    // if x is greater than one, else, the value of the result
    // must be greater than one
    function inv_test_values(UD60x18 x) public view {
        require(x.neq(ZERO_FP));

        UD60x18 inv_x = inv(x);

        if (x.gte(ONE_FP)) {
            assert(inv_x.lte(ONE_FP));
        } else {
            assert(inv_x.gt(ONE_FP));
        }
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // @audit-ok
    // Test the zero-case, should revert
    function inv_test_zero() public view {
        try this.helpersInv(ZERO_FP) {
            // Unexpected, the function must revert
            assert(false);
        } catch {}
    }

    // @audit-ok
    // Test the maximum value case, should not revert, and be close to zero
    function inv_test_maximum() public view {
        UD60x18 inv_maximum;

        try this.helpersInv(MAX_UD60x18) {
            inv_maximum = this.helpersInv(MAX_UD60x18);
            assert(equal_within_precision(inv_maximum, ZERO_FP, 10));
        } catch {
            // Unexpected, the function must not revert
            assert(false);
        }
    }

    // @audit Check precision
    // Test the minimum value case, should not revert, and be close to zero
    function inv_test_minimum() public view {
        UD60x18 inv_minimum;

        try this.helpersInv(UD60x18.wrap(1)) {
            inv_minimum = this.helpersInv(UD60x18.wrap(1));
            assert(equal_within_precision(inv_minimum, ZERO_FP, 10));
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

    // @audit-ok
    // Test that the result is between the two operands
    // avg(x, y) >= min(x, y) && avg(x, y) <= max(x, y)
    function avg_test_values_in_range(UD60x18 x, UD60x18 y) public pure {
        UD60x18 avg_xy = avg(x, y);

        if (x.gte(y)) {
            assert(avg_xy.gte(y) && avg_xy.lte(x));
        } else {
            assert(avg_xy.gte(x) && avg_xy.lte(y));
        }
    }

    // @audit-ok
    // Test that the average of the same number is itself
    // avg(x, x) == x
    function avg_test_one_value(UD60x18 x) public pure {
        UD60x18 avg_x = avg(x, x);

        assert(avg_x.eq(x));
    }

    // @audit-ok
    // Test that the order of operands is irrelevant
    // avg(x, y) == avg(y, x)
    function avg_test_operand_order(UD60x18 x, UD60x18 y) public pure {
        UD60x18 avg_xy = avg(x, y);
        UD60x18 avg_yx = avg(y, x);

        assert(avg_xy.eq(avg_yx));
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // @audit-ok
    // Test for the maximum value
    function avg_test_maximum() public view {
        UD60x18 result;

        // This may revert due to overflow depending on implementation
        // If it doesn't revert, the result must be MAX_UD60x18
        try this.helpersAvg(MAX_UD60x18, MAX_UD60x18) {
            result = this.helpersAvg(MAX_UD60x18, MAX_UD60x18);
            assert(result.eq(MAX_UD60x18));
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

    // @audit-ok
    // Test for zero exponent
    // x ** 0 == 1
    function pow_test_zero_exponent(UD60x18 x) public view {
        UD60x18 x_pow_0 = pow(x, ZERO_FP);

        assert(x_pow_0.eq(ONE_FP));
    }

    // @audit-ok
    // Test for zero base
    // 0 ** x == 0 (for positive x)
    function pow_test_zero_base(UD60x18 x) public view {
        require(x.neq(ZERO_FP));

        UD60x18 zero_pow_x = pow(ZERO_FP, x);

        assert(zero_pow_x.eq(ZERO_FP));
    }

    // @audit-ok
    // Test for exponent one
    // x ** 1 == x
    function pow_test_one_exponent(UD60x18 x) public view {
        UD60x18 x_pow_1 = pow(x, ONE_FP);

        assert(x_pow_1.eq(x));
    }

    // @audit-ok
    // Test for base one
    // 1 ** x == 1
    function pow_test_base_one(UD60x18 x) public view {
        UD60x18 one_pow_x = pow(ONE_FP, x);

        assert(one_pow_x.eq(ONE_FP));
    }

    // @audit - Fails
    // Test for product of powers of the same base
    // x ** a * x ** b == x ** (a + b)
    function pow_test_product_same_base(
        UD60x18 x,
        UD60x18 a,
        UD60x18 b
    ) public view {
        require(x.neq(ZERO_FP));

        UD60x18 x_a = pow(x, a);
        UD60x18 x_b = pow(x, b);
        UD60x18 x_ab = pow(x, a.add(b));

        assert(equal_within_precision(mul(x_a, x_b), x_ab, 10));
    }

    // @audit - fails
    // Test for power of an exponentiation
    // (x ** a) ** b == x ** (a * b)
    function pow_test_power_of_an_exponentiation(
        UD60x18 x,
        UD60x18 a,
        UD60x18 b
    ) public view {
        require(x.neq(ZERO_FP));

        UD60x18 x_a = pow(x, a);
        UD60x18 x_a_b = pow(x_a, b);
        UD60x18 x_ab = pow(x, a.mul(b));

        assert(equal_within_precision(x_a_b, x_ab, 10));
    }

    // @audit check precision
    // Test for power of a product
    // (x * y) ** a == x ** a * y ** a
    function pow_test_product_power(
        UD60x18 x,
        UD60x18 y,
        UD60x18 a
    ) public view {
        require(x.neq(ZERO_FP) && y.neq(ZERO_FP));
        // todo this should probably be changed
        require(a.gt(convert(2 ** 32))); // to avoid massive loss of precision

        UD60x18 x_y = mul(x, y);
        UD60x18 xy_a = pow(x_y, a);

        UD60x18 x_a = pow(x, a);
        UD60x18 y_a = pow(y, a);

        assert(equal_within_precision(mul(x_a, y_a), xy_a, 10));
    }

    // @audit - fails
    // Test for result being greater than or lower than the argument, depending on
    // its value and the value of the exponent
    function pow_test_values(UD60x18 x, UD60x18 a) public view {
        require(x.neq(ZERO_FP));

        UD60x18 x_a = pow(x, a);

        if (x.gte(ONE_FP)) {
            assert(x_a.gte(ONE_FP));
        }

        if (x.lte(ONE_FP)) {
            assert(x_a.lte(ONE_FP));
        }
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // @audit-ok
    // Test for maximum base and exponent > 1
    function pow_test_maximum_base(UD60x18 a) public view {
        require(a.gt(ONE_FP));

        try this.helpersPow(MAX_UD60x18, a) {
            // Unexpected, should revert because of overflow
            assert(false);
        } catch {
            // Expected revert
        }
    }

    // Test for maximum exponent and base > 1
    function pow_test_maximum_exponent(UD60x18 x) public view {
        require(x.gt(ONE_FP));

        try this.helpersPow(x, MAX_PERMITTED_EXPONENT_POW) {
            // Unexpected, should revert because of overflow
            assert(false);
        } catch {
            // Expected revert
        }
    }

    // @audit Check 2**18
    // Test for base < 1 and high exponent
    function pow_test_high_exponent(UD60x18 x, UD60x18 a) public view {
        require(x.lt(ONE_FP) && a.gt(convert(2 ** 64)));

        UD60x18 result = pow(x, a);

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

    // @audit-ok
    // Test for the inverse operation
    // sqrt(x) * sqrt(x) == x
    function sqrt_test_inverse_mul(UD60x18 x) public view {
        UD60x18 sqrt_x = sqrt(x);
        UD60x18 sqrt_x_squared = mul(sqrt_x, sqrt_x);

        // Precision loss is at most half the bits of the operand
        assert(
            equal_within_precision(
                sqrt_x_squared,
                x,
                (intoUint256(log2(x)) >> 1) + 2
            )
        );
    }

    // @audit-ok
    // Test for the inverse operation
    // sqrt(x) ** 2 == x
    function sqrt_test_inverse_pow(UD60x18 x) public view {
        UD60x18 sqrt_x = sqrt(x);
        UD60x18 sqrt_x_squared = pow(sqrt_x, convert(2));

        // Precision loss is at most half the bits of the operand
        assert(
            equal_within_precision(
                sqrt_x_squared,
                x,
                (intoUint256(log2(x)) >> 1) + 2
            )
        );
    }

    // @audit check the precision
    // Test for distributive property respect to the multiplication
    // sqrt(x) * sqrt(y) == sqrt(x * y)
    function sqrt_test_distributive(UD60x18 x, UD60x18 y) public view {
        UD60x18 sqrt_x = sqrt(x);
        UD60x18 sqrt_y = sqrt(y);
        UD60x18 sqrt_x_sqrt_y = mul(sqrt_x, sqrt_y);
        UD60x18 sqrt_xy = sqrt(mul(x, y));

        // Ensure we have enough significant digits for the result to be meaningful
        require(significant_digits_after_mult(x, y) > REQUIRED_SIGNIFICANT_DIGITS);
        require(
            significant_digits_after_mult(sqrt_x, sqrt_y) >
                REQUIRED_SIGNIFICANT_DIGITS
        );

        // Allow an error of up to one tenth of a percent
        assert(equal_within_tolerance(sqrt_x_sqrt_y, sqrt_xy, ONE_TENTH_FP));
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // @audit-ok
    // Test for zero case
    function sqrt_test_zero() public view {
        assert(sqrt(ZERO_FP).eq(ZERO_FP));
    }

    // @audit-ok
    // Test for maximum value
    function sqrt_test_maximum() public view {
        try this.helpersSqrt(MAX_PERMITTED_SQRT) {
            // Expected behaviour, MAX_SQRT is positive, and operation
            // should not revert as the result is in range
        } catch {
            // Unexpected, should not revert
            assert(false);
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

    // @audit check loss
    // Test for distributive property respect to multiplication
    // log2(x * y) = log2(x) + log2(y)
    function log2_test_distributive_mul(UD60x18 x, UD60x18 y) public view {
        require(x.gte(UNIT) && y.gte(UNIT));
        
        UD60x18 log2_x = log2(x);
        UD60x18 log2_y = log2(y);
        UD60x18 log2_x_log2_y = add(log2_x, log2_y);

        UD60x18 xy = mul(x, y);
        UD60x18 log2_xy = log2(xy);

        // Ensure we have enough significant digits for the result to be meaningful
        require(significant_digits_after_mult(x, y) > REQUIRED_SIGNIFICANT_DIGITS);

        // The maximum loss of precision is given by the formula:
        // | log2(x) + log2(y) |
        uint256 loss = intoUint256(log2(x).add(log2(y)));

        assert(equal_within_precision(log2_x_log2_y, log2_xy, loss));
    }

    // @audit - fails
    // Test for logarithm of a power
    // log2(x ** y) = y * log2(x)
    function log2_test_power(UD60x18 x, UD60x18 y) public view {
        require(x.gte(UNIT) && y.gte(UNIT));

        UD60x18 x_y = pow(x, y);
        UD60x18 log2_x_y = log2(x_y);
        UD60x18 y_log2_x = mul(log2(x), y);

        assert(equal_within_precision(y_log2_x, log2_x_y, 4));
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // @audit-ok
    // Test for zero case, should revert
    function log2_test_zero() public view {
        try this.helpersLog2(ZERO_FP) {
            // Unexpected, should revert
            assert(false);
        } catch {
            // Expected revert, log(0) is not defined
        }
    }

    // @audit-ok
    // Test for maximum value case, should return a positive number
    function log2_test_maximum() public view {
        UD60x18 result;

        try this.helpersLog2(MAX_UD60x18) {
            // Expected, should not revert and the result must be > 0
            result = this.helpersLog2(MAX_UD60x18);
            assert(result.gt(ZERO_FP));
        } catch {
            // Unexpected
            assert(false);
        }
    }

    // @audit-ok
    // Test for values less than UNIT, should revert as result would be negative
    function log2_test_less_than_unit(UD60x18 x) public view {
        require(x.lt(UNIT));

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

    // @audit check precision
    // Test for distributive property respect to multiplication
    // ln(x * y) = ln(x) + ln(y)
    function ln_test_distributive_mul(UD60x18 x, UD60x18 y) public view {
        require(x.gte(UNIT) && y.gte(UNIT));

        UD60x18 ln_x = ln(x);
        UD60x18 ln_y = ln(y);
        UD60x18 ln_x_ln_y = add(ln_x, ln_y);

        UD60x18 xy = mul(x, y);
        UD60x18 ln_xy = ln(xy);

        require(significant_digits_after_mult(x, y) > REQUIRED_SIGNIFICANT_DIGITS);

        // The maximum loss of precision is given by the formula:
        // | log2(x) + log2(y) |
        uint256 loss = intoUint256(log2(x).add(log2(y)));

        assert(equal_within_precision(ln_x_ln_y, ln_xy, loss));
    }

    // @audit check precision
    // Test for logarithm of a power
    // ln(x ** y) = y * ln(x)
    function ln_test_power(UD60x18 x, UD60x18 y) public {
        require(x.gte(UNIT));
        UD60x18 x_y = pow(x, y);
        UD60x18 ln_x_y = ln(x_y);
        UD60x18 y_ln_x = mul(ln(x), y);

        assert(equal_within_precision(ln_x_y, y_ln_x, 4));
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // @audit-ok
    // Test for zero case, should revert
    function ln_test_zero() public view {
        try this.helpersLn(ZERO_FP) {
            // Unexpected, should revert
            assert(false);
        } catch {
            // Expected revert, log(0) is not defined
        }
    }

    // @audit-ok
    // Test for maximum value case, should return a positive number
    function ln_test_maximum() public view {
        UD60x18 result;

        try this.helpersLn(MAX_UD60x18) {
            // Expected, should not revert and the result must be > 0
            result = this.helpersLn(MAX_UD60x18);
            assert(result.gt(ZERO_FP));
        } catch {
            // Unexpected
            assert(false);
        }
    }

    // @audit-ok
    // Test for values less than UNIT, should revert since result would be negative
    function ln_test_less_than_unit(UD60x18 x) public view {
        require(x.lt(UNIT));

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

    // @audit-ok
    // Test for equality with pow(2, x) for integer x
    // pow(2, x) == exp2(x)
    function exp2_test_equivalence_pow(UD60x18 x) public view {
        require(x.lte(convert(192)));
        UD60x18 exp2_x = exp2(x);
        UD60x18 pow_2_x = pow(TWO_FP, x);

        assert(exp2_x.eq(pow_2_x));
    }

    // @audit - fails
    // Test for inverse function
    // If y = log2(x) then exp2(y) == x
    function exp2_test_inverse(UD60x18 x) public view {
        UD60x18 log2_x = log2(x);
        UD60x18 exp2_x = exp2(log2_x);

        // todo is this the correct number of bits?
        uint256 bits = 18;

        assert(equal_most_significant_digits_within_precision(x, exp2_x, bits));
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // @audit-ok
    // Test for zero case
    // exp2(0) == 1
    function exp2_test_zero() public view {
        UD60x18 exp_zero = exp2(ZERO_FP);
        assert(exp_zero.eq(ONE_FP));
    }

    // @audit-ok
    // Test for maximum value. This should overflow as it won't fit
    // in the data type
    function exp2_test_maximum() public view {
        try this.helpersExp2(convert(192)) {
            // Unexpected, should revert
            assert(false);
        } catch {
            // Expected revert
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

    // @audit - fails
    // Test for inverse function
    // If y = ln(x) then exp(y) == x
    function exp_test_inverse(UD60x18 x) public view {
        UD60x18 ln_x = ln(x);
        UD60x18 exp_x = exp(ln_x);
        UD60x18 log2_x = log2(x);

        uint256 bits = 18;

        assert(equal_most_significant_digits_within_precision(x, exp_x, bits));
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // @audit-ok
    // Test for zero case
    // exp(0) == 1
    function exp_test_zero() public view {
        UD60x18 exp_zero = exp(ZERO_FP);
        assert(exp_zero.eq(ONE_FP));
    }

    // @audit-ok
    // Test for maximum value. This should overflow as it won't fit
    // in the data type
    function exp_test_maximum() public view {
        try this.helpersExp(convert(192)) {
            // Unexpected, should revert
            assert(false);
        } catch {
            // Expected revert
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

    // @audit-ok
    // Test for zero exponent
    // x ** 0 == 1
    function powu_test_zero_exponent(UD60x18 x) public view {
        UD60x18 x_pow_0 = powu(x, 0);

        assert(x_pow_0.eq(ONE_FP));
    }

    // @audit-ok
    // Test for zero base
    // 0 ** x == 0
    function powu_test_zero_base(uint256 a) public view {
        require(a != 0);

        UD60x18 zero_pow_a = powu(ZERO_FP, a);

        assert(zero_pow_a.eq(ZERO_FP));
    }

    // @audit-ok
    // Test for exponent one
    // x ** 1 == x
    function powu_test_one_exponent(UD60x18 x) public view {
        UD60x18 x_pow_1 = powu(x, 1);

        assert(x_pow_1.eq(x));
    }

    // @audit-ok
    // Test for base one
    // 1 ** x == 1
    function powu_test_base_one(uint256 a) public view {
        UD60x18 one_pow_a = powu(ONE_FP, a);

        assert(one_pow_a.eq(ONE_FP));
    }

    // @audit - Fails
    // Test for product of powers of the same base
    // x ** a * x ** b == x ** (a + b)
    function powu_test_product_same_base(
        UD60x18 x,
        uint256 a,
        uint256 b
    ) public view {
        require(x.neq(ZERO_FP));

        UD60x18 x_a = powu(x, a);
        UD60x18 x_b = powu(x, b);
        UD60x18 x_ab = powu(x, a + b);

        assert(equal_within_precision(mul(x_a, x_b), x_ab, 10));
    }

    // @audit - fails
    // Test for power of an exponentiation
    // (x ** a) ** b == x ** (a * b)
    function powu_test_power_of_an_exponentiation(
        UD60x18 x,
        uint256 a,
        uint256 b
    ) public view {
        require(x.neq(ZERO_FP));

        UD60x18 x_a = powu(x, a);
        UD60x18 x_a_b = powu(x_a, b);
        UD60x18 x_ab = powu(x, a * b);

        assert(equal_within_precision(x_a_b, x_ab, 10));
    }

    // @audit check precision
    // Test for power of a product
    // (x * y) ** a == x ** a * y ** a
    function powu_test_product_power(
        UD60x18 x,
        UD60x18 y,
        uint256 a
    ) public view {
        require(x.neq(ZERO_FP) && y.neq(ZERO_FP));
        // todo this should probably be changed
        require(a > 2 ** 32); // to avoid massive loss of precision

        UD60x18 x_y = mul(x, y);
        UD60x18 xy_a = powu(x_y, a);

        UD60x18 x_a = powu(x, a);
        UD60x18 y_a = powu(y, a);

        assert(equal_within_precision(mul(x_a, y_a), xy_a, 10));
    }

    // @audit - fails
    // Test for result being greater than or lower than the argument, depending on
    // its value and the value of the exponent
    function powu_test_values(UD60x18 x, uint256 a) public view {
        require(x.neq(ZERO_FP));

        UD60x18 x_a = powu(x, a);

        if (x.gte(ONE_FP)) {
            assert(x_a.gte(ONE_FP));
        }

        if (x.lte(ONE_FP)) {
            assert(x_a.lte(ONE_FP));
        }
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */


    // @audit-ok
    // Test for maximum base and exponent > 1
    function powu_test_maximum_base(uint256 a) public view {
        require(a > 1);

        try this.helpersPowu(MAX_UD60x18, a) {
            // Unexpected, should revert because of overflow
            assert(false);
        } catch {
            // Expected revert
        }
    }

    // @audit Check 2**64
    // Test for base < 1 and high exponent
    function powu_test_high_exponent(UD60x18 x, uint256 a) public view {
        require(x.lt(ONE_FP) && a > 2 ** 64);

        UD60x18 result = powu(x, a);

        assert(result.eq(ZERO_FP));
    }

    /* ================================================================

                        TESTS FOR FUNCTION log10()

       ================================================================ */

    /* ================================================================
       Tests for arithmetic properties.
       These should make sure that the implemented function complies
       with math rules and expected behaviour.
       ================================================================ */

    // @audit check loss
    // Test for distributive property respect to multiplication
    // log10(x * y) = log10(x) + log10(y)
    function log10_test_distributive_mul(UD60x18 x, UD60x18 y) public view {
        require(x.gte(UNIT) && y.gte(UNIT));
        UD60x18 log10_x = log10(x);
        UD60x18 log10_y = log10(y);
        UD60x18 log10_x_log10_y = add(log10_x, log10_y);

        UD60x18 xy = mul(x, y);
        UD60x18 log10_xy = log10(xy);

        // Ensure we have enough significant digits for the result to be meaningful
        require(significant_digits_after_mult(x, y) > REQUIRED_SIGNIFICANT_DIGITS);

        // The maximum loss of precision is given by the formula:
        // | log10(x) + log10(y) |
        uint256 loss = intoUint256(log10(x).add(log10(y)));

        assert(equal_within_precision(log10_x_log10_y, log10_xy, loss));
    }

    // @audit - fails
    // Test for logarithm of a power
    // log10(x ** y) = y * log10(x)
    function log10_test_power(UD60x18 x, UD60x18 y) public {
        require(x.gte(UNIT) && y.gte(UNIT));
        UD60x18 x_y = pow(x, y);
        UD60x18 log10_x_y = log10(x_y);
        UD60x18 y_log10_x = mul(log10(x), y);

        if(!equal_within_precision(log10_x_y, y_log10_x, 18)){
            emit AssertionFailed(log10_x_y, y_log10_x);
        }

        assert(equal_within_precision(log10_x_y, y_log10_x, 10));
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // @audit-ok
    // Test for zero case, should revert
    function log10_test_zero() public view {
        try this.helpersLog10(ZERO_FP) {
            // Unexpected, should revert
            assert(false);
        } catch {
            // Expected revert, log(0) is not defined
        }
    }

    // @audit-ok
    // Test for maximum value case, should return a positive number
    function log10_test_maximum() public view {
        UD60x18 result;

        try this.helpersLog10(MAX_UD60x18) {
            // Expected, should not revert and the result must be > 0
            result = this.helpersLog10(MAX_UD60x18);
            assert(result.gt(ZERO_FP));
        } catch {
            // Unexpected
            assert(false);
        }
    }

    // @audit-ok
    // Test for values less than UNIT, should revert as result would be negative
    function log10_test_less_than_unit(UD60x18 x) public view {
        require(x.lt(UNIT));

        try this.helpersLog10(x) {
            // Unexpected, should revert
            assert(false);
        } catch {
            // Expected
        }
    }

}