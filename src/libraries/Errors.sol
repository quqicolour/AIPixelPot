// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title Errors
/// @notice 统一错误定义
library Errors {
    // ─── MillionFlowerCat ────────────────────────────────────────────
    error SaleClosed();                          // 销售已关闭
    error CanvasSoldOut();                       // 像素方块售罄
    error InvalidQuantity();                     // 无效数量 (0 或超过上限)
    error WrongValue();                          // 支付的 ETH 金额错误
    error TokenNotFinalized();                   // Token 尚未完成 VRF 分配
    error NotKingWinner();                       // 不是 King 获胜者
    error NoPrize();                             // 没有可领取的奖金
    error PrizeTransferFailed();                 // 奖金转账失败
    error InvalidWithdrawAddress();              // 提款地址无效
    error WithdrawLockedUntilKingSettled();      // King 未结算前禁止提款
    error RandomRequestUnknown();                // 未知的 VRF 请求
    error KingAlreadyRequested();                // King 抽奖已请求
    error NoHolders();                           // 没有持有者
    error SalePermanentlyClosed();               // 销售永久关闭
    error MintPriceZero();                       // Mint 价格不能为 0
    error CallbackGasTooHigh();                  // 回调 gas 限制过高
    error TransferFailed();                      // 普通转账失败
    error CanvasAllocationFailed();              // Canvas 分配失败

    // ─── CanvasPointsHook ───────────────────────────────────────────
    error HookNotOwner();                        // 非 Owner 无权操作
    error HookPoolNotAllowed();                  // Pool 未被允许
    error HookZeroAddress();                     // 地址不能为 0

    // ─── Library ────────────────────────────────────────────────────
    error EmptyHolders();                        // Holder 列表为空
    error HolderNotFound();                      // 未找到 Holder
    error InvalidCanvasCount();                  // 无效的 canvas 数量
    error SeedGenerationFailed();                // 种子生成失败
}
