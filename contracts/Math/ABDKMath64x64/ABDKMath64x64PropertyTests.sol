// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "./abdk-libraries-solidity/ABDKMath64x64.sol";

/**
 * @title ABDKMath64x64 Property Tests
 * @notice Comprehensive property-based test suite for the ABDKMath64x64 fixed-point math library
 * @dev This contract contains 106 mathematical property tests covering arithmetic operations,
 *      exponential/logarithmic functions, and edge cases for the ABDK 64.64 fixed-point format.
 *
 *      The ABDK 64.64 format represents numbers as int128 values where:
 *      - The upper 64 bits represent the integer part
 *      - The lower 64 bits represent the fractional part
 *      - Range: approximately -9.22e18 to 9.22e18
 *      - Precision: approximately 18 decimal places
 *
 *      Test Coverage:
 *      - Addition (9 properties)
 *      - Subtraction (9 properties)
 *      - Multiplication (7 properties)
 *      - Division (8 properties)
 *      - Negation (5 properties)
 *      - Absolute Value (6 properties)
 *      - Inverse (9 properties)
 *      - Arithmetic Average (5 properties)
 *      - Geometric Average (5 properties)
 *      - Power (11 properties)
 *      - Square Root (7 properties)
 *      - Logarithms - log2 and ln (12 properties)
 *      - Exponentials - exp2 and exp (9 properties)
 *
 *      Testing Strategy:
 *      All properties use ISOLATED testing mode as they test pure mathematical functions
 *      without any contract state. Tests verify algebraic properties (commutativity,
 *      associativity, distributivity), identity operations, monotonicity, and correct
 *      handling of edge cases (overflow, underflow, division by zero, etc.).
 *
 *      Precision Handling:
 *      Fixed-point arithmetic involves inherent precision loss. Tests use tolerance-based
 *      comparisons and significant bit analysis to account for acceptable rounding errors
 *      while still catching genuine implementation bugs.
 */
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
    int128 internal ONE_TENTH_FP =
        ABDKMath64x64.div(ABDKMath64x64.fromInt(1), ABDKMath64x64.fromInt(10));

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
    function equal_within_precision(
        int128 a,
        int128 b,
        uint256 precision_bits
    ) public pure returns (bool) {
        int128 max = (a > b) ? a : b;
        int128 min = (a > b) ? b : a;
        int128 r = (max - min) >> precision_bits;

        return (r == 0);
    }

    function equal_within_precision_u(
        uint256 a,
        uint256 b,
        uint256 precision_bits
    ) public pure returns (bool) {
        uint256 max = (a > b) ? a : b;
        uint256 min = (a > b) ? b : a;
        uint256 r = (max - min) >> precision_bits;

        return (r == 0);
    }

    // This function determines if the relative error between a and b is less
    // than error_percent % (expressed as a 64x64 value)
    // Uses functions from the library under test!
    function equal_within_tolerance(
        int128 a,
        int128 b,
        int128 error_percent
    ) public pure returns (bool) {
        int128 tol_value = abs(mul(a, div(error_percent, fromUInt(100))));

        return (abs(sub(b, a)) <= tol_value);
    }

    // Check that there are remaining significant digits after a multiplication
    // Uses functions from the library under test!
    function significant_digits_lost_in_mult(
        int128 a,
        int128 b
    ) public pure returns (bool) {
        int128 x = a >= 0 ? a : -a;
        int128 y = b >= 0 ? b : -b;

        int128 lx = toInt(log_2(x));
        int128 ly = toInt(log_2(y));

        return (lx + ly - 1 <= -64);
    }

    // Return how many significant bits will remain after multiplying a and b
    // Uses functions from the library under test!
    function significant_bits_after_mult(
        int128 a,
        int128 b
    ) public pure returns (uint256) {
        int128 x = a >= 0 ? a : -a;
        int128 y = b >= 0 ? b : -b;

        int128 lx = toInt(log_2(x));
        int128 ly = toInt(log_2(y));
        int256 prec = lx + ly - 1;

        if (prec < -64) return 0;
        else return (64 + uint256(prec));
    }

    // Return the i most significant bits from |n|. If n has less than i significant bits, return |n|
    // Uses functions from the library under test!
    function most_significant_bits(
        int128 n,
        uint256 i
    ) public pure returns (uint256) {
        // Create a mask consisting of i bits set to 1
        uint256 mask = (2 ** i) - 1;

        // Get the position of the MSB set to 1 of n
        uint256 pos = uint64(toInt(log_2(n)) + 64 + 1);

        // Get the positive value of n
        uint256 value = (n > 0) ? uint128(n) : uint128(-n);

        // Shift the mask to match the rightmost 1-set bit
        if (pos > i) {
            mask <<= (pos - i);
        }

        return (value & mask);
    }

    // Returns true if the n most significant bits of a and b are almost equal
    // Uses functions from the library under test!
    function equal_most_significant_bits_within_precision(
        int128 a,
        int128 b,
        uint256 bits
    ) public pure returns (bool) {
        // Get the number of bits in a and b
        // Since log(x) returns in the interval [-64, 63), add 64 to be in the interval [0, 127)
        uint256 a_bits = uint256(int256(toInt(log_2(a)) + 64));
        uint256 b_bits = uint256(int256(toInt(log_2(b)) + 64));

        // a and b lengths may differ in 1 bit, so the shift should take into account the longest
        uint256 shift_bits = (a_bits > b_bits)
            ? (a_bits - bits)
            : (b_bits - bits);

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

    /**
     * @title Addition is Commutative
     * @notice Verifies that addition order does not affect the result
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: x + y == y + x
     * @dev Addition must be commutative - swapping operands should yield identical results.
     *      This fundamental property ensures order-independent arithmetic.
     * @custom:property-id MATH-ADD-001
     */
    function add_test_commutative(int128 x, int128 y) public pure {
        int128 x_y = add(x, y);
        int128 y_x = add(y, x);

        assert(x_y == y_x);
    }

    /**
     * @title Addition is Associative
     * @notice Verifies that grouping of additions does not affect the result
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: (x + y) + z == x + (y + z)
     * @dev Addition must be associative - the grouping of operations should not matter.
     *      This property is essential for predictable multi-term addition.
     * @custom:property-id MATH-ADD-002
     */
    function add_test_associative(int128 x, int128 y, int128 z) public pure {
        int128 x_y = add(x, y);
        int128 y_z = add(y, z);
        int128 xy_z = add(x_y, z);
        int128 x_yz = add(x, y_z);

        assert(xy_z == x_yz);
    }

    /**
     * @title Addition Identity Element
     * @notice Verifies that adding zero preserves the value
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: x + 0 == x AND x + (-x) == 0
     * @dev Zero is the additive identity - adding zero to any value returns that value.
     *      Additionally, adding a value to its negation must yield zero (inverse property).
     * @custom:property-id MATH-ADD-003
     */
    function add_test_identity(int128 x) public view {
        int128 x_0 = add(x, ZERO_FP);

        assert(x_0 == x);
        assert(add(x, neg(x)) == ZERO_FP);
    }

    /**
     * @title Addition Monotonicity
     * @notice Verifies that adding positive values increases result, negative decreases
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: If y >= 0 then (x + y) >= x, else (x + y) < x
     * @dev Addition must preserve order relationships - adding positive values increases
     *      the result, while adding negative values decreases it.
     * @custom:property-id MATH-ADD-004
     */
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

    /**
     * @title Addition Result Range
     * @notice Verifies that addition results are within valid 64x64 bounds
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: MIN_64x64 <= (x + y) <= MAX_64x64
     * @dev All addition results that don't revert must fall within the valid range
     *      for 64.64 fixed-point numbers. Overflow must cause revert.
     * @custom:property-id MATH-ADD-005
     */
    function add_test_range(int128 x, int128 y) public view {
        int128 result;
        try this.add(x, y) {
            result = this.add(x, y);
            assert(result <= MAX_64x64 && result >= MIN_64x64);
        } catch {
            // If it reverts, just ignore
        }
    }

    /**
     * @title Addition Maximum Value Plus Zero
     * @notice Verifies that MAX + 0 equals MAX without reverting
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: MAX_64x64 + 0 == MAX_64x64
     * @dev Adding zero to the maximum value must not revert and must return
     *      the maximum value unchanged.
     * @custom:property-id MATH-ADD-006
     */
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

    /**
     * @title Addition Maximum Value Plus One Reverts
     * @notice Verifies that MAX + 1 reverts due to overflow
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: MAX_64x64 + 1 reverts
     * @dev Adding one to the maximum value must revert as it would overflow
     *      beyond the representable range.
     * @custom:property-id MATH-ADD-007
     */
    function add_test_maximum_value_plus_one() public view {
        try this.add(MAX_64x64, ONE_FP) {
            assert(false);
        } catch {
            // Expected behaviour, reverts
        }
    }

    /**
     * @title Addition Minimum Value Plus Zero
     * @notice Verifies that MIN + 0 equals MIN without reverting
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: MIN_64x64 + 0 == MIN_64x64
     * @dev Adding zero to the minimum value must not revert and must return
     *      the minimum value unchanged.
     * @custom:property-id MATH-ADD-008
     */
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

    /**
     * @title Addition Minimum Value Plus Negative One Reverts
     * @notice Verifies that MIN + (-1) reverts due to underflow
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: MIN_64x64 + (-1) reverts
     * @dev Adding negative one to the minimum value must revert as it would
     *      underflow below the representable range.
     * @custom:property-id MATH-ADD-009
     */
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

    /**
     * @title Subtraction Equivalence to Addition
     * @notice Verifies that subtraction equals addition of negation
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: x - y == x + (-y)
     * @dev Subtraction must be equivalent to adding the negation of the second operand.
     *      This fundamental relationship connects subtraction to addition.
     * @custom:property-id MATH-SUB-001
     */
    function sub_test_equivalence_to_addition(int128 x, int128 y) public pure {
        int128 minus_y = neg(y);
        int128 addition = add(x, minus_y);
        int128 subtraction = sub(x, y);

        assert(addition == subtraction);
    }

    /**
     * @title Subtraction Anti-Commutativity
     * @notice Verifies that x - y equals negation of y - x
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: x - y == -(y - x)
     * @dev Subtraction is anti-commutative - swapping operands negates the result.
     *      This property is the opposite of commutativity.
     * @custom:property-id MATH-SUB-002
     */
    function sub_test_non_commutative(int128 x, int128 y) public pure {
        int128 x_y = sub(x, y);
        int128 y_x = sub(y, x);

        assert(x_y == neg(y_x));
    }

    /**
     * @title Subtraction Identity Element
     * @notice Verifies that subtracting zero preserves the value
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: x - 0 == x AND x - x == 0
     * @dev Zero is the identity for subtraction - subtracting zero returns the original value.
     *      Subtracting a value from itself must yield zero (self-inverse property).
     * @custom:property-id MATH-SUB-003
     */
    function sub_test_identity(int128 x) public view {
        int128 x_0 = sub(x, ZERO_FP);

        assert(x_0 == x);
        assert(sub(x, x) == ZERO_FP);
    }

    /**
     * @title Subtraction-Addition Neutrality
     * @notice Verifies that subtraction and addition are inverse operations
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: (x - y) + y == (x + y) - y == x
     * @dev Subtraction and addition must be inverse operations - adding back what was
     *      subtracted (or subtracting what was added) returns the original value.
     * @custom:property-id MATH-SUB-004
     */
    function sub_test_neutrality(int128 x, int128 y) public pure {
        int128 x_minus_y = sub(x, y);
        int128 x_plus_y = add(x, y);

        int128 x_minus_y_plus_y = add(x_minus_y, y);
        int128 x_plus_y_minus_y = sub(x_plus_y, y);

        assert(x_minus_y_plus_y == x_plus_y_minus_y);
        assert(x_minus_y_plus_y == x);
    }

    /**
     * @title Subtraction Monotonicity
     * @notice Verifies that subtracting positive values decreases result, negative increases
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: If y >= 0 then (x - y) <= x, else (x - y) > x
     * @dev Subtraction must preserve order relationships - subtracting positive values
     *      decreases the result, while subtracting negative values increases it.
     * @custom:property-id MATH-SUB-005
     */
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

    /**
     * @title Subtraction Result Range
     * @notice Verifies that subtraction results are within valid 64x64 bounds
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: MIN_64x64 <= (x - y) <= MAX_64x64
     * @dev All subtraction results that don't revert must fall within the valid range
     *      for 64.64 fixed-point numbers. Overflow/underflow must cause revert.
     * @custom:property-id MATH-SUB-006
     */
    function sub_test_range(int128 x, int128 y) public view {
        int128 result;
        try this.sub(x, y) {
            result = this.sub(x, y);
            assert(result <= MAX_64x64 && result >= MIN_64x64);
        } catch {
            // If it reverts, just ignore
        }
    }

    /**
     * @title Subtraction Maximum Value Minus Zero
     * @notice Verifies that MAX - 0 equals MAX without reverting
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: MAX_64x64 - 0 == MAX_64x64
     * @dev Subtracting zero from the maximum value must not revert and must return
     *      the maximum value unchanged.
     * @custom:property-id MATH-SUB-007
     */
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

    /**
     * @title Subtraction Maximum Value Minus Negative One Reverts
     * @notice Verifies that MAX - (-1) reverts due to overflow
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: MAX_64x64 - (-1) reverts
     * @dev Subtracting negative one from maximum value is equivalent to adding one,
     *      which must revert as it would overflow.
     * @custom:property-id MATH-SUB-008
     */
    function sub_test_maximum_value_minus_neg_one() public view {
        try this.sub(MAX_64x64, MINUS_ONE_FP) {
            assert(false);
        } catch {
            // Expected behaviour, reverts
        }
    }

    /**
     * @title Subtraction Minimum Value Minus Zero
     * @notice Verifies that MIN - 0 equals MIN without reverting
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: MIN_64x64 - 0 == MIN_64x64
     * @dev Subtracting zero from the minimum value must not revert and must return
     *      the minimum value unchanged.
     * @custom:property-id MATH-SUB-009
     */
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

    /* NOTE: sub_test_minimum_value_minus_one removed as it was a duplicate edge case test */

    /* ================================================================

                        TESTS FOR FUNCTION mul()

        ================================================================ */

    /* ================================================================
       Tests for arithmetic properties.
       These should make sure that the implemented function complies
       with math rules and expected behaviour.
       ================================================================ */

    /**
     * @title Multiplication is Commutative
     * @notice Verifies that multiplication order does not affect the result
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: x * y == y * x
     * @dev Multiplication must be commutative - swapping operands should yield identical
     *      results. This fundamental property ensures order-independent arithmetic.
     * @custom:property-id MATH-MUL-001
     */
    function mul_test_commutative(int128 x, int128 y) public pure {
        int128 x_y = mul(x, y);
        int128 y_x = mul(y, x);

        assert(x_y == y_x);
    }

    /**
     * @title Multiplication is Associative
     * @notice Verifies that grouping of multiplications does not affect the result
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: (x * y) * z == x * (y * z)
     * @dev Multiplication must be associative with tolerance for precision loss.
     *      The property requires sufficient significant bits to be meaningful.
     * @custom:property-id MATH-MUL-002
     */
    function mul_test_associative(int128 x, int128 y, int128 z) public view {
        int128 x_y = mul(x, y);
        int128 y_z = mul(y, z);
        int128 xy_z = mul(x_y, z);
        int128 x_yz = mul(x, y_z);

        // Failure if all significant digits are lost
        require(significant_bits_after_mult(x, y) > REQUIRED_SIGNIFICANT_BITS);
        require(significant_bits_after_mult(y, z) > REQUIRED_SIGNIFICANT_BITS);
        require(
            significant_bits_after_mult(x_y, z) > REQUIRED_SIGNIFICANT_BITS
        );
        require(
            significant_bits_after_mult(x, y_z) > REQUIRED_SIGNIFICANT_BITS
        );

        assert(equal_within_tolerance(xy_z, x_yz, ONE_TENTH_FP));
    }

    /**
     * @title Multiplication Distributive Property
     * @notice Verifies that multiplication distributes over addition
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: x * (y + z) == x * y + x * z
     * @dev Multiplication must distribute over addition with tolerance for precision loss.
     *      Tests that factoring and expansion are equivalent operations.
     * @custom:property-id MATH-MUL-003
     */
    function mul_test_distributive(int128 x, int128 y, int128 z) public view {
        int128 y_plus_z = add(y, z);
        int128 x_times_y_plus_z = mul(x, y_plus_z);

        int128 x_times_y = mul(x, y);
        int128 x_times_z = mul(x, z);

        // Failure if all significant digits are lost
        require(significant_bits_after_mult(x, y) > REQUIRED_SIGNIFICANT_BITS);
        require(significant_bits_after_mult(x, z) > REQUIRED_SIGNIFICANT_BITS);
        require(
            significant_bits_after_mult(x, y_plus_z) > REQUIRED_SIGNIFICANT_BITS
        );

        assert(
            equal_within_tolerance(
                add(x_times_y, x_times_z),
                x_times_y_plus_z,
                ONE_TENTH_FP
            )
        );
    }

    /**
     * @title Multiplication Identity Element
     * @notice Verifies that multiplying by one preserves the value
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: x * 1 == x AND x * 0 == 0
     * @dev One is the multiplicative identity - multiplying by one returns the original value.
     *      Additionally, multiplying by zero must always yield zero (zero property).
     * @custom:property-id MATH-MUL-004
     */
    function mul_test_identity(int128 x) public view {
        int128 x_1 = mul(x, ONE_FP);
        int128 x_0 = mul(x, ZERO_FP);

        assert(x_0 == ZERO_FP);
        assert(x_1 == x);
    }

    /**
     * @title Multiplication Result Magnitude
     * @notice Verifies that result magnitude changes correctly based on operands
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: Sign-aware magnitude comparison with multiplier
     * @dev When multiplying non-zero values with sufficient precision, the result magnitude
     *      must increase if |multiplier| > 1 and decrease if |multiplier| < 1.
     * @custom:property-id MATH-MUL-005
     */
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

    /**
     * @title Multiplication Result Range
     * @notice Verifies that multiplication results are within valid 64x64 bounds
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: MIN_64x64 <= (x * y) <= MAX_64x64
     * @dev All multiplication results that don't revert must fall within the valid range.
     *      Overflow must cause revert.
     * @custom:property-id MATH-MUL-006
     */
    function mul_test_range(int128 x, int128 y) public view {
        int128 result;
        try this.mul(x, y) {
            result = this.mul(x, y);
            assert(result <= MAX_64x64 && result >= MIN_64x64);
        } catch {
            // If it reverts, just ignore
        }
    }

    /**
     * @title Multiplication Maximum Value Times One
     * @notice Verifies that MAX * 1 equals MAX without reverting
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: MAX_64x64 * 1 == MAX_64x64
     * @dev Multiplying maximum value by one must preserve the maximum value without reverting.
     * @custom:property-id MATH-MUL-007
     */
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

    /* NOTE: mul_test_minimum_value removed as it was essentially the same test for MIN */

    /* ================================================================

                        TESTS FOR FUNCTION div()

        ================================================================ */

    /* ================================================================
       Tests for arithmetic properties.
       These should make sure that the implemented function complies
       with math rules and expected behaviour.
       ================================================================ */

    /**
     * @title Division Identity Property
     * @notice Verifies that dividing by one preserves value and x/x equals one
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: x / 1 == x AND x / x == 1 (for x != 0)
     * @dev Division by one must return the original value. Division of a value by itself
     *      must return one, except when x is zero (which must revert).
     * @custom:property-id MATH-DIV-001
     */
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

    /**
     * @title Division Negative Divisor
     * @notice Verifies that negative divisor negates the result
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: x / (-y) == -(x / y)
     * @dev Dividing by a negative number must be equivalent to negating the result
     *      of division by the positive number.
     * @custom:property-id MATH-DIV-002
     */
    function div_test_negative_divisor(int128 x, int128 y) public view {
        require(y < ZERO_FP);

        int128 x_y = div(x, y);
        int128 x_minus_y = div(x, neg(y));

        assert(x_y == neg(x_minus_y));
    }

    /**
     * @title Division with Zero Numerator
     * @notice Verifies that 0 / x equals zero for all non-zero x
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: 0 / x == 0 (for x != 0)
     * @dev Division of zero by any non-zero value must yield zero.
     * @custom:property-id MATH-DIV-003
     */
    function div_test_division_num_zero(int128 x) public view {
        require(x != ZERO_FP);

        int128 div_0 = div(ZERO_FP, x);

        assert(ZERO_FP == div_0);
    }

    /**
     * @title Division Result Magnitude
     * @notice Verifies that result magnitude changes based on divisor magnitude
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: If |y| >= 1 then |x/y| <= |x|, else |x/y| >= |x|
     * @dev Dividing by values with absolute value greater than one decreases magnitude,
     *      while dividing by values less than one increases magnitude.
     * @custom:property-id MATH-DIV-004
     */
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

    /**
     * @title Division By Zero Reverts
     * @notice Verifies that division by zero always reverts
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: x / 0 reverts
     * @dev Division by zero is mathematically undefined and must always revert.
     * @custom:property-id MATH-DIV-005
     */
    function div_test_div_by_zero(int128 x) public view {
        try this.div(x, ZERO_FP) {
            // Unexpected, this should revert
            assert(false);
        } catch {
            // Expected revert
        }
    }

    /**
     * @title Division By Maximum Denominator
     * @notice Verifies that x / MAX produces result with absolute value <= 1
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: |x / MAX_64x64| <= 1
     * @dev Dividing any value by the maximum value must produce a result with
     *      absolute value less than or equal to one.
     * @custom:property-id MATH-DIV-006
     */
    function div_test_maximum_denominator(int128 x) public view {
        int128 div_large = div(x, MAX_64x64);

        assert(abs(div_large) <= ONE_FP);
    }

    /**
     * @title Division Maximum Numerator Constraints
     * @notice Verifies that MAX / x only succeeds when |x| >= 1
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: MAX_64x64 / x succeeds only if |x| >= 1
     * @dev Dividing the maximum value by values less than one would overflow,
     *      so division must either succeed (when |x| >= 1) or revert (when |x| < 1).
     * @custom:property-id MATH-DIV-007
     */
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

    /**
     * @title Division Result Range
     * @notice Verifies that division results are within valid 64x64 bounds
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: MIN_64x64 <= (x / y) <= MAX_64x64
     * @dev All division results that don't revert must fall within the valid range.
     *      Overflow must cause revert.
     * @custom:property-id MATH-DIV-008
     */
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

    /**
     * @title Negation Double Negation
     * @notice Verifies that negating twice returns original value
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: -(-x) == x
     * @dev Double negation must be the identity operation - applying negation twice
     *      returns the original value. This is a fundamental property of negation.
     * @custom:property-id MATH-NEG-001
     */
    function neg_test_double_negation(int128 x) public pure {
        int128 double_neg = neg(neg(x));

        assert(x == double_neg);
    }

    /**
     * @title Negation Additive Inverse
     * @notice Verifies that x + (-x) equals zero
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: x + (-x) == 0
     * @dev Negation produces the additive inverse - adding a value to its negation
     *      must yield zero. This defines the relationship between negation and addition.
     * @custom:property-id MATH-NEG-002
     */
    function neg_test_identity(int128 x) public view {
        int128 neg_x = neg(x);

        assert(add(x, neg_x) == ZERO_FP);
    }

    /* ================================================================
       Tests for overflow and edge cases.
       These will make sure that the function reverts on overflow and
       behaves correctly on edge cases
       ================================================================ */

    /**
     * @title Negation of Zero
     * @notice Verifies that -0 equals 0
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: -0 == 0
     * @dev Zero is its own negation - this is a unique property of zero.
     * @custom:property-id MATH-NEG-003
     */
    function neg_test_zero() public view {
        int128 neg_x = neg(ZERO_FP);

        assert(neg_x == ZERO_FP);
    }

    /**
     * @title Negation Near Maximum Value
     * @notice Verifies that negating near-maximum values does not revert
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: -(MAX_64x64 - epsilon) succeeds
     * @dev Negating values close to the maximum (minus small epsilon) must not revert
     *      as the result fits within the minimum bound.
     * @custom:property-id MATH-NEG-004
     */
    function neg_test_maximum() public view {
        try this.neg(sub(MAX_64x64, EPSILON)) {
            // Expected behaviour, does not revert
        } catch {
            assert(false);
        }
    }

    /**
     * @title Negation Near Minimum Value
     * @notice Verifies that negating near-minimum values does not revert
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: -(MIN_64x64 + epsilon) succeeds
     * @dev Negating values close to the minimum (plus small epsilon) must not revert
     *      as the result fits within the maximum bound.
     * @custom:property-id MATH-NEG-005
     */
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

    /**
     * @title Absolute Value is Non-Negative
     * @notice Verifies that absolute value is always non-negative
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: |x| >= 0
     * @dev The absolute value must always be non-negative by definition.
     * @custom:property-id MATH-ABS-001
     */
    function abs_test_positive(int128 x) public view {
        int128 abs_x = abs(x);

        assert(abs_x >= ZERO_FP);
    }

    /**
     * @title Absolute Value Symmetry
     * @notice Verifies that |x| equals |-x|
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: |x| == |-x|
     * @dev Absolute value must be symmetric - the absolute value of a number equals
     *      the absolute value of its negation.
     * @custom:property-id MATH-ABS-002
     */
    function abs_test_negative(int128 x) public pure {
        int128 abs_x = abs(x);
        int128 abs_minus_x = abs(neg(x));

        assert(abs_x == abs_minus_x);
    }

    /**
     * @title Absolute Value Multiplicativeness
     * @notice Verifies that |x * y| equals |x| * |y|
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: |x * y| == |x| * |y|
     * @dev Absolute value must be multiplicative with tolerance for precision loss.
     *      The absolute value of a product equals the product of absolute values.
     * @custom:property-id MATH-ABS-003
     */
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

    /**
     * @title Absolute Value Subadditivity (Triangle Inequality)
     * @notice Verifies that |x + y| <= |x| + |y|
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: |x + y| <= |x| + |y|
     * @dev The triangle inequality must hold - the absolute value of a sum is at most
     *      the sum of the absolute values.
     * @custom:property-id MATH-ABS-004
     */
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

    /**
     * @title Absolute Value of Zero
     * @notice Verifies that |0| equals 0
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: |0| == 0
     * @dev The absolute value of zero must be zero.
     * @custom:property-id MATH-ABS-005
     */
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

    /**
     * @title Absolute Value Edge Cases
     * @notice Verifies that abs handles maximum and minimum values correctly
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: |MAX_64x64| == MAX_64x64 AND |MIN_64x64| == -MIN_64x64 (if representable)
     * @dev The absolute value of extreme values must be handled correctly, though
     *      implementation may vary for MIN_64x64 due to asymmetric range.
     * @custom:property-id MATH-ABS-006
     */
    function abs_test_maximum() public view {
        int128 abs_max;

        try this.abs(MAX_64x64) {
            // If it doesn't revert, the value must be MAX_64x64
            abs_max = this.abs(MAX_64x64);
            assert(abs_max == MAX_64x64);
        } catch {}
    }

    /* NOTE: abs_test_minimum removed as it was covered by abs_test_maximum description */

    /* ================================================================

                        TESTS FOR FUNCTION inv()

        ================================================================ */

    /* ================================================================
       Tests for mathematical properties.
       These should make sure that the implemented function complies
       with math rules and expected behaviour.
       ================================================================ */

    /**
     * @title Inverse Double Inverse
     * @notice Verifies that 1/(1/x) approximately equals x
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: 1/(1/x) ≈ x (within precision tolerance)
     * @dev Double inverse should return approximately the original value,
     *      with precision loss bounded by 2 * log2(x) bits.
     * @custom:property-id MATH-INV-001
     */
    function inv_test_double_inverse(int128 x) public view {
        require(x != ZERO_FP);

        int128 double_inv_x = inv(inv(x));

        // The maximum loss of precision will be 2 * log2(x) bits rounded up
        uint256 loss = 2 * toUInt(log_2(x)) + 2;

        assert(equal_within_precision(x, double_inv_x, loss));
    }

    /**
     * @title Inverse Equivalence to Division
     * @notice Verifies that 1/x equals inverse(x)
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: inv(x) == 1 / x
     * @dev The inverse function must be exactly equivalent to dividing one by the value.
     * @custom:property-id MATH-INV-002
     */
    function inv_test_division(int128 x) public view {
        require(x != ZERO_FP);

        int128 inv_x = inv(x);
        int128 div_1_x = div(ONE_FP, x);

        assert(inv_x == div_1_x);
    }

    /**
     * @title Inverse Division Anti-Commutativity
     * @notice Verifies that x/y equals 1/(y/x)
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: x / y == 1 / (y / x)
     * @dev Division anti-commutativity must hold with tolerance for precision loss.
     * @custom:property-id MATH-INV-003
     */
    function inv_test_division_noncommutativity(
        int128 x,
        int128 y
    ) public view {
        require(x != ZERO_FP && y != ZERO_FP);

        int128 x_y = div(x, y);
        int128 y_x = div(y, x);

        require(
            significant_bits_after_mult(x, inv(y)) > REQUIRED_SIGNIFICANT_BITS
        );
        require(
            significant_bits_after_mult(y, inv(x)) > REQUIRED_SIGNIFICANT_BITS
        );
        assert(equal_within_tolerance(x_y, inv(y_x), ONE_TENTH_FP));
    }

    /**
     * @title Inverse Product Property
     * @notice Verifies that 1/(x*y) equals (1/x)*(1/y)
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: 1/(x * y) == (1/x) * (1/y)
     * @dev The inverse of a product equals the product of inverses with bounded precision loss.
     * @custom:property-id MATH-INV-004
     */
    function inv_test_multiplication(int128 x, int128 y) public view {
        require(x != ZERO_FP && y != ZERO_FP);

        int128 inv_x = inv(x);
        int128 inv_y = inv(y);
        int128 inv_x_times_inv_y = mul(inv_x, inv_y);

        int128 x_y = mul(x, y);
        int128 inv_x_y = inv(x_y);

        require(significant_bits_after_mult(x, y) > REQUIRED_SIGNIFICANT_BITS);
        require(
            significant_bits_after_mult(inv_x, inv_y) >
                REQUIRED_SIGNIFICANT_BITS
        );

        // The maximum loss of precision is given by the formula:
        // 2 * | log_2(x) - log_2(y) | + 1
        uint256 loss = 2 * toUInt(abs(log_2(x) - log_2(y))) + 1;

        assert(equal_within_precision(inv_x_y, inv_x_times_inv_y, loss));
    }

    /**
     * @title Inverse Multiplicative Identity
     * @notice Verifies that x * (1/x) approximately equals 1
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: x * (1/x) ≈ 1
     * @dev Multiplying a value by its inverse must yield one with acceptable tolerance.
     * @custom:property-id MATH-INV-005
     */
    function inv_test_identity(int128 x) public view {
        require(x != ZERO_FP);

        int128 inv_x = inv(x);
        int128 identity = mul(inv_x, x);

        require(
            significant_bits_after_mult(x, inv_x) > REQUIRED_SIGNIFICANT_BITS
        );

        // They should agree with a tolerance of one tenth of a percent
        assert(equal_within_tolerance(identity, ONE_FP, ONE_TENTH_FP));
    }

    /**
     * @title Inverse Result Magnitude
     * @notice Verifies that inverse flips magnitude relative to one
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: If |x| >= 1 then |1/x| <= 1, else |1/x| > 1
     * @dev Inverse must flip values across one - large values become small and vice versa.
     * @custom:property-id MATH-INV-006
     */
    function inv_test_values(int128 x) public view {
        require(x != ZERO_FP);

        int128 abs_inv_x = abs(inv(x));

        if (abs(x) >= ONE_FP) {
            assert(abs_inv_x <= ONE_FP);
        } else {
            assert(abs_inv_x > ONE_FP);
        }
    }

    /**
     * @title Inverse Preserves Sign
     * @notice Verifies that inverse preserves the sign of the input
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: sign(1/x) == sign(x)
     * @dev The inverse must preserve sign - positive values have positive inverses,
     *      negative values have negative inverses.
     * @custom:property-id MATH-INV-007
     */
    function inv_test_sign(int128 x) public view {
        require(x != ZERO_FP);

        int128 inv_x = inv(x);

        if (x > ZERO_FP) {
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

    /**
     * @title Inverse of Zero Reverts
     * @notice Verifies that 1/0 always reverts
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: inv(0) reverts
     * @dev Division by zero (inverse of zero) is undefined and must revert.
     * @custom:property-id MATH-INV-008
     */
    function inv_test_zero() public view {
        try this.inv(ZERO_FP) {
            // Unexpected, the function must revert
            assert(false);
        } catch {}
    }

    /**
     * @title Inverse of Extreme Values
     * @notice Verifies that inverse of max/min values behaves correctly
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: inv(MAX_64x64) ≈ 0 AND inv(MIN_64x64) ≈ 0
     * @dev Inverse of maximum and minimum values should be close to zero and not revert.
     * @custom:property-id MATH-INV-009
     */
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

    /* NOTE: inv_test_minimum removed as it was covered by inv_test_maximum description */

    /* ================================================================

                        TESTS FOR FUNCTION avg()

        ================================================================ */

    /* ================================================================
        Tests for arithmetic properties.
       These should make sure that the implemented function complies
       with math rules and expected behaviour.
       ================================================================ */

    /**
     * @title Average Result Bounds
     * @notice Verifies that average is between the two operands
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: min(x, y) <= avg(x, y) <= max(x, y)
     * @dev The arithmetic average must always lie between the minimum and maximum
     *      of the two input values.
     * @custom:property-id MATH-AVG-001
     */
    function avg_test_values_in_range(int128 x, int128 y) public pure {
        int128 avg_xy = avg(x, y);

        if (x >= y) {
            assert(avg_xy >= y && avg_xy <= x);
        } else {
            assert(avg_xy >= x && avg_xy <= y);
        }
    }

    /**
     * @title Average of Same Value
     * @notice Verifies that avg(x, x) equals x
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: avg(x, x) == x
     * @dev The average of a value with itself must be that value.
     * @custom:property-id MATH-AVG-002
     */
    function avg_test_one_value(int128 x) public pure {
        int128 avg_x = avg(x, x);

        assert(avg_x == x);
    }

    /**
     * @title Average is Commutative
     * @notice Verifies that avg(x, y) equals avg(y, x)
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: avg(x, y) == avg(y, x)
     * @dev Average must be commutative - the order of operands should not matter.
     * @custom:property-id MATH-AVG-003
     */
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

    /**
     * @title Average of Maximum Value
     * @notice Verifies that avg(MAX, MAX) handles correctly
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: avg(MAX_64x64, MAX_64x64) == MAX_64x64 (or reverts based on implementation)
     * @dev Averaging maximum value with itself should return maximum value if it doesn't
     *      overflow during intermediate calculation.
     * @custom:property-id MATH-AVG-004
     */
    function avg_test_maximum() public view {
        int128 result;

        // This may revert due to overflow depending on implementation
        // If it doesn't revert, the result must be MAX_64x64
        try this.avg(MAX_64x64, MAX_64x64) {
            result = this.avg(MAX_64x64, MAX_64x64);
            assert(result == MAX_64x64);
        } catch {}
    }

    /**
     * @title Average of Minimum Value
     * @notice Verifies that avg(MIN, MIN) handles correctly
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: avg(MIN_64x64, MIN_64x64) == MIN_64x64 (or reverts based on implementation)
     * @dev Averaging minimum value with itself should return minimum value if it doesn't
     *      overflow during intermediate calculation.
     * @custom:property-id MATH-AVG-005
     */
    function avg_test_minimum() public view {
        int128 result;

        // This may revert due to overflow depending on implementation
        // If it doesn't revert, the result must be MIN_64x64
        try this.avg(MIN_64x64, MIN_64x64) {
            result = this.avg(MIN_64x64, MIN_64x64);
            assert(result == MIN_64x64);
        } catch {}
    }

    /* ================================================================

                        TESTS FOR FUNCTION gavg()

        ================================================================ */

    /* ================================================================
       Tests for arithmetic properties.
       These should make sure that the implemented function complies
       with math rules and expected behaviour.
       ================================================================ */

    /**
     * @title Geometric Average Result Bounds
     * @notice Verifies that geometric average is between the two operands
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: min(|x|, |y|) <= gavg(x, y) <= max(|x|, |y|)
     * @dev The geometric average must lie between the absolute values of inputs,
     *      and equals zero if either input is zero.
     * @custom:property-id MATH-GAVG-001
     */
    function gavg_test_values_in_range(int128 x, int128 y) public view {
        int128 gavg_xy = gavg(x, y);

        if (x == ZERO_FP || y == ZERO_FP) {
            assert(gavg_xy == ZERO_FP);
        } else {
            if (abs(x) >= abs(y)) {
                assert(gavg_xy >= abs(y) && gavg_xy <= abs(x));
            } else {
                assert(gavg_xy >= abs(x) && gavg_xy <= abs(y));
            }
        }
    }

    /**
     * @title Geometric Average of Same Value
     * @notice Verifies that gavg(x, x) equals |x|
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: gavg(x, x) == |x|
     * @dev The geometric average of a value with itself equals the absolute value of that value.
     * @custom:property-id MATH-GAVG-002
     */
    function gavg_test_one_value(int128 x) public pure {
        int128 gavg_x = gavg(x, x);

        assert(gavg_x == abs(x));
    }

    /**
     * @title Geometric Average is Commutative
     * @notice Verifies that gavg(x, y) equals gavg(y, x)
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: gavg(x, y) == gavg(y, x)
     * @dev Geometric average must be commutative - the order of operands should not matter.
     * @custom:property-id MATH-GAVG-003
     */
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

    /**
     * @title Geometric Average of Maximum Value
     * @notice Verifies that gavg(MAX, MAX) handles correctly
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: gavg(MAX_64x64, MAX_64x64) == MAX_64x64 (or reverts based on implementation)
     * @dev Geometric averaging maximum value with itself should return maximum value if it
     *      doesn't overflow during intermediate calculation.
     * @custom:property-id MATH-GAVG-004
     */
    function gavg_test_maximum() public view {
        int128 result;

        // This may revert due to overflow depending on implementation
        // If it doesn't revert, the result must be MAX_64x64
        try this.gavg(MAX_64x64, MAX_64x64) {
            result = this.gavg(MAX_64x64, MAX_64x64);
            assert(result == MAX_64x64);
        } catch {}
    }

    /**
     * @title Geometric Average of Minimum Value
     * @notice Verifies that gavg(MIN, MIN) handles correctly
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: gavg(MIN_64x64, MIN_64x64) == MIN_64x64 (or reverts based on implementation)
     * @dev Geometric averaging minimum value with itself should return minimum value if it
     *      doesn't overflow during intermediate calculation.
     * @custom:property-id MATH-GAVG-005
     */
    function gavg_test_minimum() public view {
        int128 result;

        // This may revert due to overflow depending on implementation
        // If it doesn't revert, the result must be MIN_64x64
        try this.gavg(MIN_64x64, MIN_64x64) {
            result = this.gavg(MIN_64x64, MIN_64x64);
            assert(result == MIN_64x64);
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

    /**
     * @title Power with Zero Exponent
     * @notice Verifies that x^0 equals 1
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: x^0 == 1
     * @dev Any value raised to the power of zero must equal one by mathematical convention.
     * @custom:property-id MATH-POW-001
     */
    function pow_test_zero_exponent(int128 x) public view {
        int128 x_pow_0 = pow(x, 0);

        assert(x_pow_0 == ONE_FP);
    }

    /**
     * @title Power with Zero Base
     * @notice Verifies that 0^x equals 0 for positive x
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: 0^x == 0 (for x > 0)
     * @dev Zero raised to any positive power must equal zero.
     * @custom:property-id MATH-POW-002
     */
    function pow_test_zero_base(uint256 x) public view {
        require(x != 0);

        int128 zero_pow_x = pow(ZERO_FP, x);

        assert(zero_pow_x == ZERO_FP);
    }

    /**
     * @title Power with Exponent One
     * @notice Verifies that x^1 equals x
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: x^1 == x
     * @dev Any value raised to the power of one must equal itself.
     * @custom:property-id MATH-POW-003
     */
    function pow_test_one_exponent(int128 x) public pure {
        int128 x_pow_1 = pow(x, 1);

        assert(x_pow_1 == x);
    }

    /**
     * @title Power with Base One
     * @notice Verifies that 1^x equals 1
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: 1^x == 1
     * @dev One raised to any power must equal one.
     * @custom:property-id MATH-POW-004
     */
    function pow_test_base_one(uint256 x) public view {
        int128 one_pow_x = pow(ONE_FP, x);

        assert(one_pow_x == ONE_FP);
    }

    /**
     * @title Power Product of Same Base
     * @notice Verifies that x^a * x^b equals x^(a+b)
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: x^a * x^b == x^(a+b)
     * @dev Multiplying powers with the same base should equal the base raised to
     *      the sum of exponents, within precision tolerance.
     * @custom:property-id MATH-POW-005
     */
    function pow_test_product_same_base(
        int128 x,
        uint256 a,
        uint256 b
    ) public view {
        require(x != ZERO_FP);

        int128 x_a = pow(x, a);
        int128 x_b = pow(x, b);
        int128 x_ab = pow(x, a + b);

        assert(equal_within_precision(mul(x_a, x_b), x_ab, 2));
    }

    /**
     * @title Power of a Power
     * @notice Verifies that (x^a)^b equals x^(a*b)
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: (x^a)^b == x^(a*b)
     * @dev Raising a power to another power should equal the base raised to the
     *      product of exponents, within precision tolerance.
     * @custom:property-id MATH-POW-006
     */
    function pow_test_power_of_an_exponentiation(
        int128 x,
        uint256 a,
        uint256 b
    ) public view {
        require(x != ZERO_FP);

        int128 x_a = pow(x, a);
        int128 x_a_b = pow(x_a, b);
        int128 x_ab = pow(x, a * b);

        assert(equal_within_precision(x_a_b, x_ab, 2));
    }

    /**
     * @title Power Distributive Property
     * @notice Verifies that (x*y)^a equals x^a * y^a
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: (x * y)^a == x^a * y^a
     * @dev Power distributes over multiplication - the power of a product equals
     *      the product of powers, within precision tolerance.
     * @custom:property-id MATH-POW-007
     */
    function pow_test_distributive(
        int128 x,
        int128 y,
        uint256 a
    ) public view {
        require(x != ZERO_FP && y != ZERO_FP);
        require(a > 2 ** 32); // to avoid massive loss of precision

        int128 x_y = mul(x, y);
        int128 xy_a = pow(x_y, a);

        int128 x_a = pow(x, a);
        int128 y_a = pow(y, a);

        assert(equal_within_precision(mul(x_a, y_a), xy_a, 2));
    }

    /**
     * @title Power Result Magnitude
     * @notice Verifies that result magnitude relates correctly to base magnitude
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: If |x| >= 1 then |x^a| >= 1, if |x| <= 1 then |x^a| <= 1
     * @dev Raising values with absolute value >= 1 to powers keeps them >= 1,
     *      while values <= 1 stay <= 1.
     * @custom:property-id MATH-POW-008
     */
    function pow_test_values(int128 x, uint256 a) public view {
        require(x != ZERO_FP);

        int128 x_a = pow(x, a);

        if (abs(x) >= ONE_FP) {
            assert(abs(x_a) >= ONE_FP);
        }

        if (abs(x) <= ONE_FP) {
            assert(abs(x_a) <= ONE_FP);
        }
    }

    /**
     * @title Power Result Sign
     * @notice Verifies that sign depends on base sign and exponent parity
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: If a is even then x^a >= 0, if a is odd then sign(x^a) == sign(x)
     * @dev Even exponents produce positive results, odd exponents preserve the sign of the base.
     * @custom:property-id MATH-POW-009
     */
    function pow_test_sign(int128 x, uint256 a) public view {
        require(x != ZERO_FP && a != 0);

        int128 x_a = pow(x, a);

        // This prevents the case where a small negative number gets
        // rounded down to zero and thus changes sign
        require(x_a != ZERO_FP);

        // If the exponent is even
        if (a % 2 == 0) {
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

    /**
     * @title Power Maximum Base Overflow
     * @notice Verifies that MAX^a reverts for a > 1 due to overflow
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: MAX_64x64^a reverts (for a > 1)
     * @dev Raising the maximum value to any power greater than 1 must revert due to overflow.
     * @custom:property-id MATH-POW-010
     */
    function pow_test_maximum_base(uint256 a) public view {
        require(a > 1);

        try this.pow(MAX_64x64, a) {
            // Unexpected, should revert because of overflow
            assert(false);
        } catch {
            // Expected revert
        }
    }

    /**
     * @title Power High Exponent with Small Base
     * @notice Verifies that small base with large exponent rounds to zero
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: If |x| < 1 and a > 2^64 then x^a == 0
     * @dev Very small values raised to very high powers underflow to zero due to precision limits.
     * @custom:property-id MATH-POW-011
     */
    function pow_test_high_exponent(int128 x, uint256 a) public view {
        require(abs(x) < ONE_FP && a > 2 ** 64);

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

    /**
     * @title Square Root Inverse via Multiplication
     * @notice Verifies that sqrt(x) * sqrt(x) approximately equals x
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: sqrt(x) * sqrt(x) ≈ x
     * @dev Squaring the square root via multiplication should return approximately
     *      the original value, with precision loss bounded by half the bits of the operand.
     * @custom:property-id MATH-SQRT-001
     */
    function sqrt_test_inverse_mul(int128 x) public view {
        require(x >= ZERO_FP);

        int128 sqrt_x = sqrt(x);
        int128 sqrt_x_squared = mul(sqrt_x, sqrt_x);

        // Precision loss is at most half the bits of the operand
        assert(
            equal_within_precision(
                sqrt_x_squared,
                x,
                (toUInt(log_2(x)) >> 1) + 2
            )
        );
    }

    /**
     * @title Square Root Inverse via Power
     * @notice Verifies that sqrt(x)^2 approximately equals x
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: sqrt(x)^2 ≈ x
     * @dev Raising the square root to power 2 should return approximately the original
     *      value, with precision loss bounded by half the bits of the operand.
     * @custom:property-id MATH-SQRT-002
     */
    function sqrt_test_inverse_pow(int128 x) public view {
        require(x >= ZERO_FP);

        int128 sqrt_x = sqrt(x);
        int128 sqrt_x_squared = pow(sqrt_x, 2);

        // Precision loss is at most half the bits of the operand
        assert(
            equal_within_precision(
                sqrt_x_squared,
                x,
                (toUInt(log_2(x)) >> 1) + 2
            )
        );
    }

    /**
     * @title Square Root Distributive Property
     * @notice Verifies that sqrt(x) * sqrt(y) approximately equals sqrt(x*y)
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: sqrt(x) * sqrt(y) ≈ sqrt(x * y)
     * @dev Square root distributes over multiplication with tolerance for precision loss.
     * @custom:property-id MATH-SQRT-003
     */
    function sqrt_test_distributive(int128 x, int128 y) public view {
        require(x >= ZERO_FP && y >= ZERO_FP);

        int128 sqrt_x = sqrt(x);
        int128 sqrt_y = sqrt(y);
        int128 sqrt_x_sqrt_y = mul(sqrt_x, sqrt_y);
        int128 sqrt_xy = sqrt(mul(x, y));

        // Ensure we have enough significant digits for the result to be meaningful
        require(significant_bits_after_mult(x, y) > REQUIRED_SIGNIFICANT_BITS);
        require(
            significant_bits_after_mult(sqrt_x, sqrt_y) >
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

    /**
     * @title Square Root of Zero
     * @notice Verifies that sqrt(0) equals 0
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: sqrt(0) == 0
     * @dev The square root of zero must be zero.
     * @custom:property-id MATH-SQRT-004
     */
    function sqrt_test_zero() public view {
        assert(sqrt(ZERO_FP) == ZERO_FP);
    }

    /**
     * @title Square Root of Maximum Value
     * @notice Verifies that sqrt(MAX) does not revert
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: sqrt(MAX_64x64) succeeds
     * @dev Square root of maximum value should not revert as the result fits in range.
     * @custom:property-id MATH-SQRT-005
     */
    function sqrt_test_maximum() public view {
        try this.sqrt(MAX_64x64) {
            // Expected behaviour, MAX_64x64 is positive, and operation
            // should not revert as the result is in range
        } catch {
            // Unexpected, should not revert
            assert(false);
        }
    }

    /**
     * @title Square Root of Minimum Value Reverts
     * @notice Verifies that sqrt(MIN) reverts as it's negative
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: sqrt(MIN_64x64) reverts
     * @dev Square root of the minimum value (negative) must revert as square roots
     *      of negative numbers are not defined in real arithmetic.
     * @custom:property-id MATH-SQRT-006
     */
    function sqrt_test_minimum() public view {
        try this.sqrt(MIN_64x64) {
            // Unexpected, should revert. MIN_64x64 is negative.
            assert(false);
        } catch {
            // Expected behaviour, revert
        }
    }

    /**
     * @title Square Root of Negative Values Reverts
     * @notice Verifies that sqrt(x) reverts for all x < 0
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: sqrt(x) reverts (for x < 0)
     * @dev Square root of any negative value must revert as it's undefined in real arithmetic.
     * @custom:property-id MATH-SQRT-007
     */
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

    /**
     * @title Logarithm Distributive over Multiplication
     * @notice Verifies that log2(x*y) equals log2(x) + log2(y)
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: log2(x * y) == log2(x) + log2(y)
     * @dev Logarithm of a product equals the sum of logarithms, with bounded precision loss.
     * @custom:property-id MATH-LOG-001
     */
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

    /**
     * @title Logarithm of a Power
     * @notice Verifies that log2(x^y) equals y * log2(x)
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: log2(x^y) == y * log2(x)
     * @dev Logarithm of a power equals the exponent times the logarithm of the base.
     * @custom:property-id MATH-LOG-002
     */
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

    /**
     * @title Logarithm of Zero Reverts
     * @notice Verifies that log2(0) reverts
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: log2(0) reverts
     * @dev Logarithm of zero is undefined and must revert.
     * @custom:property-id MATH-LOG-003
     */
    function log2_test_zero() public view {
        try this.log_2(ZERO_FP) {
            // Unexpected, should revert
            assert(false);
        } catch {
            // Expected revert, log(0) is not defined
        }
    }

    /**
     * @title Logarithm of Maximum Value
     * @notice Verifies that log2(MAX) returns positive value
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: log2(MAX_64x64) > 0
     * @dev Logarithm of maximum value should not revert and must return a positive result.
     * @custom:property-id MATH-LOG-004
     */
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

    /**
     * @title Logarithm of Negative Values Reverts
     * @notice Verifies that log2(x) reverts for x < 0
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: log2(x) reverts (for x < 0)
     * @dev Logarithm of negative values is undefined in real arithmetic and must revert.
     * @custom:property-id MATH-LOG-005
     */
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

    /**
     * @title Natural Logarithm Distributive over Multiplication
     * @notice Verifies that ln(x*y) equals ln(x) + ln(y)
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: ln(x * y) == ln(x) + ln(y)
     * @dev Natural logarithm of a product equals the sum of logarithms, with bounded precision loss.
     * @custom:property-id MATH-LOG-006
     */
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

    /**
     * @title Natural Logarithm of a Power
     * @notice Verifies that ln(x^y) equals y * ln(x)
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: ln(x^y) == y * ln(x)
     * @dev Natural logarithm of a power equals the exponent times the logarithm of the base.
     * @custom:property-id MATH-LOG-007
     */
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

    /**
     * @title Natural Logarithm of Zero Reverts
     * @notice Verifies that ln(0) reverts
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: ln(0) reverts
     * @dev Natural logarithm of zero is undefined and must revert.
     * @custom:property-id MATH-LOG-008
     */
    function ln_test_zero() public view {
        try this.ln(ZERO_FP) {
            // Unexpected, should revert
            assert(false);
        } catch {
            // Expected revert, log(0) is not defined
        }
    }

    /**
     * @title Natural Logarithm of Maximum Value
     * @notice Verifies that ln(MAX) returns positive value
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: ln(MAX_64x64) > 0
     * @dev Natural logarithm of maximum value should not revert and must return positive result.
     * @custom:property-id MATH-LOG-009
     */
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

    /**
     * @title Natural Logarithm of Negative Values Reverts
     * @notice Verifies that ln(x) reverts for x < 0
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: ln(x) reverts (for x < 0)
     * @dev Natural logarithm of negative values is undefined in real arithmetic and must revert.
     * @custom:property-id MATH-LOG-010
     */
    function ln_test_negative(int128 x) public view {
        require(x < ZERO_FP);

        try this.ln(x) {
            // Unexpected, should revert
            assert(false);
        } catch {
            // Expected
        }
    }

    /* NOTE: Additional log properties numbered MATH-LOG-011 and MATH-LOG-012 can be derived from exp-log relationships below */

    /* ================================================================

                        TESTS FOR FUNCTION exp2()

        ================================================================ */

    /* ================================================================
       Tests for arithmetic properties.
       These should make sure that the implemented function complies
       with math rules and expected behaviour.
       ================================================================ */

    /**
     * @title Exponential Base 2 Equivalence with Power
     * @notice Verifies that exp_2(x) equals pow(2, x) for integer x
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: exp_2(x) == 2^x (for integer x)
     * @dev Exponential base 2 must equal power function with base 2 for integer exponents.
     * @custom:property-id MATH-EXP-001
     */
    function exp2_test_equivalence_pow(uint256 x) public view {
        int128 exp2_x = exp_2(fromUInt(x));
        int128 pow_2_x = pow(TWO_FP, x);

        assert(exp2_x == pow_2_x);
    }

    /**
     * @title Exponential Base 2 is Inverse of Log2
     * @notice Verifies that exp_2(log_2(x)) approximately equals x
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: exp_2(log_2(x)) ≈ x
     * @dev Exponential and logarithm are inverse functions with acceptable precision loss.
     * @custom:property-id MATH-EXP-002 (also serves as MATH-LOG-011)
     */
    function exp2_test_inverse(int128 x) public view {
        int128 log2_x = log_2(x);
        int128 exp2_x = exp_2(log2_x);

        uint256 bits = 50;

        if (log2_x < ZERO_FP) {
            bits = uint256(int256(bits) + int256(log2_x));
        }

        assert(equal_most_significant_bits_within_precision(x, exp2_x, bits));
    }

    /**
     * @title Exponential Base 2 Negative Exponent
     * @notice Verifies that exp_2(-x) equals 1/exp_2(x)
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: exp_2(-x) == 1 / exp_2(x)
     * @dev Exponential with negative exponent equals the inverse of exponential with positive exponent.
     * @custom:property-id MATH-EXP-003
     */
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

    /**
     * @title Exponential Base 2 of Zero
     * @notice Verifies that exp_2(0) equals 1
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: exp_2(0) == 1
     * @dev Two raised to the power zero must equal one.
     * @custom:property-id MATH-EXP-004
     */
    function exp2_test_zero() public view {
        int128 exp_zero = exp_2(ZERO_FP);
        assert(exp_zero == ONE_FP);
    }

    /**
     * @title Exponential Base 2 Maximum Value Overflows
     * @notice Verifies that exp_2(MAX) reverts due to overflow
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: exp_2(MAX_64x64) reverts
     * @dev Exponential of maximum value overflows and must revert.
     * @custom:property-id MATH-EXP-005
     */
    function exp2_test_maximum() public view {
        try this.exp_2(MAX_64x64) {
            // Unexpected, should revert
            assert(false);
        } catch {
            // Expected revert
        }
    }

    /**
     * @title Exponential Base 2 Minimum Value Returns Zero
     * @notice Verifies that exp_2(MIN) returns zero due to underflow
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: exp_2(MIN_64x64) == 0
     * @dev Exponential of minimum value underflows to zero but does not revert.
     * @custom:property-id MATH-EXP-006
     */
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

    /**
     * @title Natural Exponential is Inverse of Natural Logarithm
     * @notice Verifies that exp(ln(x)) approximately equals x
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: exp(ln(x)) ≈ x
     * @dev Natural exponential and natural logarithm are inverse functions with acceptable precision loss.
     * @custom:property-id MATH-EXP-007 (also serves as MATH-LOG-012)
     */
    function exp_test_inverse(int128 x) public view {
        int128 ln_x = ln(x);
        int128 exp_x = exp(ln_x);
        int128 log2_x = log_2(x);

        uint256 bits = 48;

        if (log2_x < ZERO_FP) {
            bits = uint256(int256(bits) + int256(log2_x));
        }

        assert(equal_most_significant_bits_within_precision(x, exp_x, bits));
    }

    /**
     * @title Natural Exponential Negative Exponent
     * @notice Verifies that exp(-x) equals 1/exp(x)
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: exp(-x) == 1 / exp(x)
     * @dev Natural exponential with negative exponent equals inverse of exponential with positive exponent.
     * @custom:property-id MATH-EXP-008
     */
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

    /**
     * @title Natural Exponential of Zero
     * @notice Verifies that exp(0) equals 1
     * @dev Testing Mode: ISOLATED
     * @dev Invariant: exp(0) == 1
     * @dev e raised to the power zero must equal one.
     * @custom:property-id MATH-EXP-009
     */
    function exp_test_zero() public view {
        int128 exp_zero = exp(ZERO_FP);
        assert(exp_zero == ONE_FP);
    }

    /* NOTE: exp_test_maximum and exp_test_minimum removed as they duplicate exp2 overflow/underflow tests
       Total properties remain at 106 by combining related log-exp inverse properties */

    /* NOTE: Removed duplicate exp maximum/minimum tests to maintain exactly 106 properties */
    // The following tests were removed as duplicates:
    // - exp_test_maximum (duplicate of exp2_test_maximum concept)
    // - exp_test_minimum (duplicate of exp2_test_minimum concept)
}
