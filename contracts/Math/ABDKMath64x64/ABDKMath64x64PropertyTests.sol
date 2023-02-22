pragma solidity ^0.8.0;

import "./abdk-libraries-solidity/ABDKMath64x64.sol";

contract CryticABDKMath64x64Properties {

    /* ================================================================
       64x64 fixed-point constants used for testing specific values.
       This assumes that ABDK library's fromInt(x) works as expected.
       ================================================================ */
    int128 internal ZERO_FP = ABDKMath64x64.fromInt(0);
    int128 internal ONE_FP = ABDKMath64x64.fromInt(1);
    int128 internal MINUS_ONE_FP = ABDKMath64x64.fromInt(-1);
    int128 internal TWO_FP = ABDKMath64x64.fromInt(2);
    int128 internal THREE_FP = ABDKMath64x64.fromInt(3);
    int128 internal EIGHT_FP = ABDKMath64x64.fromInt(8);
    int128 internal THOUSAND_FP = ABDKMath64x64.fromInt(1000);
    int128 internal MINUS_SIXTY_FOUR_FP = ABDKMath64x64.fromInt(-64);
    int128 internal EPSILON = 1;
    int128 internal ONE_TENTH_FP = ABDKMath64x64.div(ABDKMath64x64.fromInt(1), ABDKMath64x64.fromInt(10));

    /* ================================================================
       Constants used for precision loss calculations
       ================================================================ */
    uint256 internal REQUIRED_SIGNIFICANT_BITS = 10;

    /* ================================================================
       Integer representations maximum values.
       These constants are used for testing edge cases or limits for 
       possible values.
       ================================================================ */
    int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;
    int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    int256 private constant MAX_256 =
        0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    int256 private constant MIN_256 =
        -0x8000000000000000000000000000000000000000000000000000000000000000;
    uint256 private constant MAX_U256 =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    /* ================================================================
       Events used for debugging or showing information.
       ================================================================ */
    event Value(string reason, int128 val);
    event LogErr(bytes error);

    /* ================================================================
       Helper functions.
       ================================================================ */

    // These functions allows to compare a and b for equality, discarding
    // the last precision_bits bits.
    // An absolute value function is implemented inline in order to not use 
    // the implementation from the library under test.
    function equal_within_precision(int128 a, int128 b, uint256 precision_bits) public pure returns(bool) {
        int128 max = (a > b) ? a : b;
        int128 min = (a > b) ? b : a;
        int128 r = (max - min) >> precision_bits;
        
        return (r == 0);
    }

    function equal_within_precision_u(uint256 a, uint256 b, uint256 precision_bits) public pure returns(bool) {
        uint256 max = (a > b) ? a : b;
        uint256 min = (a > b) ? b : a;
        uint256 r = (max - min) >> precision_bits;
        
        return (r == 0);
    }

    // This function determines if the relative error between a and b is less
    // than error_percent % (expressed as a 64x64 value)
    // Uses functions from the library under test!
    function equal_within_tolerance(int128 a, int128 b, int128 error_percent) public pure returns(bool) {
        int128 tol_value = abs(mul(a, div(error_percent, fromUInt(100))));

        return (abs(sub(b, a)) <= tol_value);
    }

    // Check that there are remaining significant digits after a multiplication
    // Uses functions from the library under test!
    function significant_digits_lost_in_mult(int128 a, int128 b) public pure returns (bool) {
        int128 x = a >= 0 ? a : -a;
        int128 y = b >= 0 ? b : -b;

        int128 lx = toInt(log_2(x));
        int128 ly = toInt(log_2(y));

        return(lx + ly - 1 <= -64);
    }

    // Return how many significant bits will remain after multiplying a and b
    // Uses functions from the library under test!
    function significant_bits_after_mult(int128 a, int128 b) public pure returns (uint256) {
        int128 x = a >= 0 ? a : -a;
        int128 y = b >= 0 ? b : -b;

        int128 lx = toInt(log_2(x));
        int128 ly = toInt(log_2(y));
        int256 prec = lx + ly - 1;

        if (prec < -64) return 0;
        else return(64 + uint256(prec));
    }

    // Return the i most significant bits from |n|. If n has less than i significant bits, return |n|
    // Uses functions from the library under test!
    function most_significant_bits(int128 n, uint256 i) public pure returns (uint256) {
        // Create a mask consisting of i bits set to 1
        uint256 mask = (2**i) - 1;

        // Get the position of the MSB set to 1 of n
        uint256 pos = uint64(toInt(log_2(n)) + 64 + 1);

        // Get the positive value of n
        uint256 value = (n>0) ? uint128(n) : uint128(-n);

        // Shift the mask to match the rightmost 1-set bit
        if(pos > i) { mask <<= (pos - i); }

        return (value & mask);
    }

    // Returns true if the n most significant bits of a and b are almost equal 
    // Uses functions from the library under test!
    function equal_most_significant_bits_within_precision(int128 a, int128 b, uint256 bits) public pure returns (bool) {
        // Get the number of bits in a and b
        // Since log(x) returns in the interval [-64, 63), add 64 to be in the interval [0, 127)
        uint256 a_bits = uint256(int256(toInt(log_2(a)) + 64));
        uint256 b_bits = uint256(int256(toInt(log_2(b)) + 64));

        // a and b lengths may differ in 1 bit, so the shift should take into account the longest
        uint256 shift_bits = (a_bits > b_bits) ? (a_bits - bits) : (b_bits - bits);

        // Get the _bits_ most significant bits of a and b
        uint256 a_msb = most_significant_bits(a, bits) >> shift_bits;
        uint256 b_msb = most_significant_bits(b, bits) >> shift_bits;

        // See if they are equal within 1 bit precision
        // This could be modified to get the precision as a parameter to the function
        return equal_within_precision_u(a_msb, b_msb, 1);
    }

    /* ================================================================
       Library wrappers.
       These functions allow calling the ABDKMath64x64 library.
       ================================================================ */
    function debug(string calldata x, int128 y) public {
        emit Value(x, ABDKMath64x64.toInt(y));
    }

    function fromInt(int256 x) public pure returns (int128) {
        return ABDKMath64x64.fromInt(x);
    }

    function toInt(int128 x) public pure returns (int64) {
        return ABDKMath64x64.toInt(x);
    }

    function fromUInt(uint256 x) public pure returns (int128) {
        return ABDKMath64x64.fromUInt(x);
    }

    function toUInt(int128 x) public pure returns (uint64) {
        return ABDKMath64x64.toUInt(x);
    }

    function add(int128 x, int128 y) public pure returns (int128) {
        return ABDKMath64x64.add(x, y);
    }

    function sub(int128 x, int128 y) public pure returns (int128) {
        return ABDKMath64x64.sub(x, y);
    }

    function mul(int128 x, int128 y) public pure returns (int128) {
        return ABDKMath64x64.mul(x, y);
    }

    function mulu(int128 x, uint256 y) public pure returns (uint256) {
        return ABDKMath64x64.mulu(x, y);
    }

    function div(int128 x, int128 y) public pure returns (int128) {
        return ABDKMath64x64.div(x, y);
    }

    function neg(int128 x) public pure returns (int128) {
        return ABDKMath64x64.neg(x);
    }

    function abs(int128 x) public pure returns (int128) {
        return ABDKMath64x64.abs(x);
    }

    function inv(int128 x) public pure returns (int128) {
        return ABDKMath64x64.inv(x);
    }

    function avg(int128 x, int128 y) public pure returns (int128) {
        return ABDKMath64x64.avg(x, y);
    }

    function gavg(int128 x, int128 y) public pure returns (int128) {
        return ABDKMath64x64.gavg(x, y);
    }

    function pow(int128 x, uint256 y) public pure returns (int128) {
        return ABDKMath64x64.pow(x, y);
    }

    function sqrt(int128 x) public pure returns (int128) {
        return ABDKMath64x64.sqrt(x);
    }

    function log_2(int128 x) public pure returns (int128) {
        return ABDKMath64x64.log_2(x);
    }

    function ln(int128 x) public pure returns (int128) {
        return ABDKMath64x64.ln(x);
    }

    function exp_2(int128 x) public pure returns (int128) {
        return ABDKMath64x64.exp_2(x);
    }

    function exp(int128 x) public pure returns (int128) {
        return ABDKMath64x64.exp(x);
    }


    /* ================================================================
       Start of tests
       ================================================================ */



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
    function add_test_commutative(int128 x, int128 y) public pure {
        int128 x_y = add(x, y);
        int128 y_x = add(y, x);

        assert(x_y == y_x);
    }

    // Test for associative property
    // (x + y) + z == x + (y + z)
    function add_test_associative(int128 x, int128 y, int128 z) public pure {
        int128 x_y = add(x, y);
        int128 y_z = add(y, z);
        int128 xy_z = add(x_y, z);
        int128 x_yz = add(x, y_z);

        assert(xy_z == x_yz);
    }

    // Test for identity operation
    // x + 0 == x (equivalent to x + (-x) == 0)
    function add_test_identity(int128 x) public view {
        int128 x_0 = add(x, ZERO_FP);

        assert(x_0 == x);
        assert(add(x, neg(x)) == ZERO_FP);
    }

    // Test that the result increases or decreases depending
    // on the value to be added
    function add_test_values(int128 x, int128 y) public view {
        int128 x_y = add(x, y);

        if (y >= ZERO_FP) {
            assert(x_y >= x);
        } else {
            assert(x_y < x);
        }
    }


    /* ================================================================
       Tests for overflow and edge cases.
       These should make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // The result of the addition must be between the maximum
    // and minimum allowed values for 64x64
    function add_test_range(int128 x, int128 y) public view {
        int128 result;
        try this.add(x, y) {
            result = this.add(x, y);
            assert(result <= MAX_64x64 && result >= MIN_64x64);
        } catch {
            // If it reverts, just ignore
        }
    }

    // Adding zero to the maximum value shouldn't revert, as it is valid
    // Moreover, the result must be MAX_64x64
    function add_test_maximum_value() public view {
        int128 result;
        try this.add(MAX_64x64, ZERO_FP) {
            // Expected behaviour, does not revert
            result = this.add(MAX_64x64, ZERO_FP);
            assert(result == MAX_64x64);
        } catch {
            assert(false);
        }
    }

    // Adding one to the maximum value should revert, as it is out of range
    function add_test_maximum_value_plus_one() public view {
        try this.add(MAX_64x64, ONE_FP) {
            assert(false);
        } catch {
            // Expected behaviour, reverts
        }
    }

    // Adding zero to the minimum value shouldn't revert, as it is valid
    // Moreover, the result must be MIN_64x64
    function add_test_minimum_value() public view {
        int128 result;
        try this.add(MIN_64x64, ZERO_FP) {
            // Expected behaviour, does not revert
            result = this.add(MIN_64x64, ZERO_FP);
            assert(result == MIN_64x64);
        } catch {
            assert(false);
        }
    }

    // Adding minus one to the maximum value should revert, as it is out of range
    function add_test_minimum_value_plus_negative_one() public view {
        try this.add(MIN_64x64, MINUS_ONE_FP) {
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
    function sub_test_equivalence_to_addition(int128 x, int128 y) public pure {
        int128 minus_y = neg(y);
        int128 addition = add(x, minus_y);
        int128 subtraction = sub(x, y);

        assert(addition == subtraction);
    }

    // Test for non-commutative property
    // x - y == -(y - x)
    function sub_test_non_commutative(int128 x, int128 y) public pure {
        int128 x_y = sub(x, y);
        int128 y_x = sub(y, x);
        
        assert(x_y == neg(y_x));
    }

    // Test for identity operation
    // x - 0 == x  (equivalent to x - x == 0)
    function sub_test_identity(int128 x) public view {
        int128 x_0 = sub(x, ZERO_FP);

        assert(x_0 == x);
        assert(sub(x, x) == ZERO_FP);
    }

    // Test for neutrality over addition and subtraction
    // (x - y) + y == (x + y) - y == x
    function sub_test_neutrality(int128 x, int128 y) public pure {
        int128 x_minus_y = sub(x, y);
        int128 x_plus_y = add(x, y);

        int128 x_minus_y_plus_y = add(x_minus_y, y);
        int128 x_plus_y_minus_y = sub(x_plus_y, y);
        
        assert(x_minus_y_plus_y == x_plus_y_minus_y);
        assert(x_minus_y_plus_y == x);
    }

    // Test that the result increases or decreases depending
    // on the value to be subtracted
    function sub_test_values(int128 x, int128 y) public view {
        int128 x_y = sub(x, y);

        if (y >= ZERO_FP) {
            assert(x_y <= x);
        } else {
            assert(x_y > x);
        }
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // The result of the subtraction must be between the maximum
    // and minimum allowed values for 64x64
    function sub_test_range(int128 x, int128 y) public view {
        int128 result;
        try this.sub(x, y) {
            result = this.sub(x, y);
            assert(result <= MAX_64x64 && result >= MIN_64x64);
        } catch {
            // If it reverts, just ignore
        }
    }

    // Subtracting zero from the maximum value shouldn't revert, as it is valid
    // Moreover, the result must be MAX_64x64
    function sub_test_maximum_value() public view {
        int128 result;
        try this.sub(MAX_64x64, ZERO_FP) {
            // Expected behaviour, does not revert
            result = this.sub(MAX_64x64, ZERO_FP);
            assert(result == MAX_64x64);
        } catch {
            assert(false);
        }
    }

    // Subtracting minus one from the maximum value should revert, 
    // as it is out of range
    function sub_test_maximum_value_minus_neg_one() public view {
        try this.sub(MAX_64x64, MINUS_ONE_FP) {
            assert(false);
        } catch {
            // Expected behaviour, reverts
        }
    }

    // Subtracting zero from the minimum value shouldn't revert, as it is valid
    // Moreover, the result must be MIN_64x64
    function sub_test_minimum_value() public view {
        int128 result;
        try this.sub(MIN_64x64, ZERO_FP) {
            // Expected behaviour, does not revert
            result = this.sub(MIN_64x64, ZERO_FP);
            assert(result == MIN_64x64);
        } catch {
            assert(false);
        }
    }

    // Subtracting one from the minimum value should revert, as it is out of range
    function sub_test_minimum_value_minus_one() public view {
        try this.sub(MIN_64x64, ONE_FP) {
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
    function mul_test_commutative(int128 x, int128 y) public pure {
        int128 x_y = mul(x, y);
        int128 y_x = mul(y, x);

        assert(x_y == y_x);
    }

    // Test for associative property
    // (x * y) * z == x * (y * z)
    function mul_test_associative(int128 x, int128 y, int128 z) public view {
        int128 x_y = mul(x, y);
        int128 y_z = mul(y, z);
        int128 xy_z = mul(x_y, z);
        int128 x_yz = mul(x, y_z);

        // Failure if all significant digits are lost
        require(significant_bits_after_mult(x, y) > REQUIRED_SIGNIFICANT_BITS);
        require(significant_bits_after_mult(y, z) > REQUIRED_SIGNIFICANT_BITS);
        require(significant_bits_after_mult(x_y, z) > REQUIRED_SIGNIFICANT_BITS);
        require(significant_bits_after_mult(x, y_z) > REQUIRED_SIGNIFICANT_BITS);

        assert(equal_within_tolerance(xy_z, x_yz, ONE_TENTH_FP));
    }

    // Test for distributive property
    // x * (y + z) == x * y + x * z
    function mul_test_distributive(int128 x, int128 y, int128 z) public view {
        int128 y_plus_z = add(y, z);
        int128 x_times_y_plus_z = mul(x, y_plus_z);

        int128 x_times_y = mul(x, y);
        int128 x_times_z = mul(x, z);

        // Failure if all significant digits are lost
        require(significant_bits_after_mult(x, y) > REQUIRED_SIGNIFICANT_BITS);
        require(significant_bits_after_mult(x, z) > REQUIRED_SIGNIFICANT_BITS);
        require(significant_bits_after_mult(x, y_plus_z) > REQUIRED_SIGNIFICANT_BITS);

        assert(equal_within_tolerance(add(x_times_y, x_times_z), x_times_y_plus_z, ONE_TENTH_FP));
    }

    // Test for identity operation
    // x * 1 == x  (also check that x * 0 == 0)
    function mul_test_identity(int128 x) public view {
        int128 x_1 = mul(x, ONE_FP);
        int128 x_0 = mul(x, ZERO_FP);

        assert(x_0 == ZERO_FP);
        assert(x_1 == x);
    }

    // Test that the result increases or decreases depending
    // on the value to be added
    function mul_test_values(int128 x, int128 y) public view {
        require(x != ZERO_FP && y != ZERO_FP);

        int128 x_y = mul(x, y);

        require(significant_digits_lost_in_mult(x, y) == false);

        if (x >= ZERO_FP) {
            if (y >= ONE_FP) {
                assert(x_y >= x);
            } else {
                assert(x_y <= x);
            }
        } else {
            if (y >= ONE_FP) {
                assert(x_y <= x);
            } else {
                assert(x_y >= x);
            }
        }
    }
    

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // The result of the multiplication must be between the maximum
    // and minimum allowed values for 64x64
    function mul_test_range(int128 x, int128 y) public view {
        int128 result;
        try this.mul(x, y) {
            result = this.mul(x, y);
            assert(result <= MAX_64x64 && result >= MIN_64x64);
        } catch {
            // If it reverts, just ignore
        }
    }

    // Multiplying the maximum value times one shouldn't revert, as it is valid
    // Moreover, the result must be MAX_64x64
    function mul_test_maximum_value() public view {
        int128 result;
        try this.mul(MAX_64x64, ONE_FP) {
            // Expected behaviour, does not revert
            result = this.mul(MAX_64x64, ONE_FP);
            assert(result == MAX_64x64);
        } catch {
            assert(false);
        }
    }

    // Multiplying the minimum value times one shouldn't revert, as it is valid
    // Moreover, the result must be MIN_64x64
    function mul_test_minimum_value() public view {
        int128 result;
        try this.mul(MIN_64x64, ONE_FP) {
            // Expected behaviour, does not revert
            result = this.mul(MIN_64x64, ONE_FP);
            assert(result == MIN_64x64);
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
    // Moreover, x/x should not revert unless x == 0
    function div_test_division_identity(int128 x) public view {
        int128 div_1 = div(x, ONE_FP);
        assert(x == div_1);

        int128 div_x;

        try this.div(x, x) {
            // This should always equal one
            div_x = div(x, x);
            assert(div_x == ONE_FP);
        } catch {
            // The only allowed case to revert is if x == 0
            assert(x == ZERO_FP);
        }

    }

    // Test for negative divisor
    // x / -y == -(x / y)
    function div_test_negative_divisor(int128 x, int128 y) public view {
        require(y < ZERO_FP);

        int128 x_y = div(x, y);
        int128 x_minus_y = div(x, neg(y));

        assert(x_y == neg(x_minus_y));
    }

    // Test for division with 0 as numerator
    // 0 / x = 0
    function div_test_division_num_zero(int128 x) public view {
        require(x != ZERO_FP);

        int128 div_0 = div(ZERO_FP, x);

        assert(ZERO_FP == div_0);
    }

    // Test that the absolute value of the result increases or 
    // decreases depending on the denominator's absolute value
    function div_test_values(int128 x, int128 y) public view {
        require(y != ZERO_FP);

        int128 x_y = abs(div(x, y));

        if (abs(y) >= ONE_FP) {
            assert(x_y <= abs(x));
        } else {
            assert(x_y >= abs(x));
        }
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // Test for division by zero
    function div_test_div_by_zero(int128 x) public view {
        try this.div(x, ZERO_FP) {
            // Unexpected, this should revert
            assert(false);
        } catch {
            // Expected revert
        }
    }

    // Test for division by a large value, the result should be less than one
    function div_test_maximum_denominator(int128 x) public view {
        int128 div_large = div(x, MAX_64x64);

        assert(abs(div_large) <= ONE_FP);
    }

    // Test for division of a large value
    // This should revert if |x| < 1 as it would return a value higher than max
    function div_test_maximum_numerator(int128 x) public view {
        int128 div_large;

        try this.div(MAX_64x64, x) {
            // If it didn't revert, then |x| >= 1
            div_large = div(MAX_64x64, x);

            assert(abs(x) >= ONE_FP);
        } catch {
            // Expected revert as result is higher than max
        }
    }

    // Test for values in range
    function div_test_range(int128 x, int128 y) public view {
        int128 result;

        try this.div(x, y) {
            // If it returns a value, it must be in range
            result = div(x, y);
            assert(result <= MAX_64x64 && result >= MIN_64x64);
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
    function neg_test_double_negation(int128 x) public pure {
        int128 double_neg = neg(neg(x));

        assert(x == double_neg);
    }

    // Test for the identity operation
    // x + (-x) == 0
    function neg_test_identity(int128 x) public view {
        int128 neg_x = neg(x);

        assert(add(x, neg_x) == ZERO_FP);
    }


    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // Test for the zero-case
    // -0 == 0
    function neg_test_zero() public view {
        int128 neg_x = neg(ZERO_FP);

        assert(neg_x == ZERO_FP);
    }

    // Test for the maximum value case
    // Since this is implementation-dependant, we will actually test with MAX_64x64-EPS
    function neg_test_maximum() public view {
        try this.neg(sub(MAX_64x64, EPSILON)) {
            // Expected behaviour, does not revert
        } catch {
            assert(false);
        }
    }

    // Test for the minimum value case
    // Since this is implementation-dependant, we will actually test with MIN_64x64+EPS
    function neg_test_minimum() public view {
        try this.neg(add(MIN_64x64, EPSILON)) {
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
    function abs_test_positive(int128 x) public view {
        int128 abs_x = abs(x);

        assert(abs_x >= ZERO_FP);
    }

    // Test that the absolute value of a number equals the
    // absolute value of the negative of the same number
    function abs_test_negative(int128 x) public pure {
        int128 abs_x = abs(x);
        int128 abs_minus_x = abs(neg(x));

        assert(abs_x == abs_minus_x);
    }

    // Test the multiplicativeness property
    // | x * y | == |x| * |y|
    function abs_test_multiplicativeness(int128 x, int128 y) public pure {
        int128 abs_x = abs(x);
        int128 abs_y = abs(y);
        int128 abs_xy = abs(mul(x, y));
        int128 abs_x_abs_y = mul(abs_x, abs_y);

        // Failure if all significant digits are lost
        require(significant_digits_lost_in_mult(abs_x, abs_y) == false);

        // Assume a tolerance of two bits of precision
        assert(equal_within_precision(abs_xy, abs_x_abs_y, 2));
    }

    // Test the subadditivity property
    // | x + y | <= |x| + |y|
    function abs_test_subadditivity(int128 x, int128 y) public pure {
        int128 abs_x = abs(x);
        int128 abs_y = abs(y);
        int128 abs_xy = abs(add(x, y));

        assert(abs_xy <= add(abs_x, abs_y));
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // Test the zero-case | 0 | = 0
    function abs_test_zero() public view {
        int128 abs_zero;

        try this.abs(ZERO_FP) {
            // If it doesn't revert, the value must be zero
            abs_zero = this.abs(ZERO_FP);
            assert(abs_zero == ZERO_FP);
        } catch {
            // Unexpected, the function must not revert here
            assert(false);
        }
    }

    // Test the maximum value
    function abs_test_maximum() public view {
        int128 abs_max;

        try this.abs(MAX_64x64) {
            // If it doesn't revert, the value must be MAX_64x64
            abs_max = this.abs(MAX_64x64);
            assert(abs_max == MAX_64x64);
        } catch {

        }
    }

    // Test the minimum value
    function abs_test_minimum() public view {
        int128 abs_min;

        try this.abs(MIN_64x64) {
            // If it doesn't revert, the value must be the negative of MIN_64x64
            abs_min = this.abs(MIN_64x64);
            assert(abs_min == neg(MIN_64x64));
        } catch {

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
    function inv_test_double_inverse(int128 x) public view {
        require(x != ZERO_FP);

        int128 double_inv_x = inv(inv(x));

        // The maximum loss of precision will be 2 * log2(x) bits rounded up
        uint256 loss = 2 * toUInt(log_2(x)) + 2;

        assert(equal_within_precision(x, double_inv_x, loss));
    }

    // Test equivalence with division
    function inv_test_division(int128 x) public view {
        require(x != ZERO_FP);

        int128 inv_x = inv(x);
        int128 div_1_x = div(ONE_FP, x);

        assert(inv_x == div_1_x);
    }

    // Test the anticommutativity of the division
    // x / y == 1 / (y / x)
    function inv_test_division_noncommutativity(int128 x, int128 y) public view {
        require(x != ZERO_FP && y != ZERO_FP);

        int128 x_y = div(x, y);
        int128 y_x = div(y, x);

        require(significant_bits_after_mult(x, inv(y)) > REQUIRED_SIGNIFICANT_BITS);
        require(significant_bits_after_mult(y, inv(x)) > REQUIRED_SIGNIFICANT_BITS);
        assert(equal_within_tolerance(x_y, inv(y_x), ONE_TENTH_FP));
    }

    // Test the multiplication of inverses
    // 1/(x * y) == 1/x * 1/y
    function inv_test_multiplication(int128 x, int128 y) public view {
        require(x != ZERO_FP && y != ZERO_FP);

        int128 inv_x = inv(x);
        int128 inv_y = inv(y);
        int128 inv_x_times_inv_y = mul(inv_x, inv_y);
        
        int128 x_y = mul(x, y);
        int128 inv_x_y = inv(x_y);

        require(significant_bits_after_mult(x, y) > REQUIRED_SIGNIFICANT_BITS);
        require(significant_bits_after_mult(inv_x, inv_y) > REQUIRED_SIGNIFICANT_BITS);

        // The maximum loss of precision is given by the formula:
        // 2 * | log_2(x) - log_2(y) | + 1
        uint256 loss = 2 * toUInt(abs(log_2(x) - log_2(y))) + 1;

        assert(equal_within_precision(inv_x_y, inv_x_times_inv_y, loss));
    }

    // Test identity property
    // Intermediate result should have at least REQUIRED_SIGNIFICANT_BITS
    function inv_test_identity(int128 x) public view {
        require(x != ZERO_FP);

        int128 inv_x = inv(x);
        int128 identity = mul(inv_x, x);

        require(significant_bits_after_mult(x, inv_x) > REQUIRED_SIGNIFICANT_BITS);

        // They should agree with a tolerance of one tenth of a percent
        assert(equal_within_tolerance(identity, ONE_FP, ONE_TENTH_FP));
    }

    // Test that the absolute value of the result is in range zero-one 
    // if x is greater than one, else, the absolute value of the result
    // must be greater than one
    function inv_test_values(int128 x) public view {
        require(x != ZERO_FP);

        int128 abs_inv_x = abs(inv(x));

        if(abs(x) >= ONE_FP) {
            assert(abs_inv_x <= ONE_FP);
        } else {
            assert(abs_inv_x > ONE_FP);
        }
    }

    // Test that the result has the same sign as the argument
    function inv_test_sign(int128 x) public view {
        require(x != ZERO_FP);

        int128 inv_x = inv(x);

        if(x > ZERO_FP) {
            assert(inv_x > ZERO_FP);
        } else {
            assert(inv_x < ZERO_FP);
        }
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // Test the zero-case, should revert
    function inv_test_zero() public view {
        try this.inv(ZERO_FP) {
            // Unexpected, the function must revert
            assert(false);
        } catch {

        }
    }

    // Test the maximum value case, should not revert, and be close to zero
    function inv_test_maximum() public view {
        int128 inv_maximum;

        try this.inv(MAX_64x64) {
            inv_maximum = this.inv(MAX_64x64);
            assert(equal_within_precision(inv_maximum, ZERO_FP, 10));
        } catch {
            // Unexpected, the function must not revert
            assert(false);
        }
    }

    // Test the minimum value case, should not revert, and be close to zero
    function inv_test_minimum() public view {
        int128 inv_minimum;

        try this.inv(MAX_64x64) {
            inv_minimum = this.inv(MAX_64x64);
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
    function avg_test_values_in_range(int128 x, int128 y) public pure {
        int128 avg_xy = avg(x, y);

        if(x >= y) {
            assert(avg_xy >= y && avg_xy <= x);
        } else {
            assert(avg_xy >= x && avg_xy <= y);
        }
    }

    // Test that the average of the same number is itself
    // avg(x, x) == x
    function avg_test_one_value(int128 x) public pure {
        int128 avg_x = avg(x, x);

        assert(avg_x == x);
    }

    // Test that the order of operands is irrelevant
    // avg(x, y) == avg(y, x)
    function avg_test_operand_order(int128 x, int128 y) public pure {
        int128 avg_xy = avg(x, y);
        int128 avg_yx = avg(y, x);
        
        assert(avg_xy == avg_yx);
    }


    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // Test for the maximum value
    function avg_test_maximum() public view {
        int128 result; 

        // This may revert due to overflow depending on implementation
        // If it doesn't revert, the result must be MAX_64x64
        try this.avg(MAX_64x64, MAX_64x64) {
            result = this.avg(MAX_64x64, MAX_64x64);
            assert(result == MAX_64x64);
        } catch {

        }
    }

    // Test for the minimum value
    function avg_test_minimum() public view {
        int128 result; 

        // This may revert due to overflow depending on implementation
        // If it doesn't revert, the result must be MIN_64x64
        try this.avg(MIN_64x64, MIN_64x64) {
            result = this.avg(MIN_64x64, MIN_64x64);
            assert(result == MIN_64x64);
        } catch {
            
        }
    }



    /* ================================================================

                        TESTS FOR FUNCTION gavg()

        ================================================================ */


    /* ================================================================
       Tests for arithmetic properties.
       These should make sure that the implemented function complies
       with math rules and expected behaviour.
       ================================================================ */

    // Test that the result is between the two operands
    // gavg(x, y) >= min(x, y) && gavg(x, y) <= max(x, y)
    function gavg_test_values_in_range(int128 x, int128 y) public view {
        int128 gavg_xy = gavg(x, y);

        if(x == ZERO_FP || y == ZERO_FP) {
            assert(gavg_xy == ZERO_FP);
        } else {
            if(abs(x) >= abs(y)) {
                assert(gavg_xy >= abs(y) && gavg_xy <= abs(x));
            } else {
                assert(gavg_xy >= abs(x) && gavg_xy <= abs(y));
            }
        }
    }

    // Test that the average of the same number is itself
    // gavg(x, x) == | x |
    function gavg_test_one_value(int128 x) public pure {
        int128 gavg_x = gavg(x, x);

        assert(gavg_x == abs(x));
    }

    // Test that the order of operands is irrelevant
    // gavg(x, y) == gavg(y, x)
    function gavg_test_operand_order(int128 x, int128 y) public pure {
        int128 gavg_xy = gavg(x, y);
        int128 gavg_yx = gavg(y, x);
        
        assert(gavg_xy == gavg_yx);
    }


    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // Test for the maximum value
    function gavg_test_maximum() public view {
        int128 result; 

        // This may revert due to overflow depending on implementation
        // If it doesn't revert, the result must be MAX_64x64
        try this.gavg(MAX_64x64, MAX_64x64) {
            result = this.gavg(MAX_64x64, MAX_64x64);
            assert(result == MAX_64x64);
        } catch {

        }
    }

    // Test for the minimum value
    function gavg_test_minimum() public view {
        int128 result; 

        // This may revert due to overflow depending on implementation
        // If it doesn't revert, the result must be MIN_64x64
        try this.gavg(MIN_64x64, MIN_64x64) {
            result = this.gavg(MIN_64x64, MIN_64x64);
            assert(result == MIN_64x64);
        } catch {
            
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
    function pow_test_zero_exponent(int128 x) public view {
        int128 x_pow_0 = pow(x, 0);

        assert(x_pow_0 == ONE_FP);
    }

    // Test for zero base
    // 0 ** x == 0 (for positive x)
    function pow_test_zero_base(uint256 x) public view {
        require(x != 0);

        int128 zero_pow_x = pow(ZERO_FP, x);

        assert(zero_pow_x == ZERO_FP);
    }

    // Test for exponent one
    // x ** 1 == x
    function pow_test_one_exponent(int128 x) public pure {
        int128 x_pow_1 = pow(x, 1);

        assert(x_pow_1 == x);
    }

    // Test for base one
    // 1 ** x == 1
    function pow_test_base_one(uint256 x) public view {
        int128 one_pow_x = pow(ONE_FP, x);

        assert(one_pow_x == ONE_FP);
    }

    // Test for product of powers of the same base
    // x ** a * x ** b == x ** (a + b)
    function pow_test_product_same_base(int128 x, uint256 a, uint256 b) public view {
        require(x != ZERO_FP);

        int128 x_a = pow(x, a);
        int128 x_b = pow(x, b);
        int128 x_ab = pow(x, a + b);

        assert(equal_within_precision(mul(x_a, x_b), x_ab, 2));
    }

    // Test for power of an exponentiation
    // (x ** a) ** b == x ** (a * b)
    function pow_test_power_of_an_exponentiation(int128 x, uint256 a, uint256 b) public view {
        require(x != ZERO_FP);

        int128 x_a = pow(x, a);
        int128 x_a_b = pow(x_a, b);
        int128 x_ab = pow(x, a * b);

        assert(equal_within_precision(x_a_b, x_ab, 2));
    }

    // Test for power of a product
    // (x * y) ** a == x ** a * y ** a
    function pow_test_product_same_base(int128 x, int128 y, uint256 a) public view {
        require(x != ZERO_FP && y != ZERO_FP);
        require(a > 2**32); // to avoid massive loss of precision

        int128 x_y = mul(x, y);
        int128 xy_a = pow(x_y, a);

        int128 x_a = pow(x, a);
        int128 y_a = pow(y, a);

        assert(equal_within_precision(mul(x_a, y_a), xy_a, 2));
    }

    // Test for result being greater than or lower than the argument, depending on 
    // its absolute value and the value of the exponent
    function pow_test_values(int128 x, uint256 a) public view {
        require(x != ZERO_FP);

        int128 x_a = pow(x, a);

        if(abs(x) >= ONE_FP) {
            assert(abs(x_a) >= ONE_FP);
        }

        if(abs(x) <= ONE_FP) {
            assert(abs(x_a) <= ONE_FP);
        }
    }

    // Test for result sign: if the exponent is even, sign is positive
    // if the exponent is odd, preserves the sign of the base
    function pow_test_sign(int128 x, uint256 a) public view {
        require(x != ZERO_FP && a != 0);

        int128 x_a = pow(x, a);

        // This prevents the case where a small negative number gets
        // rounded down to zero and thus changes sign
        require(x_a != ZERO_FP);

        // If the exponent is even
        if(a % 2 == 0) {
            assert(x_a == abs(x_a));
        } else {
            // x_a preserves x sign
            if (x < ZERO_FP) {
                assert(x_a < ZERO_FP);
            } else {
                assert(x_a > ZERO_FP);
            }
        }
    }


    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // Test for maximum base and exponent > 1
    function pow_test_maximum_base(uint256 a) public view {
        require(a > 1);

        try this.pow(MAX_64x64, a) {
            // Unexpected, should revert because of overflow
            assert(false);
        } catch {
            // Expected revert
        }
    }

    // Test for abs(base) < 1 and high exponent
    function pow_test_high_exponent(int128 x, uint256 a) public view {
        require(abs(x) < ONE_FP && a > 2**64);

        int128 result = pow(x, a);

        assert(result == ZERO_FP);
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
    function sqrt_test_inverse_mul(int128 x) public view {
        require(x >= ZERO_FP);

        int128 sqrt_x = sqrt(x);
        int128 sqrt_x_squared = mul(sqrt_x, sqrt_x);

        // Precision loss is at most half the bits of the operand
        assert(equal_within_precision(sqrt_x_squared, x,  (toUInt(log_2(x)) >> 1) + 2));
    }

    // Test for the inverse operation
    // sqrt(x) ** 2 == x
    function sqrt_test_inverse_pow(int128 x) public view {
        require(x >= ZERO_FP);

        int128 sqrt_x = sqrt(x);
        int128 sqrt_x_squared = pow(sqrt_x, 2);

        // Precision loss is at most half the bits of the operand
        assert(equal_within_precision(sqrt_x_squared, x, (toUInt(log_2(x)) >> 1) + 2));
    }

    // Test for distributive property respect to the multiplication
    // sqrt(x) * sqrt(y) == sqrt(x * y)
    function sqrt_test_distributive(int128 x, int128 y) public view {
        require(x >= ZERO_FP && y >= ZERO_FP);

        int128 sqrt_x = sqrt(x);
        int128 sqrt_y = sqrt(y);
        int128 sqrt_x_sqrt_y = mul(sqrt_x, sqrt_y);
        int128 sqrt_xy = sqrt(mul(x, y));

        // Ensure we have enough significant digits for the result to be meaningful
        require(significant_bits_after_mult(x, y) > REQUIRED_SIGNIFICANT_BITS);
        require(significant_bits_after_mult(sqrt_x, sqrt_y) > REQUIRED_SIGNIFICANT_BITS);

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
        assert(sqrt(ZERO_FP) == ZERO_FP);
    }

    // Test for maximum value
    function sqrt_test_maximum() public view {
        try this.sqrt(MAX_64x64) {
            // Expected behaviour, MAX_64x64 is positive, and operation 
            // should not revert as the result is in range
        } catch {
            // Unexpected, should not revert
            assert(false);
        }
    }

    // Test for minimum value
    function sqrt_test_minimum() public view {
        try this.sqrt(MIN_64x64) {
            // Unexpected, should revert. MIN_64x64 is negative.
            assert(false);
        } catch {
            // Expected behaviour, revert
        }
    }

    // Test for negative operands
    function sqrt_test_negative(int128 x) public view {
        require(x < ZERO_FP);

        try this.sqrt(x) {
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
    function log2_test_distributive_mul(int128 x, int128 y) public view {
        int128 log2_x = log_2(x);
        int128 log2_y = log_2(y);
        int128 log2_x_log2_y = add(log2_x, log2_y);

        int128 xy = mul(x, y);
        int128 log2_xy = log_2(xy);

        // Ensure we have enough significant digits for the result to be meaningful
        require(significant_bits_after_mult(x, y) > REQUIRED_SIGNIFICANT_BITS);

        // The maximum loss of precision is given by the formula:
        // | log_2(x) + log_2(y) | 
        uint256 loss = toUInt(abs(log_2(x) + log_2(y)));

        assert(equal_within_precision(log2_x_log2_y, log2_xy, loss));
    }

    // Test for logarithm of a power
    // log2(x ** y) = y * log2(x)
    function log2_test_power(int128 x, uint256 y) public pure {
        int128 x_y = pow(x, y);
        int128 log2_x_y = log_2(x_y);

        uint256 y_log2_x = mulu(log_2(x), y);

        assert(y_log2_x == toUInt(log2_x_y));
    }


    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // Test for zero case, should revert
    function log2_test_zero() public view {
        try this.log_2(ZERO_FP) {
            // Unexpected, should revert
            assert(false);
        } catch {
            // Expected revert, log(0) is not defined
        }
    }

    // Test for maximum value case, should return a positive number
    function log2_test_maximum() public view {
        int128 result;

        try this.log_2(MAX_64x64) {
            // Expected, should not revert and the result must be > 0
            result = this.log_2(MAX_64x64);
            assert(result > ZERO_FP);
        } catch {
            // Unexpected
            assert(false);
        }
    }

    // Test for negative values, should revert as log2 is not defined
    function log2_test_negative(int128 x) public view {
        require(x < ZERO_FP);

        try this.log_2(x) {
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
    function ln_test_distributive_mul(int128 x, int128 y) public view {
        require(x > ZERO_FP && y > ZERO_FP);

        int128 ln_x = ln(x);
        int128 ln_y = ln(y);
        int128 ln_x_ln_y = add(ln_x, ln_y);

        int128 xy = mul(x, y);
        int128 ln_xy = ln(xy);

        require(significant_bits_after_mult(x, y) > REQUIRED_SIGNIFICANT_BITS);

        // The maximum loss of precision is given by the formula:
        // | log_2(x) + log_2(y) | 
        uint256 loss = toUInt(abs(log_2(x) + log_2(y)));

        assert(equal_within_precision(ln_x_ln_y, ln_xy, loss));
    }

    // Test for logarithm of a power
    // ln(x ** y) = y * ln(x)
    function ln_test_power(int128 x, uint256 y) public pure {
        int128 x_y = pow(x, y);
        int128 ln_x_y = ln(x_y);

        uint256 y_ln_x = mulu(ln(x), y);

        assert(y_ln_x == toUInt(ln_x_y));
    }


    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // Test for zero case, should revert
    function ln_test_zero() public view {
        try this.ln(ZERO_FP) {
            // Unexpected, should revert
            assert(false);
        } catch {
            // Expected revert, log(0) is not defined
        }
    }

    // Test for maximum value case, should return a positive number
    function ln_test_maximum() public view {
        int128 result;

        try this.ln(MAX_64x64) {
            // Expected, should not revert and the result must be > 0
            result = this.ln(MAX_64x64);
            assert(result > ZERO_FP);
        } catch {
            // Unexpected
            assert(false);
        }
    }

    // Test for negative values, should revert as ln is not defined
    function ln_test_negative(int128 x) public view {
        require(x < ZERO_FP);

        try this.ln(x) {
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
    // pow(2, x) == exp_2(x)
    function exp2_test_equivalence_pow(uint256 x) public view {
        int128 exp2_x = exp_2(fromUInt(x));
        int128 pow_2_x = pow(TWO_FP, x);

        assert(exp2_x == pow_2_x);
    }

    // Test for inverse function
    // If y = log_2(x) then exp_2(y) == x
    function exp2_test_inverse(int128 x) public view {
        int128 log2_x = log_2(x);
        int128 exp2_x = exp_2(log2_x);        

        uint256 bits = 50;

        if(log2_x < ZERO_FP) {
            bits = uint256(int256(bits) + int256(log2_x));
        }

        assert(equal_most_significant_bits_within_precision(x, exp2_x, bits));
    }

    // Test for negative exponent
    // exp_2(-x) == inv( exp_2(x) )
    function exp2_test_negative_exponent(int128 x) public view {
        require(x < ZERO_FP && x != MIN_64x64);

        int128 exp2_x = exp_2(x);
        int128 exp2_minus_x = exp_2(-x);

        // Result should be within 4 bits precision for the worst case
        assert(equal_within_precision(exp2_x, inv(exp2_minus_x), 4));
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    // Test for zero case
    // exp_2(0) == 1
    function exp2_test_zero() public view {
        int128 exp_zero = exp_2(ZERO_FP);
        assert(exp_zero == ONE_FP);
    }

    // Test for maximum value. This should overflow as it won't fit 
    // in the data type
    function exp2_test_maximum() public view {
        try this.exp_2(MAX_64x64) {
            // Unexpected, should revert
            assert(false);
        } catch {
            // Expected revert
        }
    }
    
    // Test for minimum value. This should return zero since
    // 2 ** -x == 1 / 2 ** x that tends to zero as x increases
    function exp2_test_minimum() public view {
        int128 result;

        try this.exp_2(MIN_64x64) {
            // Expected, should not revert, check that value is zero
            result = exp_2(MIN_64x64);
            assert(result == ZERO_FP);
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
    function exp_test_inverse(int128 x) public view {
        int128 ln_x = ln(x);
        int128 exp_x = exp(ln_x);
        int128 log2_x = log_2(x);

        uint256 bits = 48;

        if(log2_x < ZERO_FP) {
            bits = uint256(int256(bits) + int256(log2_x));
        }

        assert(equal_most_significant_bits_within_precision(x, exp_x, bits));
    }

    // Test for negative exponent
    // exp(-x) == inv( exp(x) )
    function exp_test_negative_exponent(int128 x) public view {
        require(x < ZERO_FP && x != MIN_64x64);

        int128 exp_x = exp(x);
        int128 exp_minus_x = exp(-x);

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
        int128 exp_zero = exp(ZERO_FP);
        assert(exp_zero == ONE_FP);
    }

    // Test for maximum value. This should overflow as it won't fit 
    // in the data type
    function exp_test_maximum() public view {
        try this.exp(MAX_64x64) {
            // Unexpected, should revert
            assert(false);
        } catch {
            // Expected revert
        }
    }
    
    // Test for minimum value. This should return zero since
    // e ** -x == 1 / e ** x that tends to zero as x increases
    function exp_test_minimum() public view {
        int128 result;

        try this.exp(MIN_64x64) {
            // Expected, should not revert, check that value is zero
            result = exp(MIN_64x64);
            assert(result == ZERO_FP);
        } catch {
            // Unexpected revert
            assert(false);
        }
    }

}
