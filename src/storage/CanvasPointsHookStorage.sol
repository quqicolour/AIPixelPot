// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {PoolId} from "v4-core/src/types/PoolId.sol";

/// @title CanvasPointsHookStorage
/// @notice EIP-7201 分离存储桶 - CanvasPointsHook 存储
library CanvasPointsHookStorage {
    bytes32 constant STORAGE_NAMESPACE =
        bytes32(uint256(keccak256("AIPixelPot.storage.CanvasPointsHook")) - 1);

    struct Layout {
        address owner;
        address flowerCat;
        mapping(PoolId poolId => bool allowed) allowedPool;
        mapping(address user => uint256 points) userPoints;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_NAMESPACE;
        assembly {
            l.slot := slot
        }
    }
}
