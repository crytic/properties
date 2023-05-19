pragma solidity ^0.8.19;

import { UD60x18 } from "@prb/math/UD60x18.sol";
import {add, sub, eq, gt, gte, lt, lte, lshift, rshift} from "@prb/math/ud60x18/Helpers.sol";
import {convert} from "@prb/math/ud60x18/Conversions.sol";
import {msb} from "@prb/math/Common.sol";
import {intoUint128, intoUint256} from "@prb/math/ud60x18/Casting.sol";
import {mul, div, ln, exp, exp2, log2, sqrt, pow, avg, inv, log10, floor, powu, gm} from "@prb/math/ud60x18/Math.sol";
import "./utils/AssertionHelperUD.sol";

contract CryticPRBMath60x18Propertiesv4 is AssertionHelperUD {

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
    UD60x18 internal constant MAX_PERMITTED_POW = UD60x18.wrap(2 ** 192 * 10 ** 18 - 1);
    UD60x18 internal constant MAX_PERMITTED_SQRT = UD60x18.wrap(115792089237316195423570985008687907853269_984665640564039457);

    /* ================================================================
       Events used for debugging or showing information.
       ================================================================ */
    event Value(string reason, UD60x18 val);
    event LogErr(bytes error);

    /* ================================================================
       Library wrappers.
       These functions allow calling the PRBMathUD60x18 library.
       ================================================================ */
    function debug(string calldata x, UD60x18 y) public {
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

    function helpersGm(UD60x18 x, UD60x18 y) public pure returns (UD60x18) {
        return gm(x, y);
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
    function add_test_commutative(UD60x18 x, UD60x18 y) public {
        UD60x18 x_y = x.add(y);
        UD60x18 y_x = y.add(x);

        assertEq(x_y, y_x);
    }

    // Test for associative property
    // (x + y) + z == x + (y + z)
    function add_test_associative(UD60x18 x, UD60x18 y, UD60x18 z) public {
        UD60x18 x_y = x.add(y);
        UD60x18 y_z = y.add(z);
        UD60x18 xy_z = x_y.add(z);
        UD60x18 x_yz = x.add(y_z);

        assertEq(xy_z, x_yz);
    }

    // Test for identity operation
    // x + 0 == x (equivalent to x + (-x) == 0)
    function add_test_identity(UD60x18 x) public {
        UD60x18 x_0 = x.add(ZERO_FP);

        assertEq(x, x_0);
        assertEq(x.sub(x), ZERO_FP);
    }

    // Test that the result increases or decreases depending
    // on the value to be added
    function add_test_values(UD60x18 x, UD60x18 y) public {
        UD60x18 x_y = x.add(y);

        assertGte(x_y, x);
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These should make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // The result of the addition must be between the maximum
    // and minimum allowed values for UD60x18
    function add_test_range(UD60x18 x, UD60x18 y) public {
        try this.helpersAdd(x, y) returns (UD60x18 result) {
            assert(result.lte(MAX_UD60x18) && result.gte(ZERO_FP));
        } catch {
            // If it reverts, just ignore
        }
    }

    // Adding zero to the maximum value shouldn't revert, as it is valid
    // Moreover, the result must be MAX_UD60x18
    function add_test_maximum_value() public {
        try this.helpersAdd(MAX_UD60x18, ZERO_FP) returns (UD60x18 result) {
            // Expected behaviour, does not revert
            assertEq(result, MAX_UD60x18);
        } catch {
            assert(false);
        }
    }

    // Adding one to the maximum value should revert, as it is out of range
    function add_test_maximum_value_plus_one() public {
        try this.helpersAdd(MAX_UD60x18, ONE_FP) {
            assert(false);
        } catch {
            // Expected behaviour, reverts
        }
    }

    // Adding zero to the minimum value shouldn't revert, as it is valid
    // Moreover, the result must be MIN_UD60x18
    function add_test_minimum_value() public {
        try this.helpersAdd(ZERO_FP, ZERO_FP) returns (UD60x18 result) {
            // Expected behaviour, does not revert
            assertEq(result, ZERO_FP);
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

    // Test for identity operation
    // x - 0 == x  (equivalent to x - x == 0)
    function sub_test_identity(UD60x18 x) public {
        UD60x18 x_0 = x.sub(ZERO_FP);

        assertEq(x_0, x);
        assertEq(x.sub(x), ZERO_FP);
    }

    // Test for neutrality over addition and subtraction
    // (x - y) + y == (x + y) - y == x
    function sub_test_neutrality(UD60x18 x, UD60x18 y) public {
        UD60x18 x_minus_y = x.sub(y);
        UD60x18 x_plus_y = x.add(y);

        UD60x18 x_minus_y_plus_y = x_minus_y.add(y);
        UD60x18 x_plus_y_minus_y = x_plus_y.sub(y);
        
        assertEq(x_minus_y_plus_y, x_plus_y_minus_y);
        assertEq(x_minus_y_plus_y, x);
    }

    // Test that the result always decreases
    function sub_test_values(UD60x18 x, UD60x18 y) public {
        UD60x18 x_y = x.sub(y);

        assertLte(x_y, x);
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // The result of the subtraction must be between the maximum
    // and minimum allowed values for UD60x18
    function sub_test_range(UD60x18 x, UD60x18 y) public {
        try this.helpersSub(x, y) returns (UD60x18 result) {
            assert(result.lte(MAX_UD60x18) && result.gte(ZERO_FP));
        } catch {
            // If it reverts, just ignore
        }
    }

    // Subtracting zero from the maximum value shouldn't revert, as it is valid
    // Moreover, the result must be MAX_UD60x18
    function sub_test_maximum_value() public {
        try this.helpersSub(MAX_UD60x18, ZERO_FP) returns (UD60x18 result) {
            // Expected behaviour, does not revert
            assertEq(result, MAX_UD60x18);
        } catch {
            assert(false);
        }
    }

    // Subtracting zero from the minimum value shouldn't revert, as it is valid
    // Moreover, the result must be MIN_UD60x18
    function sub_test_minimum_value() public {
        try this.helpersSub(ZERO_FP, ZERO_FP) returns (UD60x18 result) {
            // Expected behaviour, does not revert
            assertEq(result, ZERO_FP);
        } catch {
            assert(false);
        }
    }

    // Subtracting one from the minimum value should revert, as it is out of range
    function sub_test_minimum_value_minus_one() public {
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

    // Test for commutative property
    // x * y == y * x
    function mul_test_commutative(UD60x18 x, UD60x18 y) public {
        UD60x18 x_y = x.mul(y);
        UD60x18 y_x = y.mul(x);

        assertEq(x_y, y_x);
    }

    // Test for associative property
    // (x * y) * z == x * (y * z)
    function mul_test_associative(UD60x18 x, UD60x18 y, UD60x18 z) public {
        UD60x18 x_y = x.mul(y);
        UD60x18 y_z = y.mul(z);
        UD60x18 xy_z = x_y.mul(z);
        UD60x18 x_yz = x.mul(y_z);

        require(xy_z.neq(ZERO_FP) && x_yz.neq(ZERO_FP));
        assertEqWithinTolerance(xy_z, x_yz, ONE_TENTH_FP, "0.1%");
    }

    // Test for distributive property
    // x * (y + z) == x * y + x * z
    function mul_test_distributive(UD60x18 x, UD60x18 y, UD60x18 z) public {
        UD60x18 y_plus_z = y.add(z);
        UD60x18 x_times_y_plus_z = x.mul(y_plus_z);

        UD60x18 x_times_y = x.mul(y);
        UD60x18 x_times_z = x.mul(z);

        assertEqWithinTolerance(add(x_times_y, x_times_z), x_times_y_plus_z, ONE_TENTH_FP, "0.1%");
    }

    // Test for identity operation
    // x * 1 == x  (also check that x * 0 == 0)
    function mul_test_identity(UD60x18 x) public {
        UD60x18 x_1 = x.mul(ONE_FP);
        UD60x18 x_0 = x.mul(ZERO_FP);

        assertEq(x_0, ZERO_FP);
        assertEq(x_1, x);
    }

    // Test that the result increases or decreases depending
    // on the value to be added
    function mul_test_values(UD60x18 x, UD60x18 y) public {
        UD60x18 x_y = x.mul(y);

        if (y.gte(ONE_FP)) {
            assertGte(x_y, x);
        } else {
            assertLte(x_y, x);
        }
    }
    
    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // The result of the multiplication must be between the maximum
    // and minimum allowed values for UD60x18
    function mul_test_range(UD60x18 x, UD60x18 y) public {
        try this.helpersMul(x, y) returns(UD60x18 result) {
            assertLte(result, MAX_UD60x18);
        } catch {
            // If it reverts, just ignore
        }
    }

    // Multiplying the maximum value times one shouldn't revert, as it is valid
    // Moreover, the result must be MAX_UD60x18
    function mul_test_maximum_value() public {
        try this.helpersMul(MAX_UD60x18, ONE_FP) returns (UD60x18 result) {
            // Expected behaviour, does not revert
            assertEq(result, MAX_UD60x18);
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
    function div_test_division_identity_x_div_1(UD60x18 x) public {
        UD60x18 div_1 = div(x, ONE_FP);
        
        assertEq(x, div_1);
    }

    // Test for identity property
    // x/x should not revert unless x == 0
    function div_test_division_identity_x_div_x(UD60x18 x) public {
        UD60x18 div_x;

        try this.helpersDiv(x, x) {
            // This should always equal one
            div_x = div(x, x);
            assertEq(div_x, ONE_FP);
        } catch {
            // Only valid case for revert is x == 0
            assertEq(x, ZERO_FP);
        }
    }

    // Test for division with 0 as numerator
    // 0 / x = 0
    function div_test_division_num_zero(UD60x18 y) public {
        require(y.neq(ZERO_FP));

        UD60x18 div_0 = div(ZERO_FP, y);

        assertEq(ZERO_FP, div_0);
    }

    // Test that the value of the result increases or
    // decreases depending on the denominator's value
    function div_test_values(UD60x18 x, UD60x18 y) public {
        require(y.neq(ZERO_FP));

        UD60x18 x_y = div(x, y);

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

    // Test for division by zero
    function div_test_div_by_zero(UD60x18 x) public {
        try this.helpersDiv(x, ZERO_FP) {
            // Unexpected, this should revert
            assert(false);
        } catch {
            // Expected revert
        }
    }

    // Test for division by a large value, the result should be less than one
    function div_test_maximum_denominator(UD60x18 x) public {
        UD60x18 div_large = div(x, MAX_UD60x18);

        assertLte(div_large, ONE_FP);
    }

    // Test for division of a large value
    // This should revert if |y| < 1 as it would return a value higher than max
    function div_test_maximum_numerator(UD60x18 y) public {
        require(y.neq(ZERO_FP));
        UD60x18 div_large;

        try this.helpersDiv(MAX_UD60x18, y) {
            // If it didn't revert, then |y| >= 1
            div_large = div(MAX_UD60x18, y);

            assertGte(y, ONE_FP);
        } catch {
            // Expected revert as result is higher than max
        }
    }

    // Test for values in range
    function div_test_range(UD60x18 x, UD60x18 y) public {
        require(y.neq(ZERO_FP));
        UD60x18 result;

        try this.helpersDiv(x, y) {
            // If it returns a value, it must be in range
            result = div(x, y);
            assertLte(result, MAX_UD60x18);
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

    // Test that the inverse of the inverse is close enough to the
    // original number
    function inv_test_double_inverse(UD60x18 x) public {
        require(x.neq(ZERO_FP));

        UD60x18 double_inv_x = inv(inv(x));

        // The maximum loss of precision will be 2 * log2(x) bits rounded up
        uint256 loss = 2 * intoUint256(log2(x)) + 2;

        assertEqWithinBitPrecision(x, double_inv_x, loss);
    }

    // Test equivalence with division
    function inv_test_division(UD60x18 x) public {
        require(x.neq(ZERO_FP));

        UD60x18 inv_x = inv(x);
        UD60x18 div_1_x = div(ONE_FP, x);

        assertEq(inv_x, div_1_x);
    }

    // Test the anticommutativity of the division
    // x / y == 1 / (y / x)
    function inv_test_division_noncommutativity(
        UD60x18 x,
        UD60x18 y
    ) public {
        require(x.neq(ZERO_FP) && y.neq(ZERO_FP));

        UD60x18 x_y = div(x, y);
        UD60x18 y_x = div(y, x);

        assertEqWithinTolerance(x_y, inv(y_x), ONE_TENTH_FP, "0.1%");
    }

    // Test the multiplication of inverses
    // 1/(x * y) == 1/x * 1/y
    function inv_test_multiplication(UD60x18 x, UD60x18 y) public {
        require(x.neq(ZERO_FP) && y.neq(ZERO_FP));

        UD60x18 inv_x = inv(x);
        UD60x18 inv_y = inv(y);
        UD60x18 inv_x_times_inv_y = mul(inv_x, inv_y);

        UD60x18 x_y = mul(x, y);
        UD60x18 inv_x_y = inv(x_y);

        // The maximum loss of precision is given by the formula:
        // 2 * | log2(x) - log2(y) | + 1
        uint256 loss = 2 * intoUint256(log2(x).sub(log2(y))) + 1;

        assertEqWithinBitPrecision(inv_x_y, inv_x_times_inv_y, loss);
    }

    // Test multiplicative identity property
    function inv_test_identity(UD60x18 x) public {
        require(x.neq(ZERO_FP));

        UD60x18 inv_x = inv(x);
        UD60x18 identity = mul(inv_x, x);

        require(inv_x.neq(ZERO_FP) && identity.neq(ZERO_FP));

        // They should agree with a tolerance of one tenth of a percent
        assertEqWithinTolerance(identity, ONE_FP, ONE_TENTH_FP, "0.1%");
    }

    // Test that the value of the result is in range zero-one
    // if x is greater than one, else, the value of the result
    // must be greater than one
    function inv_test_values(UD60x18 x) public {
        require(x.neq(ZERO_FP));

        UD60x18 inv_x = inv(x);

        if (x.gte(ONE_FP)) {
            assertLte(inv_x, ONE_FP);
        } else {
            assertGt(inv_x, ONE_FP);
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
        UD60x18 inv_maximum;

        try this.helpersInv(MAX_UD60x18) {
            inv_maximum = this.helpersInv(MAX_UD60x18);
            assertEqWithinBitPrecision(inv_maximum, ZERO_FP, 10);
        } catch {
            // Unexpected, the function must not revert
            assert(false);
        }
    }

    // Test the minimum value case, should not revert, and be close to 1e36
    function inv_test_minimum() public {
        UD60x18 inv_minimum;

        try this.helpersInv(UD60x18.wrap(1)) {
            inv_minimum = this.helpersInv(UD60x18.wrap(1));
            assertEqWithinBitPrecision(inv_minimum, UD60x18.wrap(1e36), 10);
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
    function avg_test_values_in_range(UD60x18 x, UD60x18 y) public {
        UD60x18 avg_xy = avg(x, y);

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
    function avg_test_one_value(UD60x18 x) public {
        UD60x18 avg_x = avg(x, x);

        assertEq(avg_x, x);
    }

    // Test that the order of operands is irrelevant
    // avg(x, y) == avg(y, x)
    function avg_test_operand_order(UD60x18 x, UD60x18 y) public {
        UD60x18 avg_xy = avg(x, y);
        UD60x18 avg_yx = avg(y, x);

        assertEq(avg_xy, avg_yx);
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // Test for the maximum value
    function avg_test_maximum() public {
        UD60x18 result;

        // This may revert due to overflow depending on implementation
        // If it doesn't revert, the result must be MAX_UD60x18
        try this.helpersAvg(MAX_UD60x18, MAX_UD60x18) {
            result = this.helpersAvg(MAX_UD60x18, MAX_UD60x18);
            assertEq(result, MAX_UD60x18);
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
    function pow_test_zero_exponent(UD60x18 x) public {
        require(x.lte(MAX_PERMITTED_POW));
        UD60x18 x_pow_0 = pow(x, ZERO_FP);

        assertEq(x_pow_0, ONE_FP);
    }

    // Test for zero base
    // 0 ** y == 0 (for positive y)
    function pow_test_zero_base(UD60x18 y) public {
        require(y.lte(MAX_PERMITTED_POW));
        require(y.neq(ZERO_FP));

        UD60x18 zero_pow_y = pow(ZERO_FP, y);

        assertEq(zero_pow_y, ZERO_FP);
    }

    // Test for exponent one
    // x ** 1 == x
    function pow_test_one_exponent(UD60x18 x) public {
        require(x.lte(MAX_PERMITTED_POW));
        UD60x18 x_pow_1 = pow(x, ONE_FP);

        assertEq(x_pow_1, x);
    }

    // Test for base one
    // 1 ** y == 1
    function pow_test_base_one(UD60x18 y) public {
        UD60x18 one_pow_y = pow(ONE_FP, y);

        assertEq(one_pow_y, ONE_FP);
    }

    // Test for product of powers of the same base
    // x ** a * x ** b == x ** (a + b)
    function pow_test_product_same_base(
        UD60x18 x,
        UD60x18 a,
        UD60x18 b
    ) public {
        require(x.neq(ZERO_FP));
        require(x.lte(MAX_PERMITTED_POW));

        UD60x18 x_a = pow(x, a);
        UD60x18 x_b = pow(x, b);
        UD60x18 x_ab = pow(x, a.add(b));

        assertEqWithinDecimalPrecision(mul(x_a, x_b), x_ab, 9);
    }

    // Test for power of an exponentiation
    // (x ** a) ** b == x ** (a * b)
    function pow_test_power_of_an_exponentiation(
        UD60x18 x,
        UD60x18 a,
        UD60x18 b
    ) public {
        require(x.neq(ZERO_FP));
        require(x.lte(MAX_PERMITTED_POW));

        UD60x18 x_a = pow(x, a);
        UD60x18 x_a_b = pow(x_a, b);
        UD60x18 x_ab = pow(x, a.mul(b));

        assertEqWithinDecimalPrecision(x_a_b, x_ab, 9);
    }

    // Test for power of a product
    // (x * y) ** a == x ** a * y ** a
    function pow_test_product_power(
        UD60x18 x,
        UD60x18 y,
        UD60x18 a
    ) public {
        require(x.lte(MAX_PERMITTED_POW));
        require(x.neq(ZERO_FP) && y.neq(ZERO_FP));
        require(a.gt(UD60x18.wrap(1e9))); // to avoid massive loss of precision

        UD60x18 x_y = mul(x, y);
        UD60x18 xy_a = pow(x_y, a);

        UD60x18 x_a = pow(x, a);
        UD60x18 y_a = pow(y, a);

        assertEqWithinDecimalPrecision(mul(x_a, y_a), xy_a, 9);
    }

    // Test for result being greater than or lower than the argument, depending on
    // its value and the value of the exponent
    function pow_test_values(UD60x18 x, UD60x18 a) public {
        require(x.neq(ZERO_FP));
        require(x.lte(MAX_PERMITTED_POW));

        UD60x18 x_a = pow(x, a);

        if (x.gte(ONE_FP)) {
            assertGte(x_a, ONE_FP);
        }

        if (x.lte(ONE_FP)) {
            assertLte(x_a, ONE_FP);
        }
    }

    // Power is strictly increasing
    // x > y && a >= 0 --> pow(x) >= pow(y)
    function pow_test_strictly_increasing(UD60x18 x, UD60x18 y, UD60x18 a) public {
        require(x.gt(y) && x.lte(MAX_PERMITTED_POW));
        require(a.gte(ZERO_FP));

        UD60x18 x_a = pow(x, a);
        UD60x18 y_a = pow(y, a);

        assertGte(x_a, y_a);
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // Test for maximum base and exponent > 1
    function pow_test_maximum_base(UD60x18 a) public {
        require(a.gt(ONE_FP));

        try this.helpersPow(MAX_UD60x18, a) {
            // Unexpected, should revert because of overflow
            assert(false);
        } catch {
            // Expected revert
        }
    }

    // Test for maximum exponent and base > 1
    function pow_test_maximum_exponent(UD60x18 x) public {
        require(x.gt(ONE_FP));
        require(x.lte(MAX_PERMITTED_POW));

        try this.helpersPow(x, MAX_PERMITTED_POW) {
            // Unexpected, should revert because of overflow
            assert(false);
        } catch {
            // Expected revert
        }
    }

    // Test for base < 1 and high exponent
    function pow_test_high_exponent(UD60x18 x, UD60x18 a) public {
        require(x.lt(ONE_FP) && a.gt(convert(2 ** 64)));

        UD60x18 result = pow(x, a);

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
    function sqrt_test_inverse_mul(UD60x18 x) public {
        require(x.lte(MAX_PERMITTED_SQRT));
        UD60x18 sqrt_x = sqrt(x);
        UD60x18 sqrt_x_squared = mul(sqrt_x, sqrt_x);

        // Precision loss is at most half the bits of the operand
        assertEqWithinBitPrecision(sqrt_x_squared, x, (intoUint256(log2(x)) >> 1) + 2);
    }

    // Test for the inverse operation
    // sqrt(x) ** 2 == x
    function sqrt_test_inverse_pow(UD60x18 x) public {
        require(x.lte(MAX_PERMITTED_SQRT));
        UD60x18 sqrt_x = sqrt(x);
        UD60x18 sqrt_x_squared = pow(sqrt_x, convert(2));

        // Precision loss is at most half the bits of the operand
        assertEqWithinBitPrecision(sqrt_x_squared, x, (intoUint256(log2(x)) >> 1) + 2);
    }

    // Test for distributive property respect to the multiplication
    // sqrt(x) * sqrt(y) == sqrt(x * y)
    function sqrt_test_distributive(UD60x18 x, UD60x18 y) public {
        require(x.lte(MAX_PERMITTED_SQRT) && y.lte(MAX_PERMITTED_SQRT));
        UD60x18 sqrt_x = sqrt(x);
        UD60x18 sqrt_y = sqrt(y);
        UD60x18 sqrt_x_sqrt_y = mul(sqrt_x, sqrt_y);
        UD60x18 sqrt_xy = sqrt(mul(x, y));

        // Allow an error of up to one tenth of a percent
        assertEqWithinTolerance(sqrt_x_sqrt_y, sqrt_xy, ONE_TENTH_FP, "0.1%");
    }

    // Test that sqrt is strictly increasing
    // x >= 0 && y > x --> sqrt(y) >= sqrt(x)
    function sqrt_test_strictly_increasing(UD60x18 x, UD60x18 y) public {
        require(y.gt(x));

        UD60x18 sqrt_x = sqrt(x);
        UD60x18 sqrt_y = sqrt(y);

        assertGte(sqrt_y, sqrt_x);
    }

    // Square root of perfect square should be equal to x
    // sqrt(x * x) == x
    function sqrt_test_square(UD60x18 x) public {
        require(x.gt(ONE_FP));

        UD60x18 square_x = x.mul(x);
        UD60x18 sqrt_square_x = sqrt(square_x);

        assertEq(sqrt_square_x, x);
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

    // Test for distributive property respect to multiplication
    // log2(x * y) = log2(x) + log2(y)
    function log2_test_distributive_mul(UD60x18 x, UD60x18 y) public {
        require(x.gte(UNIT) && y.gte(UNIT));
        
        UD60x18 log2_x = log2(x);
        UD60x18 log2_y = log2(y);
        UD60x18 log2_x_log2_y = add(log2_x, log2_y);

        UD60x18 xy = mul(x, y);
        UD60x18 log2_xy = log2(xy);

        // The maximum loss of precision is given by the formula:
        // | log2(x) + log2(y) |
        uint256 loss = intoUint256(log2(x).add(log2(y)));

        assertEqWithinBitPrecision(log2_x_log2_y, log2_xy, loss);
    }

    // Test for logarithm of a power
    // log2(x ** y) = y * log2(x)
    function log2_test_power(UD60x18 x, UD60x18 y) public {
        require(x.gte(UNIT) && y.gte(UNIT));

        UD60x18 x_y = pow(x, y);
        UD60x18 log2_x_y = log2(x_y);
        UD60x18 y_log2_x = mul(log2(x), y);

        assertEqWithinTolerance(y_log2_x, log2_x_y, ONE_TENTH_FP, "0.1%");
    }

    // Base 2 logarithm is strictly increasing
    // y > 0 && x > y --> log2(x) > log2(y)
    function log2_test_strictly_increasing(UD60x18 x, UD60x18 y) public {
        require(y.gt(ZERO_FP) && x.gt(y));
        
        UD60x18 log2_x = log2(x);
        UD60x18 log2_y = log2(y);

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
        UD60x18 result;

        try this.helpersLog2(MAX_UD60x18) {
            // Expected, should not revert and the result must be > 0
            result = this.helpersLog2(MAX_UD60x18);
            assertGt(result, ZERO_FP);
        } catch {
            // Unexpected
            assert(false);
        }
    }

    // Test for values less than UNIT, should revert as result would be negative
    function log2_test_less_than_unit(UD60x18 x) public {
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

    // Test for distributive property respect to multiplication
    // ln(x * y) = ln(x) + ln(y)
    function ln_test_distributive_mul(UD60x18 x, UD60x18 y) public {
        require(x.gte(UNIT) && y.gte(UNIT));

        UD60x18 ln_x = ln(x);
        UD60x18 ln_y = ln(y);
        UD60x18 ln_x_ln_y = add(ln_x, ln_y);

        UD60x18 xy = mul(x, y);
        UD60x18 ln_xy = ln(xy);

        // The maximum loss of precision is given by the formula:
        // | log2(x) + log2(y) |
        uint256 loss = intoUint256(log2(x).add(log2(y)));
        assertEqWithinBitPrecision(ln_x_ln_y, ln_xy, loss);
    }

    // Test for logarithm of a power
    // ln(x ** y) = y * ln(x)
    function ln_test_power(UD60x18 x, UD60x18 y) public {
        require(x.gte(UNIT));
        UD60x18 x_y = pow(x, y);
        UD60x18 ln_x_y = ln(x_y);
        UD60x18 y_ln_x = mul(ln(x), y);

        assertEqWithinDecimalPrecision(ln_x_y, y_ln_x, 9);
    }

    // Natural logarithm is strictly increasing
    // y > 0 && x > y --> log2(x) > log2(y)
    function ln_test_strictly_increasing(UD60x18 x, UD60x18 y) public {
        require(y.gt(ZERO_FP) && x.gt(y));
        
        UD60x18 ln_x = ln(x);
        UD60x18 ln_y = ln(y);

        assertGte(ln_x, ln_y);
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
        UD60x18 result;

        try this.helpersLn(MAX_UD60x18) {
            // Expected, should not revert and the result must be > 0
            result = this.helpersLn(MAX_UD60x18);
            assertGt(result, ZERO_FP);
        } catch {
            // Unexpected
            assert(false);
        }
    }

    // Test for values less than UNIT, should revert since result would be negative
    function ln_test_less_than_unit(UD60x18 x) public {
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

    // Test for equality with pow(2, x) for integer x
    // pow(2, x) == exp2(x)
    function exp2_test_equivalence_pow(UD60x18 x) public {
        require(x.lte(MAX_PERMITTED_EXP2));
        UD60x18 exp2_x = exp2(x);
        UD60x18 pow_2_x = pow(TWO_FP, x);

        assertEq(exp2_x, pow_2_x);
    }

    // Test for inverse function
    // If y = log2(x) then exp2(y) == x
    function exp2_test_inverse(UD60x18 x) public {
        require(x.gte(UNIT));
        UD60x18 log2_x = log2(x);
        require(log2_x.lte(MAX_PERMITTED_EXP2));
        UD60x18 exp2_x = exp2(log2_x);

        assertEqWithinTolerance(x, exp2_x, ONE_TENTH_FP, "0.1%");
    }

    // Test that exp2 strictly increases
    // y > x && y < MAX --> exp2(y) > exp2(x)
    function exp2_test_strictly_increasing(UD60x18 x, UD60x18 y) public {
        require(y.gt(x) && y.lte(MAX_PERMITTED_EXP2));

        UD60x18 exp_x = exp(x);
        UD60x18 exp_y = exp(y);

        assertGte(exp_y, exp_x);
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // Test for zero case
    // exp2(0) == 1
    function exp2_test_zero() public {
        UD60x18 exp_zero = exp2(ZERO_FP);
        assertEq(exp_zero, ONE_FP);
    }

    // Test for maximum value. This should overflow as it won't fit
    // in the data type
    function exp2_test_maximum() public {
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

    // Test for inverse function
    // If y = ln(x) then exp(y) == x
    function exp_test_inverse(UD60x18 x) public {
        require(x.gte(UNIT));
        UD60x18 ln_x = ln(x);
        UD60x18 exp_x = exp(ln_x);
        require(exp_x.lte(MAX_PERMITTED_EXP));
        UD60x18 log2_x = log2(x);

        assertEqWithinDecimalPrecision(x, exp_x, 9);
    }

    // Test that exp strictly increases
    // y <= MAX && y.gt(x) --> exp(y) >= exp(x)
    function exp_test_strictly_increasing(UD60x18 x, UD60x18 y) public {
        require(y.gt(x) && y.lte(MAX_PERMITTED_EXP));

        UD60x18 exp_x = exp(x);
        UD60x18 exp_y = exp(y);

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
        UD60x18 exp_zero = exp(ZERO_FP);
        assertEq(exp_zero, ONE_FP);
    }

    // Test for maximum value. This should overflow as it won't fit
    // in the data type
    function exp_test_maximum() public {
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

    // Test for zero exponent
    // x ** 0 == 1
    function powu_test_zero_exponent(UD60x18 x) public {
        UD60x18 x_pow_0 = powu(x, 0);

        assertEq(x_pow_0, ONE_FP);
    }

    // Test for zero base
    // 0 ** x == 0
    function powu_test_zero_base(uint256 a) public {
        require(a != 0);

        UD60x18 zero_pow_a = powu(ZERO_FP, a);

        assertEq(zero_pow_a, ZERO_FP);
    }

    // Test for exponent one
    // x ** 1 == x
    function powu_test_one_exponent(UD60x18 x) public {
        UD60x18 x_pow_1 = powu(x, 1);

        assertEq(x_pow_1, x);
    }

    // Test for base one
    // 1 ** x == 1
    function powu_test_base_one(uint256 a) public {
        UD60x18 one_pow_a = powu(ONE_FP, a);

        assertEq(one_pow_a, ONE_FP);
    }

    // Test for product of powers of the same base
    // x ** a * x ** b == x ** (a + b)
    function powu_test_product_same_base(
        UD60x18 x,
        uint256 a,
        uint256 b
    ) public {
        require(x.neq(ZERO_FP));

        UD60x18 x_a = powu(x, a);
        UD60x18 x_b = powu(x, b);
        UD60x18 x_ab = powu(x, a + b);

        assertEqWithinBitPrecision(mul(x_a, x_b), x_ab, 10);
    }

    // Test for power of an exponentiation
    // (x ** a) ** b == x ** (a * b)
    function powu_test_power_of_an_exponentiation(
        UD60x18 x,
        uint256 a,
        uint256 b
    ) public {
        require(x.neq(ZERO_FP));

        UD60x18 x_a = powu(x, a);
        UD60x18 x_a_b = powu(x_a, b);
        UD60x18 x_ab = powu(x, a * b);

        assertEqWithinBitPrecision(x_a_b, x_ab, 10);
    }

    // Test for power of a product
    // (x * y) ** a == x ** a * y ** a
    function powu_test_product_power(
        UD60x18 x,
        UD60x18 y,
        uint256 a
    ) public {
        require(x.neq(ZERO_FP) && y.neq(ZERO_FP));

        require(a > 1e9); // to avoid massive loss of precision

        UD60x18 x_y = mul(x, y);
        UD60x18 xy_a = powu(x_y, a);

        UD60x18 x_a = powu(x, a);
        UD60x18 y_a = powu(y, a);

        assertEqWithinBitPrecision(mul(x_a, y_a), xy_a, 10);
    }

    // Test for result being greater than or lower than the argument, depending on
    // its value and the value of the exponent
    function powu_test_values(UD60x18 x, uint256 a) public {
        require(x.neq(ZERO_FP));

        UD60x18 x_a = powu(x, a);

        if (x.gte(ONE_FP)) {
            assertGte(x_a, ONE_FP);
        }

        if (x.lte(ONE_FP)) {
            assertLte(x_a, ONE_FP);
        }
    }

    // Unsigned power is strictly increasing
    // y > MIN && x > y && a > 0 --> powu(x, a) > powu(y, a)
    function powu_test_strictly_increasing(
        UD60x18 x,
        UD60x18 y,
        uint256 a
    ) public {
        require(x.gt(y) && y.gt(ZERO_FP));
        require(x.lte(MAX_UD60x18));
        require(a > 0);

        UD60x18 x_a = powu(x, a);
        UD60x18 y_a = powu(y, a);
        
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

        try this.helpersPowu(MAX_UD60x18, a) {
            // Unexpected, should revert because of overflow
            assert(false);
        } catch {
            // Expected revert
        }
    }

    // Test for base < 1 and high exponent
    function powu_test_high_exponent(UD60x18 x, uint256 a) public {
        require(x.lt(ONE_FP) && a > 2 ** 64);

        UD60x18 result = powu(x, a);

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
    function log10_test_distributive_mul(UD60x18 x, UD60x18 y) public {
        require(x.gte(UNIT) && y.gte(UNIT));
        UD60x18 log10_x = log10(x);
        UD60x18 log10_y = log10(y);
        UD60x18 log10_x_log10_y = add(log10_x, log10_y);

        UD60x18 xy = mul(x, y);
        UD60x18 log10_xy = log10(xy);

        // The maximum loss of precision is given by the formula:
        // | log10(x) + log10(y) |
        uint256 loss = intoUint256(log10(x).add(log10(y)));

        assertEqWithinBitPrecision(log10_x_log10_y, log10_xy, loss);
    }

    // Test for logarithm of a power
    // log10(x ** y) = y * log10(x)
    function log10_test_power(UD60x18 x, UD60x18 y) public {
        require(x.gte(UNIT) && y.gte(UNIT));
        UD60x18 x_y = pow(x, y);
        UD60x18 log10_x_y = log10(x_y);
        UD60x18 y_log10_x = mul(log10(x), y);

        assertEqWithinTolerance(log10_x_y, y_log10_x, ONE_TENTH_FP, "0.1%");
    }

    // Base 10 logarithm is strictly increasing
    // x > y && y > 0 --> log10(x) > log10(y)
    function log10_test_strictly_increasing(UD60x18 x, UD60x18 y) public {
        require(y.gt(ZERO_FP) && x.gt(y));
        
        UD60x18 log10_x = log10(x);
        UD60x18 log10_y = log10(y);

        assertGte(log10_x, log10_y);
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
        UD60x18 result;

        try this.helpersLog10(MAX_UD60x18) {
            // Expected, should not revert and the result must be > 0
            result = this.helpersLog10(MAX_UD60x18);
            assertGt(result, ZERO_FP);
        } catch {
            // Unexpected
            assert(false);
        }
    }

    // Test for values less than UNIT, should revert as result would be negative
    function log10_test_less_than_unit(UD60x18 x) public {
        require(x.lt(UNIT));

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
    function gm_test_product(UD60x18 x, UD60x18 y) public {
        UD60x18 x_mul_y = x.mul(y);
        UD60x18 gm_squared = pow(gm(x,y), TWO_FP);

        assertEqWithinTolerance(x_mul_y, gm_squared, ONE_TENTH_FP, "0.1%");
    }

    // The geometric mean for a set of positive numbers is less than the
    // arithmetic mean of that set, as long as the values of the set are not equal
    function gm_test_positive_set_avg(UD60x18 x, UD60x18 y) public {
        require(x.neq(y));

        UD60x18 gm_x_y = gm(x, y);
        UD60x18 avg_x_y = avg(x, y);

        assertLte(gm_x_y, avg_x_y);
    }

    // The geometric mean of a set of positive equal numbers should be
    // equal to the arithmetic mean
    function gm_test_positive_equal_set_avg(UD60x18 x) public {
        UD60x18 gm_x = gm(x, x);
        UD60x18 avg_x = avg(x, x);

        assertEq(gm_x, avg_x);
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // Test for zero case, should return 0
    function gm_test_zero(UD60x18 x) public {
        require(x.gte(ZERO_FP));

        try this.helpersGm(x, ZERO_FP) {
            UD60x18 result = gm(x, ZERO_FP);
            assertEq(result, ZERO_FP);
        } catch {
            // Unexpected, should not revert
            assert(false);
        }
    }
}