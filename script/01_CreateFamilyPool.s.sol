// script/01_CreateFamilyPool.s.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {BaseScript} from "./base/BaseScript.sol";
import {LiquidityHelpers} from "./base/LiquidityHelpers.sol";
import {WhalePoolWrapper} from "../src/WhalePoolWrapper.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import "forge-std/console.sol";


contract CreateFamilyPoolScript is BaseScript, LiquidityHelpers {
    using CurrencyLibrary for Currency;
    
    // PYUSD on mainnet
    address constant PYUSD = 0x6c3ea9036406852006290770BEdFcAbA0e23A0e8;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    
    // Replace with your deployed hook address
    address constant WHALE_WRAPPER = address(0); // Will be filled after deployment
    
    function run() external {
        // Create PYUSD-ETH pool with our wrapper hook
        Currency currency0 = Currency.wrap(PYUSD < WETH ? PYUSD : WETH);
        Currency currency1 = Currency.wrap(PYUSD < WETH ? WETH : PYUSD);
        
        PoolKey memory poolKey = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 3000, // 0.3% fee tier
            tickSpacing: 60,
            hooks: IHooks(WHALE_WRAPPER)
        });
        
        // Initialize pool at current market price
        uint160 startingPrice = TickMath.getSqrtPriceAtTick(0); // 1:1 for demo
        
        vm.startBroadcast();
        
        // Initialize the pool
        poolManager.initialize(poolKey, startingPrice);
        
        console.log("Family pool created with wrapper hook");
        
        vm.stopBroadcast();
    }
}