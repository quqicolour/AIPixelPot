// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId} from "v4-core/src/types/PoolId.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";

/// @title ICanvasPointsHook
/// @notice Canvas 积分 Hook 接口
interface ICanvasPointsHook {
    // ─── 错误 ────────────────────────────────────────────────────
    error NotOwner();
    error PoolNotAllowed();
    error HookZeroAddress();

    // ─── 权限 ────────────────────────────────────────────────────
    function getHookPermissions() external pure returns (Hooks.Permissions memory);
    function getPermissions() external pure returns (Hooks.Permissions memory);

    // ─── Admin ──────────────────────────────────────────────────
    function setOwner(address newOwner) external;
    function setFlowerCat(address thisFlowerCat) external;
    function setAllowedPool(PoolKey calldata key, bool allowed) external;

    // ─── 状态查询 ────────────────────────────────────────────────
    function owner() external view returns (address);
    function flowerCat() external view returns (address);
    function allowedPool(PoolId poolId) external view returns (bool);
    function userPoints(address user) external view returns (uint256);

    // ─── 事件 ────────────────────────────────────────────────────
    event OwnerSet(address indexed owner);
    event FlowerCatSet(address indexed flowerCat);
    event PoolAllowed(PoolId indexed poolId, bool allowed);
    event PointsAdded(address indexed user, PoolId indexed poolId, uint256 points, uint256 totalPoints);
}
