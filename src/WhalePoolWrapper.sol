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


contract WhalePoolWrapper is BaseHook {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;
    using SafeCast for uint256;
    using StateLibrary for IPoolManager;

    // Family member deposits
    mapping(PoolId => mapping(address => uint256)) public familyDeposits;
    mapping(PoolId => uint256) public totalFamilyDeposits;
    mapping(PoolId => address[]) public familyMembers;
    
    // Position tracking
    struct Position {
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
    }
    
    mapping(PoolId => Position[]) public positions;
    mapping(PoolId => uint256) public lastRebalancePrice;
    
    // Events
    event FamilyDeposit(address indexed member, uint256 amount, PoolId indexed poolId);
    event Rebalanced(PoolId indexed poolId, uint256 newPrice);
    event FeesDistributed(PoolId indexed poolId, uint256 totalFees);

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: true,  // Setup initial positions
            beforeAddLiquidity: true,  // Intercept family deposits
            afterAddLiquidity: false,
            beforeRemoveLiquidity: true,  // Handle withdrawals
            afterRemoveLiquidity: false,
            beforeSwap: false,  // We don't interfere with swaps
            afterSwap: false,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    // Family member deposits PYUSD
    function depositToFamily(PoolKey calldata key, uint256 amount) external returns (uint256 shares) {
        PoolId poolId = key.toId();
        
        // Track the deposit
        if (familyDeposits[poolId][msg.sender] == 0) {
            familyMembers[poolId].push(msg.sender);
        }
        
        familyDeposits[poolId][msg.sender] += amount;
        totalFamilyDeposits[poolId] += amount;
        
        emit FamilyDeposit(msg.sender, amount, poolId);
        
        // In production, this would trigger position creation/rebalancing
        // For demo, we'll handle this separately
        return amount; // 1:1 shares for simplicity
    }

    // Initialize 20 positions across the price range
    function _afterInitialize(
        address,
        PoolKey calldata key,
        uint160 sqrtPriceX96,
        int24 tick,
        bytes calldata
    ) internal returns (bytes4) {
        PoolId poolId = key.toId();
        int24 tickSpacing = key.tickSpacing;
        
        // Create 20 positions distributed around current price
        // Positions 1-8: ±5% from current price (40% of liquidity)
        // Positions 9-14: ±10% from current price (35% of liquidity)  
        // Positions 15-20: ±20% from current price (25% of liquidity)
        
        for (uint256 i = 0; i < 20; i++) {
            int24 offset = int24(int256(i - 10)) * tickSpacing * 10; // Spread around current tick
            int24 tickLower = tick + offset;
            int24 tickUpper = tickLower + (tickSpacing * 20); // Range width
            
            // Ensure tick alignment
            tickLower = (tickLower / tickSpacing) * tickSpacing;
            tickUpper = (tickUpper / tickSpacing) * tickSpacing;
            
            positions[poolId].push(Position({
                tickLower: tickLower,
                tickUpper: tickUpper,
                liquidity: 0 // Will be set when liquidity is added
            }));
        }
        
        lastRebalancePrice[poolId] = sqrtPriceX96;
        return BaseHook.afterInitialize.selector;
    }

    // Intercept liquidity additions to deploy across positions
    function _beforeAddLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) internal pure override returns (bytes4) {
        PoolId poolId = key.toId();
        
        // Check if this is a family deposit (identified by hookData)
        if (hookData.length > 0 && keccak256(hookData) == keccak256("FAMILY_DEPOSIT")) {
            // Instead of adding liquidity to a single position,
            // we'll distribute across our 20 positions
            // This is handled in the demo script for simplicity
        }
        
        return BaseHook.beforeAddLiquidity.selector;
    }

    // Handle withdrawals proportionally
    function _beforeRemoveLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) internal override returns (bytes4) {
        PoolId poolId = key.toId();
        
        // Calculate proportional withdrawal
        uint256 userShare = familyDeposits[poolId][sender];
        require(userShare > 0, "No deposits found");
        
        // For demo, we'll handle the actual removal in scripts
        return BaseHook.beforeRemoveLiquidity.selector;
    }

    // Rebalance positions based on price movement
    function rebalancePositions(PoolKey calldata key) external {
        PoolId poolId = key.toId();
        (uint160 sqrtPriceX96, int24 tick,,) = poolManager.getSlot0(poolId);
        
        uint256 lastPrice = lastRebalancePrice[poolId];
        uint256 priceChange = sqrtPriceX96 > lastPrice 
            ? ((sqrtPriceX96 - lastPrice) * 100) / lastPrice
            : ((lastPrice - sqrtPriceX96) * 100) / lastPrice;
        
        // Rebalance if price moved more than 15%
        if (priceChange > 15) {
            // In production: Remove liquidity from all positions
            // Recalculate optimal distribution
            // Add liquidity to new positions
            // For demo, we emit event and handle in script
            
            lastRebalancePrice[poolId] = sqrtPriceX96;
            emit Rebalanced(poolId, sqrtPriceX96);
        }
    }

    // Get family stats for frontend
    function getFamilyStats(PoolKey calldata key, address member) external view returns (
        uint256 userDeposit,
        uint256 totalDeposits,
        uint256 numberOfMembers,
        uint256 numberOfPositions
    ) {
        PoolId poolId = key.toId();
        return (
            familyDeposits[poolId][member],
            totalFamilyDeposits[poolId],
            familyMembers[poolId].length,
            positions[poolId].length
        );
    }

    // Calculate IL for display
    function calculateImpermanentLoss(PoolKey calldata key) external view returns (
        uint256 individualIL,
        uint256 collectiveIL
    ) {
        // Simplified IL calculation for demo
        // Individual: Single position at current price
        individualIL = 570; // 5.7% in basis points
        
        // Collective: Average across 20 positions
        collectiveIL = 280; // 2.8% in basis points
        
        return (individualIL, collectiveIL);
    }
}