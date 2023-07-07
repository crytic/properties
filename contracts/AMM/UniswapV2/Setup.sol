pragma solidity ^0.6.0;

import "./uni-v2/UniswapV2ERC20.sol";
import "./uni-v2/UniswapV2Pair.sol";
import "./uni-v2/UniswapV2Factory.sol";
import "./uni-v2/UniswapV2Router01.sol";
import "./libraries/UniswapV2Library.sol";
import "./libraries/WETH.sol";

contract Users {
    function proxy(
        address target,
        bytes memory data
    ) public returns (bool success, bytes memory retData) {
        return target.call(data);
    }
}

contract Setup {
    UniswapV2Factory factory;
    UniswapV2Pair pair;
    UniswapV2ERC20 testToken1;
    UniswapV2ERC20 testToken2;
    UniswapV2Router01 router;
    WETH9 weth;
    Users user;
    bool completed;

    constructor() public {
        weth = new WETH9();
        testToken1 = new UniswapV2ERC20();
        testToken2 = new UniswapV2ERC20();
        factory = new UniswapV2Factory(address(this));
        pair = UniswapV2Pair(
            factory.createPair(address(testToken1), address(testToken2))
        );
        router = new UniswapV2Router01(address(factory), address(weth));

        // Sort the test tokens we just created, for clarity when writing invariant tests later
        (address testTokenA, address testTokenB) = UniswapV2Library.sortTokens(
            address(testToken1),
            address(testToken2)
        );
        testToken1 = UniswapV2ERC20(testTokenA);
        testToken2 = UniswapV2ERC20(testTokenB);
        user = new Users();
        user.proxy(
            address(testToken1),
            abi.encodeWithSelector(
                testToken1.approve.selector,
                address(pair),
                uint(-1)
            )
        );
        user.proxy(
            address(testToken2),
            abi.encodeWithSelector(
                testToken2.approve.selector,
                address(pair),
                uint(-1)
            )
        );
        user.proxy(
            address(testToken1),
            abi.encodeWithSelector(
                testToken1.approve.selector,
                address(router),
                uint(-1)
            )
        );
        user.proxy(
            address(testToken2),
            abi.encodeWithSelector(
                testToken2.approve.selector,
                address(router),
                uint(-1)
            )
        );
    }

    function _init(uint amount1, uint amount2) internal {
        testToken1.mint(address(user), amount1);
        testToken2.mint(address(user), amount2);
        completed = true;
    }

    function _between(
        uint val,
        uint low,
        uint high
    ) internal pure returns (uint) {
        return low + (val % (high - low + 1));
    }
}
