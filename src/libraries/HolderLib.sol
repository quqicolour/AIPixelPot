// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {MillionFlowerCatStorage} from "../storage/MillionFlowerCatStorage.sol";
import {Errors} from "./Errors.sol";

/// @title HolderLib
/// @notice Holder 注册表管理库
library HolderLib {
    /// @notice 添加 holder
    /// @param holders holders 数组引用
    /// @param holderIndexPlusOne holder => index+1 映射引用
    /// @param holder 要添加的地址
    function addHolder(
        address[] storage holders,
        mapping(address => uint256) storage holderIndexPlusOne,
        address holder
    ) internal {
        if (holderIndexPlusOne[holder] == 0) {
            holders.push(holder);
            holderIndexPlusOne[holder] = holders.length;
        }
    }

    /// @notice 移除 holder (当余额变为 0 时)
    /// @param holders holders 数组引用
    /// @param holderIndexPlusOne holder => index+1 映射引用
    /// @param holder 要移除的地址
    function removeHolder(
        address[] storage holders,
        mapping(address => uint256) storage holderIndexPlusOne,
        address holder
    ) internal {
        uint256 indexPlusOne = holderIndexPlusOne[holder];
        if (indexPlusOne == 0) return; // 本来就不在列表中

        uint256 index = indexPlusOne - 1;
        uint256 lastIndex = holders.length - 1;

        // 如果不是最后一个，将其与最后一个交换
        if (index != lastIndex) {
            address lastHolder = holders[lastIndex];
            holders[index] = lastHolder;
            holderIndexPlusOne[lastHolder] = index + 1;
        }

        holders.pop();
        delete holderIndexPlusOne[holder];
    }

    /// @notice 从 holders 数组中随机选择一个
    /// @param holders holders 数组
    /// @param seed 随机种子
    /// @return winner 选中的获胜者地址
    function selectRandomWinner(
        address[] storage holders,
        uint256 seed
    ) internal view returns (address winner) {
        if (holders.length == 0) {
            revert Errors.EmptyHolders();
        }
        return holders[seed % holders.length];
    }

    /// @notice 检查地址是否是 holder
    /// @param holderIndexPlusOne holder => index+1 映射
    /// @param account 要检查的地址
    /// @return isHolder_ 是否是 holder
    function isHolder(
        mapping(address => uint256) storage holderIndexPlusOne,
        address account
    ) internal view returns (bool isHolder_) {
        return holderIndexPlusOne[account] != 0;
    }

    /// @notice 获取 holder 总数
    /// @param holders holders 数组
    /// @return count holder 数量
    function holderCount(address[] storage holders) internal view returns (uint256 count) {
        return holders.length;
    }
}
