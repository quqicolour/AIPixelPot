// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {MillionFlowerCat} from "../src/MillionFlowerCat.sol";

contract DeployMillionFlowerCat is Script {
    function run() external returns (MillionFlowerCat cat) {
        address owner = vm.envAddress("OWNER");
        address vrfCoordinator = vm.envAddress("VRF_COORDINATOR");
        bytes32 keyHash = vm.envBytes32("VRF_KEY_HASH");
        uint256 subId = vm.envUint("VRF_SUBSCRIPTION_ID");
        uint256 mintPrice = vm.envUint("MINT_PRICE_WEI");

        vm.startBroadcast();
        cat = new MillionFlowerCat(owner, vrfCoordinator, keyHash, subId, mintPrice);
        vm.stopBroadcast();
    }
}
