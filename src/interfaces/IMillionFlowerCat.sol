// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title IMillionFlowerCat
/// @notice 花猫 NFT 核心接口
interface IMillionFlowerCat {
    // ══════════════════════════════════════════════════════════════
    // 枚举 & 结构体
    // ══════════════════════════════════════════════════════════════

    enum RequestKind {
        None,
        CanvasBatch,
        King
    }

    struct CanvasAllocation {
        uint32 startCanvasId;
        uint16 canvasCount;
        uint256 seed;
        bool finalized;
    }

    struct VRFRequest {
        RequestKind kind;
        uint256 startTokenId;
        uint32 quantity;
        bool fulfilled;
    }

    // ══════════════════════════════════════════════════════════════
    // 常量
    // ══════════════════════════════════════════════════════════════

    function TOTAL_CANVAS() external view returns (uint256);
    function MAX_CANVAS_PER_NFT() external view returns (uint256);
    function RANDOM_MODULO() external view returns (uint256);
    function MAX_MINT_PER_TX() external view returns (uint256);

    // ══════════════════════════════════════════════════════════════
    // 状态变量 (只读)
    // ══════════════════════════════════════════════════════════════

    function mintPrice() external view returns (uint256);
    function saleActive() external view returns (bool);
    function salePermanentlyClosed() external view returns (bool);
    function allocatedCanvas() external view returns (uint256);
    function pendingCanvasTokens() external view returns (uint256);
    function regularMinted() external view returns (uint256);
    function kingRequested() external view returns (bool);
    function kingMinted() external view returns (bool);
    function kingRequestId() external view returns (uint256);
    function kingTokenId() external view returns (uint256);
    function kingWinner() external view returns (address);
    function kingSeed() external view returns (uint256);
    function kingPrize() external view returns (uint256);
    function keyHash() external view returns (bytes32);
    function subscriptionId() external view returns (uint256);
    function callbackGasLimit() external view returns (uint32);
    function requestConfirmations() external view returns (uint16);
    function nativePayment() external view returns (bool);

    // ══════════════════════════════════════════════════════════════
    // 映射查询
    // ══════════════════════════════════════════════════════════════

    function vrfRequests(uint256 requestId) external view returns (
        RequestKind kind,
        uint256 startTokenId,
        uint32 quantity,
        bool fulfilled
    );
    function canvasOf(uint256 tokenId) external view returns (
        uint32 startCanvasId,
        uint16 canvasCount,
        uint256 seed,
        bool finalized
    );
    function claimablePrize(address winner) external view returns (uint256);

    // ══════════════════════════════════════════════════════════════
    // 用户交互函数
    // ══════════════════════════════════════════════════════════════

    /// @notice 铸造 NFT
    /// @param quantity 数量 (1~10)
    /// @return requestId VRF 请求ID
    function mint(uint256 quantity) external payable returns (uint256 requestId);

    /// @notice 领取 King 奖金
    function claimPrize() external;

    /// @notice 查询剩余可铸造数量
    function remainingCanvasForNewMints() external view returns (uint256);

    // ══════════════════════════════════════════════════════════════
    // Holder 查询
    // ══════════════════════════════════════════════════════════════

    function holderCount() external view returns (uint256);
    function holderAt(uint256 index) external view returns (address);
    function isHolder(address account) external view returns (bool);

    // ══════════════════════════════════════════════════════════════
    // Owner 函数
    // ══════════════════════════════════════════════════════════════

    function setSaleActive(bool active) external;
    function setMintPrice(uint256 price) external;
    function setVRFConfig(
        bytes32 keyHash_,
        uint256 subscriptionId_,
        uint32 callbackGasLimit_,
        uint16 requestConfirmations_,
        bool nativePayment_
    ) external;
    function requestKingRandomnessManually() external returns (uint256 requestId);
    function withdrawRemainder(address payable to) external;

    // ══════════════════════════════════════════════════════════════
    // 元数据
    // ══════════════════════════════════════════════════════════════

    function tokenURI(uint256 tokenId) external view returns (string memory);
    function traitSpace() external pure returns (uint256);

    // ══════════════════════════════════════════════════════════════
    // 事件
    // ══════════════════════════════════════════════════════════════

    event SaleActiveSet(bool active);
    event MintPriceSet(uint256 price);
    event FlowerCatsMinted(
        address indexed buyer,
        uint256 indexed startTokenId,
        uint256 quantity,
        uint256 requestId
    );
    event CanvasBatchFulfilled(
        uint256 indexed requestId,
        uint256 indexed startTokenId,
        uint256 quantity
    );
    event CanvasAllocated(
        uint256 indexed tokenId,
        address indexed owner,
        uint256 seed,
        uint256 startCanvasId,
        uint256 canvasCount,
        uint256 allocatedCanvasTotal
    );
    event SaleClosedByCanvasReserve(uint256 allocatedCanvas, uint256 pendingCanvasTokens);
    event KingRandomnessRequested(uint256 indexed requestId, uint256 holderCount);
    event KingCatMinted(
        uint256 indexed tokenId,
        address indexed winner,
        uint256 seed,
        uint256 prizeWei
    );
    event PrizeClaimed(address indexed winner, uint256 amount);
}
