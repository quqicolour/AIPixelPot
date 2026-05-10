// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {CanvasPointsHook} from "../src/hooks/CanvasPointsHook.sol";

contract DeployCanvasPointsHook is Script {
    function run() external returns (CanvasPointsHook hook) {
        IPoolManager poolManager = IPoolManager(vm.envAddress("POOL_MANAGER"));
        address owner = vm.envAddress("OWNER");
        address flowerCat = vm.envAddress("FLOWER_CAT");

        vm.startBroadcast();
        hook = new CanvasPointsHook(poolManager, owner, flowerCat);
        vm.stopBroadcast();
    }
}
