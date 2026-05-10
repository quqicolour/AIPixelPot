// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title MillionFlowerCatStorage
/// @notice EIP-7201 分离存储桶 - MillionFlowerCat 核心存储
/// @dev 使用这些 slot 前先: using MillionFlowerCatStorage for MillionFlowerCatStorage.Layout;
library MillionFlowerCatStorage {
    bytes32 constant STORAGE_NAMESPACE =
        bytes32(uint256(keccak256("AIPixelPot.storage.MillionFlowerCat")) - 1);

    struct Layout {
        // ─── 基础配置 ───
        uint256 mintPrice;
        bool saleActive;
        bool salePermanentlyClosed;

        // ─── Canvas 追踪 ───
        uint256 allocatedCanvas;
        uint256 pendingCanvasTokens;
        uint256 regularMinted;

        // ─── Chainlink VRF 配置 ───
        bytes32 keyHash;
        uint256 subscriptionId;
        uint32 callbackGasLimit;
        uint16 requestConfirmations;
        bool nativePayment;

        // ─── VRF 请求追踪 ───
        mapping(uint256 requestId => Request) vrfRequests;

        // ─── NFT Canvas 分配 ───
        mapping(uint256 tokenId => CanvasAllocation) canvasOf;

        // ─── Holder 注册表 ───
        address[] holders;
        mapping(address holder => uint256 indexPlusOne) holderIndexPlusOne;

        // ─── King 抽奖 ───
        bool kingRequested;
        bool kingMinted;
        uint256 kingRequestId;
        uint256 kingTokenId;
        address kingWinner;
        uint256 kingSeed;
        uint256 kingPrize;
        mapping(address winner => uint256 amount) claimablePrize;
    }

    enum RequestKind {
        None,
        CanvasBatch,
        King
    }

    struct Request {
        RequestKind kind;
        uint256 startTokenId;
        uint32 quantity;
        bool fulfilled;
    }

    struct CanvasAllocation {
        uint32 startCanvasId;
        uint16 canvasCount;
        uint256 seed;
        bool finalized;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_NAMESPACE;
        assembly {
            l.slot := slot
        }
    }
}
