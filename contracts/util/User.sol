pragma solidity ^0.8.0;

contract User {
    function proxy(
        address _target,
        bytes memory _calldata
    ) public returns (bool success, bytes memory returnData) {
        (success, returnData) = _target.call(_calldata);
    }

    function proxy(
        address _target,
        bytes memory _calldata,
        uint256 _value
    ) public returns (bool success, bytes memory returnData) {
        (success, returnData) = _target.call{value: _value}(_calldata);
    }

    receive() external payable {}
}