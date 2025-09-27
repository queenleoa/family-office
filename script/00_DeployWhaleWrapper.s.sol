// script/00_DeployWhaleWrapper.s.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {HookMiner} from "@uniswap/v4-periphery/src/utils/HookMiner.sol";
import {BaseScript} from "./base/BaseScript.sol";
import {WhalePoolWrapper} from "../src/WhalePoolWrapper.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import "forge-std/console.sol";

contract DeployWhaleWrapperScript is BaseScript {
    function run() public {
        // Hook needs these specific flags for our use case
        uint160 flags = uint160(
            Hooks.AFTER_INITIALIZE_FLAG | 
            Hooks.BEFORE_ADD_LIQUIDITY_FLAG | 
            Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG
        );

        // Mine a salt that will produce a hook address with correct flags
        bytes memory constructorArgs = abi.encode(poolManager);
        (address hookAddress, bytes32 salt) = HookMiner.find(
            CREATE2_FACTORY, 
            flags, 
            type(WhalePoolWrapper).creationCode, 
            constructorArgs
        );

        // Deploy the hook using CREATE2
        vm.startBroadcast();
        WhalePoolWrapper wrapper = new WhalePoolWrapper{salt: salt}(poolManager);
        vm.stopBroadcast();

        require(address(wrapper) == hookAddress, "Hook address mismatch");
        
        console.log("WhalePoolWrapper deployed at:", address(wrapper));
    }
}