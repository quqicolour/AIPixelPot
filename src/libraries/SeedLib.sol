// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title SeedLib
/// @notice VRF 种子派生库 - 从原始随机数和上下文信息派生确定性的 canvas 种子
library SeedLib {
    uint256 constant RANDOM_MODULO = 100_000;
    uint256 constant MAX_CANVAS_PER_NFT = 500;

    /// @notice 从 VRF 随机数派生 canvas 分配的种子
    /// @param randomWord VRF 返回的原始随机数
    /// @param tokenId NFT tokenId
    /// @param chainId 链 ID
    /// @param contractAddress 合约地址
    /// @return seed 派生后的种子
    function deriveCanvasSeed(
        uint256 randomWord,
        uint256 tokenId,
        uint256 chainId,
        address contractAddress
    ) internal pure returns (uint256 seed) {
        return uint256(
            keccak256(
                abi.encode(randomWord, tokenId, chainId, contractAddress)
            )
        );
    }

    /// @notice 从原始随机数派生 King 抽奖种子
    /// @param randomWord VRF 返回的原始随机数
    /// @param requestId VRF 请求 ID
    /// @param contractAddress 合约地址
    /// @param chainId 链 ID
    /// @return seed 派生后的种子
    function deriveKingSeed(
        uint256 randomWord,
        uint256 requestId,
        address contractAddress,
        uint256 chainId
    ) internal pure returns (uint256 seed) {
        return uint256(
            keccak256(
                abi.encode(randomWord, requestId, contractAddress, chainId)
            )
        );
    }

    /// @notice 从种子中提取 canvas 数量
    /// @param seed 派生后的种子
    /// @param maxAvailable 当前最大可用 canvas 数量
    /// @return canvasCount 分配的 canvas 数量 (1~MAX_CANVAS_PER_NFT)
    function extractCanvasCount(
        uint256 seed,
        uint256 maxAvailable
    ) internal pure returns (uint256 canvasCount) {
        uint256 lastFive = seed % RANDOM_MODULO;
        canvasCount = lastFive == 0 ? 1 : lastFive;

        if (canvasCount > MAX_CANVAS_PER_NFT) {
            canvasCount = MAX_CANVAS_PER_NFT;
        }
        if (canvasCount > maxAvailable) {
            canvasCount = maxAvailable;
        }
        if (canvasCount == 0) {
            canvasCount = 1;
        }
    }

    /// @notice 从种子中提取 12 维特征
    /// @param seed 派生后的种子
    /// @return background 背景 (0~19)
    /// @return fur 毛色 (0~19)
    /// @return eyes 眼睛 (0~14)
    /// @return ears 耳朵 (0~7)
    /// @return pose 姿态 (0~9)
    /// @return expression 表情 (0~9)
    /// @return mouth 嘴巴 (0~7)
    /// @return nose 鼻子 (0~7)
    /// @return whiskers 胡须 (0~5)
    /// @return flower 花 (0~11)
    /// @return pattern 花纹 (0~11)
    /// @return aura 光环 (0~7)
    function extractTraits(uint256 seed)
        internal
        pure
        returns (
            uint8 background,
            uint8 fur,
            uint8 eyes,
            uint8 ears,
            uint8 pose,
            uint8 expression,
            uint8 mouth,
            uint8 nose,
            uint8 whiskers,
            uint8 flower,
            uint8 pattern,
            uint8 aura
        )
    {
        uint256 x = seed;
        background = uint8(x % 20);
        x /= 20;
        fur = uint8(x % 20);
        x /= 20;
        eyes = uint8(x % 15);
        x /= 15;
        ears = uint8(x % 8);
        x /= 8;
        pose = uint8(x % 10);
        x /= 10;
        expression = uint8(x % 10);
        x /= 10;
        mouth = uint8(x % 8);
        x /= 8;
        nose = uint8(x % 8);
        x /= 8;
        whiskers = uint8(x % 6);
        x /= 6;
        flower = uint8(x % 12);
        x /= 12;
        pattern = uint8(x % 12);
        x /= 12;
        aura = uint8(x % 8);
    }
}
