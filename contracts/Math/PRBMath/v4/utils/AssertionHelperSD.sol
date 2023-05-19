pragma solidity ^0.8.0;

import { SD59x18 } from "@prb/math/SD59x18.sol";

import { convert } from "@prb/math/sd59x18/Conversions.sol";
import { add, sub, eq, gt, gte, lt, lte, rshift } from "@prb/math/sd59x18/Helpers.sol";
import { mul, div, abs } from "@prb/math/sd59x18/Math.sol";

abstract contract AssertionHelperSD {
    event AssertEqFailure(string);
    event AssertGtFailure(string);
    event AssertGteFailure(string);
    event AssertLtFailure(string);
    event AssertLteFailure(string);

    function assertEq(SD59x18 a, SD59x18 b) internal {
        if (!a.eq(b)) {
            string memory str_a = toString(SD59x18.unwrap(a));
            string memory str_b = toString(SD59x18.unwrap(b));

            bytes memory assertMsg = abi.encodePacked(
                "Invalid: ",
                str_a,
                " != ",
                str_b,
                ". No precision loss allowed."
            );
            emit AssertEqFailure(string(assertMsg));
            assert(false);
        }
    }

    function assertEqWithinBitPrecision(SD59x18 a, SD59x18 b, uint256 precision_bits) internal {
        SD59x18 max = gt(a , b) ? a : b;
        SD59x18 min = gt(a , b) ? b : a;
        SD59x18 r = rshift(sub(max, min), precision_bits);
        
        if (!eq(r, convert(0))) {
            string memory str_a = toString(SD59x18.unwrap(a));
            string memory str_b = toString(SD59x18.unwrap(b));
            string memory str_bits = toString(precision_bits);

            bytes memory assertMsg = abi.encodePacked(
                "Invalid: ",
                str_a,
                " != ",
                str_b,
                " within ",
                str_bits,
                " bits of precision"
            );
            emit AssertEqFailure(string(assertMsg));
            assert(false);
        }
    }

    function assertEqWithinTolerance(SD59x18 a, SD59x18 b, SD59x18 error_percent, string memory str_percent) internal {
        SD59x18 tol_value = mul(a, div(error_percent, convert(100)));

        require(tol_value.neq(convert(0)));

        if (!lte(sub(b, a), abs(tol_value))) {
            string memory str_a = toString(SD59x18.unwrap(a));
            string memory str_b = toString(SD59x18.unwrap(b));
            string memory tolerance = toString(SD59x18.unwrap(abs(tol_value)));
            bytes memory assertMsg = abi.encodePacked(
                "Invalid: ",
                str_a,
                " != ",
                str_b,
                " within ",
                str_percent,
                " tolerance: ",
                tolerance
            );
            emit AssertEqFailure(string(assertMsg));
            assert(false);
        }
    }

    // Returns true if the n most significant bits of a and b are almost equal 
    // Uses functions from the library under test!
    function assertEqWithinDecimalPrecision(SD59x18 a, SD59x18 b, uint256 digits) internal {
       // Divide both number by digits to truncate the unimportant digits
       int256 a_int = SD59x18.unwrap(a);
       int256 b_int = SD59x18.unwrap(b);

       int256 denominator = int256(10 ** digits);

       int256 a_significant = a_int / denominator;
       int256 b_significant = b_int / denominator;

       int256 larger = a_significant > b_significant ? a_significant : b_significant;
       int256 smaller = a_significant > b_significant ? b_significant : a_significant;
       
       if (!((larger - smaller) <= 1)) {
            string memory str_a = toString(a_int);
            string memory str_b = toString(b_int);
            string memory str_larger = toString(larger);
            string memory str_smaller = toString(smaller);
            string memory str_digits = toString(digits);
            string memory difference = toString(larger - smaller);

            bytes memory assertMsg = abi.encodePacked(
                "Invalid: ",
                str_a,
                " != ",
                str_b,
                " within ",
                str_digits,
                " digits of precision.  Difference: ",
                difference,
                ", truncated input:",
                str_larger,
                " != ",
                str_smaller
            );
            emit AssertEqFailure(string(assertMsg));
            assert(false);
       }
    }

    function assertGt(SD59x18 a, SD59x18 b, string memory reason) internal {
        if (!a.gt(b)) {
            string memory str_a = toString(SD59x18.unwrap(a));
            string memory str_b = toString(SD59x18.unwrap(b));

            bytes memory assertMsg = abi.encodePacked(
                "Invalid: ",
                str_a,
                " <= ",
                str_b,
                ", reason: ",
                reason
            );
            emit AssertGtFailure(string(assertMsg));
            assert(false);
        }
    }

    function assertGt(SD59x18 a, SD59x18 b) internal {
        if (!a.gt(b)) {
            string memory str_a = toString(SD59x18.unwrap(a));
            string memory str_b = toString(SD59x18.unwrap(b));

            bytes memory assertMsg = abi.encodePacked(
                "Invalid: ",
                str_a,
                " <= ",
                str_b
            );
            emit AssertGtFailure(string(assertMsg));
            assert(false);
        }
    }

    function assertGte(SD59x18 a, SD59x18 b, string memory reason) internal {
        if (!a.gte(b)) {
            string memory str_a = toString(SD59x18.unwrap(a));
            string memory str_b = toString(SD59x18.unwrap(b));

            bytes memory assertMsg = abi.encodePacked(
                "Invalid: ",
                str_a,
                " < ",
                str_b,
                ", reason: ",
                reason
            );
            emit AssertGteFailure(string(assertMsg));
            assert(false);
        }
    }

    function assertGte(SD59x18 a, SD59x18 b) internal {
        if (!a.gte(b)) {
            string memory str_a = toString(SD59x18.unwrap(a));
            string memory str_b = toString(SD59x18.unwrap(b));

            bytes memory assertMsg = abi.encodePacked(
                "Invalid: ",
                str_a,
                " < ",
                str_b
            );
            emit AssertGteFailure(string(assertMsg));
            assert(false);
        }
    }

    function assertLt(SD59x18 a, SD59x18 b, string memory reason) internal {
        if (!a.lt(b)) {
            string memory str_a = toString(SD59x18.unwrap(a));
            string memory str_b = toString(SD59x18.unwrap(b));

            bytes memory assertMsg = abi.encodePacked(
                "Invalid: ",
                str_a,
                " >= ",
                str_b,
                ", reason: ",
                reason
            );
            emit AssertLtFailure(string(assertMsg));
            assert(false);
        }
    }

    function assertLt(SD59x18 a, SD59x18 b) internal {
        if (!a.lt(b)) {
            string memory str_a = toString(SD59x18.unwrap(a));
            string memory str_b = toString(SD59x18.unwrap(b));

            bytes memory assertMsg = abi.encodePacked(
                "Invalid: ",
                str_a,
                " >= ",
                str_b
            );
            emit AssertLtFailure(string(assertMsg));
            assert(false);
        }
    }

    function assertLte(SD59x18 a, SD59x18 b, string memory reason) internal {
        if (!a.lte(b)) {
            string memory str_a = toString(SD59x18.unwrap(a));
            string memory str_b = toString(SD59x18.unwrap(b));

            bytes memory assertMsg = abi.encodePacked(
                "Invalid: ",
                str_a,
                " > ",
                str_b,
                ", reason: ",
                reason
            );
            emit AssertLteFailure(string(assertMsg));
            assert(false);
        }
    }

    function assertLte(SD59x18 a, SD59x18 b) internal {
        if (!a.lte(b)) {
            string memory str_a = toString(SD59x18.unwrap(a));
            string memory str_b = toString(SD59x18.unwrap(b));

            bytes memory assertMsg = abi.encodePacked(
                "Invalid: ",
                str_a,
                " > ",
                str_b
            );
            emit AssertLteFailure(string(assertMsg));
            assert(false);
        }
    }

    function toString(int256 value) internal pure returns (string memory str) {
        uint256 absValue = value >= 0 ? uint256(value) : uint256(-value);
        str = toString(absValue);

        if (value < 0) {
            str = string(abi.encodePacked("-", str));
        }
    }

    function toString(uint256 value) internal pure returns (string memory str) {
        /// @solidity memory-safe-assembly
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but we allocate 160 bytes
            // to keep the free memory pointer word aligned. We'll need 1 word for the length, 1 word for the
            // trailing zeros padding, and 3 other words for a max of 78 digits. In total: 5 * 32 = 160 bytes.
            let newFreeMemoryPointer := add(mload(0x40), 160)

            // Update the free memory pointer to avoid overriding our string.
            mstore(0x40, newFreeMemoryPointer)

            // Assign str to the end of the zone of newly allocated memory.
            str := sub(newFreeMemoryPointer, 32)

            // Clean the last word of memory it may not be overwritten.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                // Move the pointer 1 byte to the left.
                str := sub(str, 1)

                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))

                // Keep dividing temp until zero.
                temp := div(temp, 10)

                 // prettier-ignore
                if iszero(temp) { break }
            }

            // Compute and cache the final total length of the string.
            let length := sub(end, str)

            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 32)

            // Store the string's length at the start of memory allocated for our string.
            mstore(str, length)
        }
    }
}