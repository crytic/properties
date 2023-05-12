# PRBMath test suite for Echidna

## What is PRBMath?

The Solidity smart contract programming language does not have any inbuilt feature for working with decimal numbers, so for contracts dealing with non-integer values, a third party solution is needed. PRBMath is a fixed-point arithmetic Solidity library that operates on signed 59x18-decimal fixed-point and unsigned 60.18-decimal fixed-point numbers. This library was developed by [Paul Razvan Berg](https://github.com/PaulRBerg "Paul Razvan Berg") and is [open source](https://github.com/PaulRBerg/prb-math "open source") under the MIT License.

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
function add_test_commutative(SD59x18 x, SD59x18 y) public pure {
    SD59x18 x_y = x.add(y);
    SD59x18 y_x = y.add(x);

    assert(x_y.eq(y_x));
}
```

Finally, the fuzzer has to be instructed to perform the correct type of test, the number of test runs to be made, among other configuration parameters. Since the invariant is checked using an assertion, Echidna must be configured to try to find assertion violations. In this mode, different argument values are passed to `add_test_commutative()`, and the result of the `assert(x_y == y_x)` expression is evaluated for each call: if the assertion is false, the invariant was broken, and it is a sign that there can be an issue with the library implementation.

However, even if this particular test suite is meant as an exercise, it can be used as a template to create tests for other fixed-point arithmetic libraries implementations.
