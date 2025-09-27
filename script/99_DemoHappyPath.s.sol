// script/99_DemoHappyPath.s.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {BaseScript} from "./base/BaseScript.sol";
import {WhalePoolWrapper} from "../src/WhalePoolWrapper.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import "forge-std/console.sol";
import {Test, console2} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";

contract DemoHappyPathScript is BaseScript, StdCheats {
    address constant PYUSD = 0x6c3ea9036406852006290770BEdFcAbA0e23A0e8;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    WhalePoolWrapper wrapper;
    // anvil default for --private-key 0xac0974...ff80
    address constant BROADCASTER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    function run() external {
        // Setup wrapper (use deployed address)
        wrapper = WhalePoolWrapper(0xa365f75b072CF8BA95e6A27A9E1f94038dCB9A00); // Replace with deployed address

        // Create pool key
        Currency currency0 = Currency.wrap(PYUSD < WETH ? PYUSD : WETH);
        Currency currency1 = Currency.wrap(PYUSD < WETH ? WETH : PYUSD);

        PoolKey memory poolKey = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(address(wrapper))
        });

        // Step 1: Show initial state
        console.log("=== FAMILY POOL DEMO ===");
        console.log("Initial family members: 0");

        // Step 2: First 3 family members deposit (pre-demo setup)
        // depositForMember(poolKey, address(0xa0Ee7A142d267C1f36714E4a8F75612F20a79720), 1000e6); // Mom: 1000 PYUSD
        // depositForMember(poolKey, address(0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f), 1500e6); // Dad: 1500 PYUSD
        // depositForMember(poolKey, address(0x14dC79964da2C08b23698B3D3cc7Ca32193d9955), 500e6); // Sister: 500 PYUSD

        IERC20 pyusd = IERC20(PYUSD);
        seedAndDepositSim(poolKey, pyusd, 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720, 1000e6);
        seedAndDepositSim(poolKey, pyusd, 0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f, 1500e6);
        seedAndDepositSim(poolKey, pyusd, 0x14dC79964da2C08b23698B3D3cc7Ca32193d9955, 500e6);

        console.log("Family members after setup: 3");
        console.log("Total pooled: 3000 PYUSD");

        // Step 3: Live deposit during demo
        console.log("\n=== LIVE DEMO - You deposit ===");
        // give PYUSD to the broadcaster, then broadcast, approve, deposit
        deal(PYUSD, BROADCASTER, 1000e6, true);
        vm.startBroadcast(); // uses the --private-key you pass
        //pyusd.approve(address(wrapper), 1000e6);
        wrapper.depositToFamily(poolKey, 0);
        // Step 4: Show IL comparison
        (uint256 individualIL, uint256 collectiveIL) = wrapper.calculateImpermanentLoss(poolKey);
        console.log("\n=== Impermanent Loss Comparison ===");
        console.log("\n=== If ETH price increases 50%: ===");
        console2.log("  Individual LP (centi-%):");
        console2.log(individualIL); // prints raw integer (e.g., 1234)
        console2.log("  Family Pool (centi-%):");
        console2.log(collectiveIL);
        console2.log("  Savings (centi-%):");
        console2.log(individualIL > collectiveIL ? individualIL - collectiveIL : 0);

        // Step 5: Trigger rebalance
        console.log("\n=== Rebalancing Positions ===");
        wrapper.rebalancePositions(poolKey);
        console.log("Positions rebalanced across 20 ranges");

        vm.stopBroadcast();
    }

    function depositForMember(PoolKey memory key, address member, uint256 amount) internal {
        vm.prank(member);
        wrapper.depositToFamily(key, amount);
    }

    function seedAndDepositSim(PoolKey memory key, IERC20 pyusd, address member, uint256 amount) internal {
        // mint PYUSD to member on the fork
        deal(address(pyusd), member, amount, true);
        vm.startPrank(member);
        pyusd.approve(address(wrapper), amount);
        wrapper.depositToFamily(key, amount);
        vm.stopPrank();
    }
}
