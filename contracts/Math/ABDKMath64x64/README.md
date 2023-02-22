# ABDKMath64x64 test suite for Echidna

## What is ABDKMath64x64?
The Solidity smart contract programming language does not have any inbuilt feature for working with decimal numbers, so for contracts dealing with non-integer values, a third party solution is needed. ABDKMath64x64 is a fixed-point arithmetic Solidity library that operates on 64.64-bit numbers. This library was developed by [ABDK Consulting](https://abdk.consulting/ "ABDK Consulting") and is [open source](https://github.com/abdk-consulting/abdk-libraries-solidity "open source") under the BSD License.

A 64.64-bit fixed-point number is a data type that consists of a sign bit, a 63-bit integer part, and a 64bit decimal part. Since there is no direct support for fractional numbers in the EVM, the underlying data type that stores the values is a 128-bit signed integer.

ABDKMath64x64 library implements [19 arithmetic operations](https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.md#simple-arithmetic "19 arithmetic operations") using fixed-point numbers and [6 conversion functions](https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.md#conversions "6 conversion functions") between integer types and fixed-point types.

## Why are tests needed?

Solidity libraries are used in smart contracts that at some point in time can hold important value in tokens or other assets. The security of those assets is directly related to the robustness and reliability of the smart contract source code.

While testing does not guarantee the absence of errors, it helps the developers in assessing what the risky operations are, how they work, and ultimately how can they fail. Furthermore, having a working test suite with common and edge cases is useful to ensure that code does not behave unexpectedly, and that future versions of the library do not break compatibility.

Echidna testing can be integrated into CI/CD pipelines, so bugs are caught early and the developers are notified about security risks in their contracts.

## Who are these tests designed for?

In principle, these tests are meant to be an entry level practice to learn how to use Echidna for assertion-based fuzz tests, targeting a stand-alone library. It is a self contained exercise that shows how to determine the contract invariants, create proper tests, and configure the relevant Echidna parameters for the campaign.

Determining the invariants is a process that involves an intermediate-level comprehension of the library and the math properties behind the operations implemented. For example, the addition function has the `x+y == y+x` commutative property. This statement should always be true, no matter the values of `x` and `y`, therefore it should be a good invariant for the system. More complex operations can demand more complex invariants.

The next step, creating the tests, means to implement Solidity functions that verify the previously defined invariants. Echidna is a fuzz tester, so it can quickly test different values for the arguments of a function. For example, the commutative property can be tested using a function that takes two parameters and performs the additions, as shown below:
```solidity
    // Test for commutative property
    // x + y == y + x
    function add_test_commutative(int128 x, int128 y) public {
        int128 x_y = add(x, y);
        int128 y_x = add(y, x);

        assert(x_y == y_x);
    }
```

Finally, the fuzzer has to be instructed to perform the correct type of test, the number of test runs to be made, among other configuration parameters. Since the invariant is checked using an assertion, Echidna must be configured to try to find assertion violations. In this mode, different argument values are passed to `add_test_commutative()`, and the result of the `assert(x_y == y_x)` expression is evaluated for each call: if the assertion is false, the invariant was broken, and it is a sign that there can be an issue with the library implementation.

However, even if this particular test suite is meant as an exercise, it can be used as a template to create tests for other fixed-point arithmetic libraries implementations. 