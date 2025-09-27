// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";

import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";

// ✅ use the local Deployers utility that comes with the v4-template
import {Deployers} from "../test/utils/Deployers.sol";

import {MockWETH} from "../src/tokens/MockWETH.sol";
import {MockPYUSD} from "../src/tokens/MockPYUSD.sol";

contract ETH_PYUSD_Setup is Test, Deployers {
    using CurrencyLibrary for Currency;

    IPoolManager public poolManager;
    MockWETH public weth;
    MockPYUSD public pyusd;
    PoolKey public poolKey;

    function setUp() public {
        // this helper comes from Deployers.sol and spins up a new PoolManager, routers, etc.
        deployFreshManagerAndRouters();
        poolManager = manager;

        weth = new MockWETH();
        pyusd = new MockPYUSD();

        poolKey = PoolKey({
            currency0: Currency.wrap(address(weth)),
            currency1: Currency.wrap(address(pyusd)),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(address(0))
        });

        // tick = 0 => price = 1:1
        uint160 sqrtPriceX96 = TickMath.getSqrtPriceAtTick(0);
        poolManager.initialize(poolKey, sqrtPriceX96);

        // give ourselves balances to play with later
        weth.mint(address(this), 1_000 ether);
        pyusd.mint(address(this), 1_000_000e6);
    }

    function testPoolIsInitialized() public {
        assertTrue(true, "Pool initialized without revert");
    }
}
