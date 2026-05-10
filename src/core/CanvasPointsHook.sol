// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {BaseHook} from "v4-periphery/src/utils/BaseHook.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {SwapParams} from "v4-core/src/types/PoolOperation.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "v4-core/src/types/BeforeSwapDelta.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";

import {ICanvasPointsHook} from "../interfaces/ICanvasPointsHook.sol";
import {CanvasPointsHookStorage} from "../storage/CanvasPointsHookStorage.sol";
import {Errors} from "../libraries/Errors.sol";

interface ICanvasPointsConsumer {
    function isHolder(address account) external view returns (bool);
}

/// @title CanvasPointsHook
/// @notice Uniswap V4 Hook - 在 swap 时为用户累积积分
/// @dev NFT 持有者 swap 时得 3 分，普通用户得 1 分
contract CanvasPointsHook is BaseHook, ICanvasPointsHook {
    using PoolIdLibrary for PoolKey;

    // ══════════════════════════════════════════════════════════════
    // 存储访问
    // ══════════════════════════════════════════════════════════════

    function _storage() private pure returns (CanvasPointsHookStorage.Layout storage) {
        return CanvasPointsHookStorage.layout();
    }

    // ══════════════════════════════════════════════════════════════
    // 构造函数
    // ══════════════════════════════════════════════════════════════

    constructor(IPoolManager poolManager, address owner_, address flowerCat_) BaseHook(poolManager) {
        CanvasPointsHookStorage.Layout storage s = _storage();
        s.owner = owner_;
        s.flowerCat = flowerCat_;
    }

    // ══════════════════════════════════════════════════════════════
    // Hook 权限
    // ══════════════════════════════════════════════════════════════

    /// @inheritdoc ICanvasPointsHook
    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return _permissions();
    }

    /// @inheritdoc ICanvasPointsHook
    function getPermissions() public pure override returns (Hooks.Permissions memory) {
        return _permissions();
    }

    function _permissions() private pure returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: true,
            afterSwap: true,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    // ══════════════════════════════════════════════════════════════
    // Admin 函数
    // ══════════════════════════════════════════════════════════════

    /// @inheritdoc ICanvasPointsHook
    function setOwner(address newOwner) external override {
        _requireOwner();
        CanvasPointsHookStorage.Layout storage s = _storage();
        if (newOwner == address(0)) revert Errors.HookZeroAddress();
        s.owner = newOwner;
        emit OwnerSet(newOwner);
    }

    /// @inheritdoc ICanvasPointsHook
    function setFlowerCat(address thisFlowerCat) external override {
        _requireOwner();
        CanvasPointsHookStorage.Layout storage s = _storage();
        s.flowerCat = thisFlowerCat;
        emit FlowerCatSet(thisFlowerCat);
    }

    /// @inheritdoc ICanvasPointsHook
    function setAllowedPool(PoolKey calldata key, bool allowed) external override {
        _requireOwner();
        CanvasPointsHookStorage.Layout storage s = _storage();
        PoolId poolId = key.toId();
        s.allowedPool[poolId] = allowed;
        emit PoolAllowed(poolId, allowed);
    }

    // ══════════════════════════════════════════════════════════════
    // Hook 实现
    // ══════════════════════════════════════════════════════════════

    function _beforeSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata,
        bytes calldata
    ) internal override returns (bytes4, BeforeSwapDelta, uint24) {
        CanvasPointsHookStorage.Layout storage s = _storage();
        PoolId poolId = key.toId();
        if (!s.allowedPool[poolId]) revert Errors.HookPoolNotAllowed();

        uint256 points = _getPoints(s, sender);
        s.userPoints[sender] += points;
        emit PointsAdded(sender, poolId, points, s.userPoints[sender]);

        return (BaseHook.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }

    function _afterSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata,
        BalanceDelta,
        bytes calldata
    ) internal override returns (bytes4, int128) {
        CanvasPointsHookStorage.Layout storage s = _storage();
        PoolId poolId = key.toId();
        uint256 points = _getPoints(s, sender);
        s.userPoints[sender] += points;
        emit PointsAdded(sender, poolId, points, s.userPoints[sender]);
        return (BaseHook.afterSwap.selector, 0);
    }

    // ══════════════════════════════════════════════════════════════
    // 内部辅助
    // ══════════════════════════════════════════════════════════════

    function _requireOwner() internal view {
        CanvasPointsHookStorage.Layout storage s = _storage();
        if (msg.sender != s.owner) revert Errors.HookNotOwner();
    }

    function _getPoints(CanvasPointsHookStorage.Layout storage s, address sender) internal view returns (uint256) {
        if (address(s.flowerCat) != address(0) && ICanvasPointsConsumer(s.flowerCat).isHolder(sender)) {
            return 3;
        }
        return 1;
    }

    // ══════════════════════════════════════════════════════════════
    // 只读查询
    // ══════════════════════════════════════════════════════════════

    /// @inheritdoc ICanvasPointsHook
    function owner() public view override returns (address) { return _storage().owner; }
    /// @inheritdoc ICanvasPointsHook
    function flowerCat() public view override returns (address) { return _storage().flowerCat; }
    /// @inheritdoc ICanvasPointsHook
    function allowedPool(PoolId poolId) public view override returns (bool) { return _storage().allowedPool[poolId]; }
    /// @inheritdoc ICanvasPointsHook
    function userPoints(address user) public view override returns (uint256) { return _storage().userPoints[user]; }
}
