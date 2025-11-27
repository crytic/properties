// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

/**
 * @title Simple Mock Concentrated Liquidity Pool
 * @notice Minimal implementation for property testing
 * @dev This is a simplified mock for demonstration purposes only
 */
contract SimpleMockPool {
    // Pool state
    uint160 public sqrtPriceX96;
    int24 public tick;
    uint128 public liquidity;
    int24 public immutable tickSpacing;

    // Tick data
    struct TickInfo {
        uint128 liquidityGross;
        int128 liquidityNet;
        bool initialized;
    }
    mapping(int24 => TickInfo) public ticks;

    // Position data
    struct PositionInfo {
        uint128 liquidity;
    }
    mapping(bytes32 => PositionInfo) public positions;

    // Constants
    int24 internal constant MIN_TICK = -887272;
    int24 internal constant MAX_TICK = 887272;
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    constructor(int24 _tickSpacing) {
        tickSpacing = _tickSpacing;
        // Initialize at mid-range price
        sqrtPriceX96 = 79228162514264337593543950336; // sqrt(1) * 2^96
        tick = 0;
        liquidity = 0;
    }

    /**
     * @notice Get slot0 data (Uniswap V3 compatibility)
     */
    function slot0()
        external
        view
        returns (
            uint160 _sqrtPriceX96,
            int24 _tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        )
    {
        _sqrtPriceX96 = sqrtPriceX96;
        _tick = tick;
        observationIndex = 0;
        observationCardinality = 0;
        observationCardinalityNext = 0;
        feeProtocol = 0;
        unlocked = true;
    }

    /**
     * @notice Mint a liquidity position
     */
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata /* data */
    ) external returns (uint256 amount0, uint256 amount1) {
        require(amount > 0, "Amount must be positive");
        require(tickLower < tickUpper, "Invalid tick range");
        require(tickLower % tickSpacing == 0, "tickLower not aligned");
        require(tickUpper % tickSpacing == 0, "tickUpper not aligned");

        // Update tick data
        _updateTick(tickLower, int128(amount), false);
        _updateTick(tickUpper, -int128(amount), false);

        // Update position
        bytes32 positionKey = keccak256(abi.encodePacked(recipient, tickLower, tickUpper));
        positions[positionKey].liquidity += amount;

        // Update current liquidity if in range
        if (tick >= tickLower && tick < tickUpper) {
            liquidity += amount;
        }

        // For simplicity, return fixed amounts
        amount0 = 1000;
        amount1 = 1000;
    }

    /**
     * @notice Burn a liquidity position
     */
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1) {
        require(amount > 0, "Amount must be positive");

        // Update tick data
        _updateTick(tickLower, -int128(amount), false);
        _updateTick(tickUpper, int128(amount), false);

        // Update position
        bytes32 positionKey = keccak256(abi.encodePacked(msg.sender, tickLower, tickUpper));
        require(positions[positionKey].liquidity >= amount, "Insufficient liquidity");
        positions[positionKey].liquidity -= amount;

        // Update current liquidity if in range
        if (tick >= tickLower && tick < tickUpper) {
            require(liquidity >= amount, "Insufficient pool liquidity");
            liquidity -= amount;
        }

        // For simplicity, return fixed amounts
        amount0 = 1000;
        amount1 = 1000;
    }

    /**
     * @notice Swap tokens (simplified)
     */
    function swap(
        address /* recipient */,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata /* data */
    ) external returns (int256 amount0, int256 amount1) {
        require(amountSpecified != 0, "Invalid amount");

        // Simple price update logic (not production-ready)
        if (zeroForOne) {
            // Price goes down
            uint160 newPrice = sqrtPriceX96 > 1000000 ? sqrtPriceX96 - 1000000 : MIN_SQRT_RATIO;
            if (sqrtPriceLimitX96 > 0 && newPrice < sqrtPriceLimitX96) {
                newPrice = sqrtPriceLimitX96;
            }
            sqrtPriceX96 = newPrice;
            tick = tick > -100 ? tick - 1 : tick;
        } else {
            // Price goes up
            uint160 newPrice = sqrtPriceX96 < MAX_SQRT_RATIO - 1000000
                ? sqrtPriceX96 + 1000000
                : MAX_SQRT_RATIO - 1;
            if (sqrtPriceLimitX96 > 0 && newPrice > sqrtPriceLimitX96) {
                newPrice = sqrtPriceLimitX96;
            }
            sqrtPriceX96 = newPrice;
            tick = tick < 100 ? tick + 1 : tick;
        }

        // For simplicity, return fixed amounts
        amount0 = zeroForOne ? amountSpecified : -amountSpecified;
        amount1 = zeroForOne ? -amountSpecified : amountSpecified;
    }

    /**
     * @notice Update tick data
     */
    function _updateTick(
        int24 _tick,
        int128 liquidityDelta,
        bool /* upper */
    ) internal {
        TickInfo storage tickInfo = ticks[_tick];

        uint128 liquidityGrossBefore = tickInfo.liquidityGross;
        int128 liquidityNetBefore = tickInfo.liquidityNet;

        uint128 liquidityGrossAfter = liquidityDelta < 0
            ? liquidityGrossBefore - uint128(-liquidityDelta)
            : liquidityGrossBefore + uint128(liquidityDelta);

        int128 liquidityNetAfter = liquidityNetBefore + liquidityDelta;

        tickInfo.liquidityGross = liquidityGrossAfter;
        tickInfo.liquidityNet = liquidityNetAfter;

        if (!tickInfo.initialized && liquidityGrossAfter > 0) {
            tickInfo.initialized = true;
        } else if (tickInfo.initialized && liquidityGrossAfter == 0) {
            tickInfo.initialized = false;
        }
    }
}
