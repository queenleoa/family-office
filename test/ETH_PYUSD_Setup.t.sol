// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";

import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolManager} from "@uniswap/v4-core/src/PoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";

import {MockPYUSD} from "../src/tokens/MockPYUSD.sol";

contract ETH_PYUSD_Setup is Test {
    using CurrencyLibrary for Currency;

    PoolManager public poolManager;
    MockPYUSD public pyusd;

    PoolKey public poolKey;

    function setUp() public {
        poolManager = new PoolManager();
        pyusd = new MockPYUSD(); // 6 decimals

        // For local ETH in v4, use CurrencyLibrary.NATIVE as token0.
        // We'll initialize at tick = 0 (price = 1:1) for simplicity.
        // That's enough to stand the pool up; later, our oracle-based rebalance logic
        // will compute bands around the live price.
        poolKey = PoolKey({
            currency0: CurrencyLibrary.NATIVE,          // ETH (native)
            currency1: Currency.wrap(address(pyusd)),   // PYUSD (6 decimals)
            fee: 3000,                                  // 0.3% (any fee tier is fine for POC)
            tickSpacing: 60,                            // common spacing
            hooks: IHooks(address(0))                   // no hooks yet in this setup test
        });

        uint160 sqrtPriceX96 = TickMath.getSqrtPriceAtTick(0);
        poolManager.initialize(poolKey, sqrtPriceX96);

        // seed some balances for later tests/demos
        pyusd.mint(address(this), 1_000_000e6); // 1,000,000 PYUSD (6dp)
        vm.deal(address(this), 1000 ether);      // give this test address ETH
    }

    function testPoolIsInitialized() public {
        // If we got here without revert, we have a live pool.
        assertTrue(true);
    }
}
