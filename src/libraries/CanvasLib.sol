// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {MillionFlowerCatStorage} from "../storage/MillionFlowerCatStorage.sol";
import {Errors} from "./Errors.sol";

/// @title CanvasLib
/// @notice Canvas 分配逻辑库
library CanvasLib {
    uint256 constant TOTAL_CANVAS = 1_000_000;

    /// @notice 创建 Canvas 分配结构
    /// @param startCanvasId 起始 Canvas ID
    /// @param canvasCount Canvas 数量
    /// @param seed 随机种子
    /// @return allocation 分配结构
    function createAllocation(
        uint256 startCanvasId,
        uint256 canvasCount,
        uint256 seed
    ) internal pure returns (MillionFlowerCatStorage.CanvasAllocation memory allocation) {
        allocation.startCanvasId = uint32(startCanvasId);
        allocation.canvasCount = uint16(canvasCount);
        allocation.seed = seed;
        allocation.finalized = true;
    }

    /// @notice 检查 Canvas 是否还有剩余
    /// @param allocated 已分配
    /// @param pending 待处理
    /// @return available 剩余可分配数量
    function remainingCanvas(uint256 allocated, uint256 pending)
        internal
        pure
        returns (uint256 available)
    {
        if (allocated + pending >= TOTAL_CANVAS) {
            return 0;
        }
        return TOTAL_CANVAS - allocated - pending;
    }

    /// @notice 验证分配是否有效
    /// @param allocation 分配结构
    /// @param tokenId Token ID
    function validateAllocation(
        MillionFlowerCatStorage.CanvasAllocation memory allocation,
        uint256 tokenId
    ) internal pure {
        if (!allocation.finalized) {
            revert Errors.CanvasAllocationFailed();
        }
        if (allocation.startCanvasId == 0) {
            revert Errors.CanvasAllocationFailed();
        }
        if (allocation.canvasCount == 0) {
            revert Errors.InvalidCanvasCount();
        }
        // 检查范围是否超出上限
        uint256 endCanvasId = allocation.startCanvasId + allocation.canvasCount - 1;
        if (endCanvasId > TOTAL_CANVAS) {
            revert Errors.CanvasAllocationFailed();
        }
        // 检查 tokenId 合理性 (tokenId 从 1 开始)
        if (tokenId == 0) {
            revert Errors.CanvasAllocationFailed();
        }
    }

    /// @notice 计算下一个可用的起始 Canvas ID
    /// @param allocated 当前已分配总量
    /// @return nextStartId 下一个起始 ID (1-indexed)
    function nextStartCanvasId(uint256 allocated) internal pure returns (uint256 nextStartId) {
        return allocated + 1;
    }
}
