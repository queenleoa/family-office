// src/WhalePoolWrapper.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {BaseHook} from "@openzeppelin/uniswap-hooks/src/base/BaseHook.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {SafeCast} from "@uniswap/v4-core/src/libraries/SafeCast.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {StateLibrary} from "@uniswap/v4-core/src/libraries/StateLibrary.sol";
import {ModifyLiquidityParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Additional functions to add to WhalePoolWrapper.sol to act as single LP

contract WhalePoolWrapper is BaseHook {
    // ... existing code ...

    // Add these imports at the top:
    // import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
    // import {Position as V4Position} from "@uniswap/v4-core/src/libraries/Position.sol";
    // import {FixedPoint128} from "@uniswap/v4-core/src/libraries/FixedPoint128.sol";
    // import {LiquidityAmounts} from "@uniswap/v4-core/src/libraries/LiquidityAmounts.sol";

    // ========== NEW: Core LP Functions ==========
    
    /**
     * @dev Deploy collected family funds across multiple positions
     * This makes the contract act as a single LP managing multiple positions
     */
    function deployLiquidity(PoolKey calldata key) external returns (uint256 totalLiquidityDeployed) {
        PoolId poolId = key.toId();
        uint256 totalPYUSD = IERC20(Currency.unwrap(key.currency0)).balanceOf(address(this));
        uint256 totalWETH = IERC20(Currency.unwrap(key.currency1)).balanceOf(address(this));
        
        require(totalPYUSD > 0, "No PYUSD to deploy");
        
        // Get current price
        (uint160 sqrtPriceX96, int24 currentTick,,) = poolManager.getSlot0(poolId);
        
        // First approve tokens to pool manager
        IERC20(Currency.unwrap(key.currency0)).approve(address(poolManager), totalPYUSD);
        if (totalWETH > 0) {
            IERC20(Currency.unwrap(key.currency1)).approve(address(poolManager), totalWETH);
        }
        
        // Calculate allocation per position (simplified equal distribution)
        //useEasyPosm
        uint256 numPositions = positions[poolId].length;
        uint256 pyusdPerPosition = totalPYUSD / numPositions;
        uint256 wethPerPosition = totalWETH / numPositions;
        
        // Deploy liquidity to each position
        for (uint256 i = 0; i < numPositions; i++) {
            Position storage pos = positions[poolId][i];
            
            // Only add liquidity to positions that are somewhat in range
            if (_isPositionViable(pos.tickLower, pos.tickUpper, currentTick)) {
                uint128 liquidityToAdd = _calculateLiquidityAmount(
                    key,
                    pos.tickLower,
                    pos.tickUpper,
                    pyusdPerPosition,
                    wethPerPosition,
                    sqrtPriceX96
                );
                
                if (liquidityToAdd > 0) {
                    // Prepare the modify liquidity params
                    ModifyLiquidityParams memory params = ModifyLiquidityParams({
                        tickLower: pos.tickLower,
                        tickUpper: pos.tickUpper,
                        liquidityDelta: int256(uint256(liquidityToAdd)),
                        salt: bytes32(uint256(i)) // Use index as salt for uniqueness
                    });
                    
                    // Call pool manager to add liquidity
                    BalanceDelta delta = poolManager.modifyLiquidity(
                        key,
                        params,
                        abi.encode(FAMILY_OP_TAG) // Pass our tag to identify family operations
                    );
                    
                    // Update position tracking
                    pos.liquidity += liquidityToAdd;
                    totalLiquidityDeployed += liquidityToAdd;
                    
                    // Handle the balance delta (tokens that need to be paid)
                    _settleDeltas(key, delta);
                }
            }
        }
        
        emit LiquidityDeployed(poolId, totalLiquidityDeployed, numPositions);
        return totalLiquidityDeployed;
    }
    
    /**
     * @dev Remove liquidity from all positions (for rebalancing or withdrawals)
     */
    function removeLiquidity(PoolKey calldata key, uint256 percentageToRemove) 
        external 
        returns (uint256 totalPYUSDRecovered, uint256 totalWETHRecovered) 
    {
        require(percentageToRemove <= 100, "Invalid percentage");
        PoolId poolId = key.toId();
        
        for (uint256 i = 0; i < positions[poolId].length; i++) {
            Position storage pos = positions[poolId][i];
            
            if (pos.liquidity > 0) {
                // Calculate how much liquidity to remove
                uint128 liquidityToRemove = uint128(
                    (uint256(pos.liquidity) * percentageToRemove) / 100
                );
                
                if (liquidityToRemove > 0) {
                    ModifyLiquidityParams memory params = ModifyLiquidityParams({
                        tickLower: pos.tickLower,
                        tickUpper: pos.tickUpper,
                        liquidityDelta: -int256(uint256(liquidityToRemove)),
                        salt: bytes32(uint256(i))
                    });
                    
                    // Remove liquidity from pool
                    BalanceDelta delta = poolManager.modifyLiquidity(
                        key,
                        params,
                        abi.encode(FAMILY_OP_TAG)
                    );
                    
                    // Update position
                    pos.liquidity -= liquidityToRemove;
                    
                    // Track recovered amounts
                    totalPYUSDRecovered += uint256(uint128(delta.amount0()));
                    totalWETHRecovered += uint256(uint128(delta.amount1()));
                    
                    // Settle the deltas (receive tokens back)
                    _settleDeltas(key, delta);
                }
            }
        }
        
        emit LiquidityRemoved(poolId, totalPYUSDRecovered, totalWETHRecovered);
        return (totalPYUSDRecovered, totalWETHRecovered);
    }
    
    /**
     * @dev Rebalance all positions based on new price
     */
    function rebalanceAllPositions(PoolKey calldata key) external {
        // First remove all liquidity
        (uint256 pyusdRecovered, uint256 wethRecovered) = this.removeLiquidity(key, 100);
        
        // Update position ranges based on new price
        _updatePositionRanges(key);
        
        // Redeploy liquidity with new ranges
        this.deployLiquidity(key);
        
        emit FullRebalance(key.toId(), pyusdRecovered, wethRecovered);
    }
    
    /**
     * @dev Collect fees from all positions
     */
    function collectAllFees(PoolKey calldata key) 
        external 
        returns (uint256 totalFees0, uint256 totalFees1) 
    {
        PoolId poolId = key.toId();
        
        for (uint256 i = 0; i < positions[poolId].length; i++) {
            Position storage pos = positions[poolId][i];
            
            if (pos.liquidity > 0) {
                // Collect fees by doing a 0 liquidity change
                ModifyLiquidityParams memory params = ModifyLiquidityParams({
                    tickLower: pos.tickLower,
                    tickUpper: pos.tickUpper,
                    liquidityDelta: 0, // 0 change triggers fee collection
                    salt: bytes32(uint256(i))
                });
                
                BalanceDelta delta = poolManager.modifyLiquidity(
                    key,
                    params,
                    abi.encode(FAMILY_OP_TAG)
                );
                
                // Fees are returned as positive deltas
                if (delta.amount0() > 0) totalFees0 += uint256(int256(delta.amount0()));
                if (delta.amount1() > 0) totalFees1 += uint256(int256(delta.amount1()));
                
                _settleDeltas(key, delta);
            }
        }
        
        // Distribute fees proportionally to family members
        _distributeFees(poolId, totalFees0, totalFees1);
        
        emit FeesCollected(poolId, totalFees0, totalFees1);
        return (totalFees0, totalFees1);
    }
    
    /**
     * @dev Withdraw a family member's proportional share
     */
    function withdrawFromFamily(PoolKey calldata key, uint256 shares) 
        external 
        returns (uint256 pyusdAmount, uint256 wethAmount) 
    {
        PoolId poolId = key.toId();
        uint256 userDeposit = familyDeposits[poolId][msg.sender];
        require(userDeposit >= shares, "Insufficient shares");
        
        // Calculate percentage of pool
        uint256 userPercentage = (shares * 100) / totalFamilyDeposits[poolId];
        
        // Remove proportional liquidity
        (uint256 totalPYUSD, uint256 totalWETH) = this.removeLiquidity(key, userPercentage);
        
        // Update deposits
        familyDeposits[poolId][msg.sender] -= shares;
        totalFamilyDeposits[poolId] -= shares;
        
        // Transfer tokens to user
        if (totalPYUSD > 0) {
            IERC20(Currency.unwrap(key.currency0)).transfer(msg.sender, totalPYUSD);
        }
        if (totalWETH > 0) {
            IERC20(Currency.unwrap(key.currency1)).transfer(msg.sender, totalWETH);
        }
        
        emit FamilyWithdrawal(msg.sender, poolId, totalPYUSD, totalWETH);
        return (totalPYUSD, totalWETH);
    }
    
    // ========== Helper Functions ==========
    
    function _calculateLiquidityAmount(
        PoolKey calldata key,
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0,
        uint256 amount1,
        uint160 sqrtPriceX96
    ) internal pure returns (uint128) {
        // Use Uniswap's LiquidityAmounts library
        // This calculates optimal liquidity given token amounts
        uint160 sqrtRatioAX96 = TickMath.getSqrtPriceAtTick(tickLower);
        uint160 sqrtRatioBX96 = TickMath.getSqrtPriceAtTick(tickUpper);
        
        return LiquidityAmounts.getLiquidityForAmounts(
            sqrtPriceX96,
            sqrtRatioAX96,
            sqrtRatioBX96,
            amount0,
            amount1
        );
    }
    
    function _isPositionViable(int24 tickLower, int24 tickUpper, int24 currentTick) 
        internal 
        pure 
        returns (bool) 
    {
        // Position is viable if current price is within 50% of the range
        int24 rangeSize = tickUpper - tickLower;
        int24 buffer = rangeSize / 2;
        
        return currentTick >= (tickLower - buffer) && currentTick <= (tickUpper + buffer);
    }
    
    function _settleDeltas(PoolKey calldata key, BalanceDelta delta) internal {
        // Settle any amounts owed to/from the pool
        if (delta.amount0() < 0) {
            // We owe token0 to the pool
            poolManager.take(key.currency0, address(this), uint256(uint128(-delta.amount0())));
        } else if (delta.amount0() > 0) {
            // Pool owes us token0
            poolManager.settle(key.currency0);
        }
        
        if (delta.amount1() < 0) {
            // We owe token1 to the pool
            poolManager.take(key.currency1, address(this), uint256(uint128(-delta.amount1())));
        } else if (delta.amount1() > 0) {
            // Pool owes us token1
            poolManager.settle(key.currency1);
        }
    }
    
    function _updatePositionRanges(PoolKey calldata key) internal {
        PoolId poolId = key.toId();
        (uint160 sqrtPriceX96, int24 currentTick,,) = poolManager.getSlot0(poolId);
        int24 spacing = key.tickSpacing;
        
        // Redistribute positions around new price
        for (uint256 i = 0; i < positions[poolId].length; i++) {
            int256 offset = (int256(i) - 10) * int256(spacing) * 10;
            int24 newTickLower = ((currentTick + int24(offset)) / spacing) * spacing;
            int24 newTickUpper = newTickLower + (spacing * 20);
            
            // Update position ranges
            positions[poolId][i].tickLower = newTickLower;
            positions[poolId][i].tickUpper = newTickUpper;
        }
    }
    
    function _distributeFees(PoolId poolId, uint256 fees0, uint256 fees1) internal {
        // Track fees for proportional distribution
        // In production, you'd maintain a fee accumulator per user
        emit FeesDistributed(poolId, fees0 + fees1);
    }
    
    // ========== New Events ==========
    event LiquidityDeployed(PoolId indexed poolId, uint256 totalLiquidity, uint256 numPositions);
    event LiquidityRemoved(PoolId indexed poolId, uint256 amount0, uint256 amount1);
    event FullRebalance(PoolId indexed poolId, uint256 pyusdRecovered, uint256 wethRecovered);
    event FeesCollected(PoolId indexed poolId, uint256 fees0, uint256 fees1);
    event FamilyWithdrawal(address indexed member, PoolId indexed poolId, uint256 amount0, uint256 amount1);
}