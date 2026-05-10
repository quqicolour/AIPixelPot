// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

import {IMillionFlowerCat} from "../interfaces/IMillionFlowerCat.sol";
import {MillionFlowerCatStorage} from "../storage/MillionFlowerCatStorage.sol";
import {CanvasLib} from "../libraries/CanvasLib.sol";
import {HolderLib} from "../libraries/HolderLib.sol";
import {SeedLib} from "../libraries/SeedLib.sol";
import {FlowerCatRenderer} from "../libraries/FlowerCatRenderer.sol";
import {Errors} from "../libraries/Errors.sol";

/// @title MillionFlowerCat
/// @notice 花猫 NFT 核心合约 - 结合 Chainlink VRF 的生成艺术 NFT
/// @dev 100万 Canvas 分块 + King 奖金机制
contract MillionFlowerCat is ERC721A, Ownable, ReentrancyGuard, VRFConsumerBaseV2Plus, IMillionFlowerCat {
    using Strings for uint256;

    // ══════════════════════════════════════════════════════════════
    // 常量
    // ══════════════════════════════════════════════════════════════

    uint256 public constant override TOTAL_CANVAS = 1_000_000;
    uint256 public constant override MAX_CANVAS_PER_NFT = 500;
    uint256 public constant override RANDOM_MODULO = 100_000;
    uint256 public constant override MAX_MINT_PER_TX = 10;

    // ══════════════════════════════════════════════════════════════
    // 存储访问
    // ══════════════════════════════════════════════════════════════

    function _storage() private pure returns (MillionFlowerCatStorage.Layout storage) {
        return MillionFlowerCatStorage.layout();
    }

    // ══════════════════════════════════════════════════════════════
    // 构造函数
    // ══════════════════════════════════════════════════════════════

    constructor(
        address initialOwner,
        address vrfCoordinator,
        bytes32 keyHash_,
        uint256 subscriptionId_,
        uint256 mintPrice_
    )
        ERC721A("Million Flower Cat", "MFLOWERCAT")
        Ownable(initialOwner)
        VRFConsumerBaseV2Plus(vrfCoordinator)
    {
        MillionFlowerCatStorage.Layout storage s = _storage();
        s.keyHash = keyHash_;
        s.subscriptionId = subscriptionId_;
        s.mintPrice = mintPrice_;
    }

    receive() external payable {}

    // ══════════════════════════════════════════════════════════════
    // 公共写入函数
    // ══════════════════════════════════════════════════════════════

    /// @inheritdoc IMillionFlowerCat
    function mint(uint256 quantity)
        external
        payable
        nonReentrant
        returns (uint256 requestId)
    {
        MillionFlowerCatStorage.Layout storage s = _storage();

        if (!s.saleActive || s.salePermanentlyClosed) revert Errors.SaleClosed();
        if (quantity == 0 || quantity > MAX_MINT_PER_TX) revert Errors.InvalidQuantity();
        if (msg.value != s.mintPrice * quantity) revert Errors.WrongValue();
        if (s.allocatedCanvas + s.pendingCanvasTokens + quantity > TOTAL_CANVAS) revert Errors.CanvasSoldOut();

        uint256 startTokenId = _nextTokenId();
        s.regularMinted += quantity;
        s.pendingCanvasTokens += quantity;

        _safeMint(msg.sender, quantity);

        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: s.keyHash,
                subId: s.subscriptionId,
                requestConfirmations: s.requestConfirmations,
                callbackGasLimit: s.callbackGasLimit,
                numWords: uint32(quantity),
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: s.nativePayment})
                )
            })
        );

        s.vrfRequests[requestId] = MillionFlowerCatStorage.Request({
            kind: MillionFlowerCatStorage.RequestKind.CanvasBatch,
            startTokenId: startTokenId,
            quantity: uint32(quantity),
            fulfilled: false
        });

        emit FlowerCatsMinted(msg.sender, startTokenId, quantity, requestId);

        if (s.allocatedCanvas + s.pendingCanvasTokens >= TOTAL_CANVAS) {
            _closeSaleByReserve();
        }
    }

    /// @inheritdoc IMillionFlowerCat
    function claimPrize() external nonReentrant {
        MillionFlowerCatStorage.Layout storage s = _storage();
        uint256 amount = s.claimablePrize[msg.sender];
        if (amount == 0) revert Errors.NoPrize();
        s.claimablePrize[msg.sender] = 0;

        (bool ok,) = payable(msg.sender).call{value: amount}("");
        if (!ok) revert Errors.PrizeTransferFailed();

        emit PrizeClaimed(msg.sender, amount);
    }

    // ══════════════════════════════════════════════════════════════
    // VRF 回调
    // ══════════════════════════════════════════════════════════════

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {
        MillionFlowerCatStorage.Layout storage s = _storage();
        MillionFlowerCatStorage.Request storage req = s.vrfRequests[requestId];
        if (req.kind == MillionFlowerCatStorage.RequestKind.None) revert Errors.RandomRequestUnknown();
        if (req.fulfilled) return;
        req.fulfilled = true;

        if (req.kind == MillionFlowerCatStorage.RequestKind.CanvasBatch) {
            _fulfillCanvasBatch(requestId, req, randomWords);
        } else if (req.kind == MillionFlowerCatStorage.RequestKind.King) {
            _fulfillKing(requestId, randomWords[0]);
        }
    }

    function _fulfillCanvasBatch(
        uint256 requestId,
        MillionFlowerCatStorage.Request memory req,
        uint256[] calldata randomWords
    ) internal {
        MillionFlowerCatStorage.Layout storage s = _storage();
        uint256 quantity = req.quantity;
        uint256 startTokenId = req.startTokenId;

        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = startTokenId + i;
            if (s.canvasOf[tokenId].finalized) continue;

            uint256 seed = SeedLib.deriveCanvasSeed(
                randomWords[i],
                tokenId,
                block.chainid,
                address(this)
            );

            s.pendingCanvasTokens -= 1;
            uint256 pendingAfterThis = s.pendingCanvasTokens;
            uint256 maxAvailableForThis = TOTAL_CANVAS - s.allocatedCanvas - pendingAfterThis;

            uint256 canvasCount = SeedLib.extractCanvasCount(seed, maxAvailableForThis);
            uint256 startCanvasId = CanvasLib.nextStartCanvasId(s.allocatedCanvas);
            s.allocatedCanvas += canvasCount;

            s.canvasOf[tokenId] = CanvasLib.createAllocation(startCanvasId, canvasCount, seed);

            emit CanvasAllocated(
                tokenId,
                ownerOf(tokenId),
                seed,
                startCanvasId,
                canvasCount,
                s.allocatedCanvas
            );
        }

        emit CanvasBatchFulfilled(requestId, startTokenId, quantity);

        if (s.allocatedCanvas + s.pendingCanvasTokens >= TOTAL_CANVAS) {
            _closeSaleByReserve();
        }
        if (s.allocatedCanvas == TOTAL_CANVAS && s.pendingCanvasTokens == 0 && !s.kingRequested) {
            _requestKingRandomness();
        }
    }

    function _requestKingRandomness() internal returns (uint256 requestId) {
        MillionFlowerCatStorage.Layout storage s = _storage();
        if (s.holders.length == 0) revert Errors.NoHolders();

        s.kingRequested = true;
        s.saleActive = false;
        s.salePermanentlyClosed = true;

        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: s.keyHash,
                subId: s.subscriptionId,
                requestConfirmations: s.requestConfirmations,
                callbackGasLimit: 500_000,
                numWords: 1,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: s.nativePayment})
                )
            })
        );

        s.kingRequestId = requestId;
        s.vrfRequests[requestId] = MillionFlowerCatStorage.Request({
            kind: MillionFlowerCatStorage.RequestKind.King,
            startTokenId: 0,
            quantity: 1,
            fulfilled: false
        });

        emit KingRandomnessRequested(requestId, s.holders.length);
    }

    function _fulfillKing(uint256 requestId, uint256 randomWord) internal {
        MillionFlowerCatStorage.Layout storage s = _storage();
        if (s.kingMinted) return;
        if (s.holders.length == 0) revert Errors.NoHolders();

        uint256 seed = SeedLib.deriveKingSeed(randomWord, requestId, address(this), block.chainid);
        address winner = HolderLib.selectRandomWinner(s.holders, seed);
        uint256 prize = address(this).balance / 2;
        uint256 tokenId = _nextTokenId();

        s.kingSeed = seed;
        s.kingWinner = winner;
        s.kingPrize = prize;
        s.kingTokenId = tokenId;
        s.kingMinted = true;
        s.claimablePrize[winner] += prize;

        _safeMint(winner, 1);

        emit KingCatMinted(tokenId, winner, seed, prize);
    }

    // ══════════════════════════════════════════════════════════════
    // tokenURI
    // ══════════════════════════════════════════════════════════════

    /// @inheritdoc IMillionFlowerCat
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert Errors.TokenNotFinalized();

        MillionFlowerCatStorage.Layout storage s = _storage();
        bool isKing = s.kingMinted && tokenId == s.kingTokenId;
        string memory name;
        string memory description;
        string memory svg;
        string memory attributes;

        if (isKing) {
            name = string.concat("King Flower Cat #", tokenId.toString());
            description = "The unique fully on-chain King Flower Cat, awarded by Chainlink VRF after all one million canvas units are allocated.";
            svg = FlowerCatRenderer.renderKing(
                tokenId,
                s.kingWinner,
                s.kingSeed,
                s.kingPrize
            );
            attributes = FlowerCatRenderer.kingAttributesJSON(
                s.kingWinner,
                s.kingPrize
            );
        } else {
            MillionFlowerCatStorage.CanvasAllocation memory c = s.canvasOf[tokenId];
            name = string.concat("Flower Cat #", tokenId.toString());
            description = "A fully on-chain generative flower cat NFT with canvas allocation determined by Chainlink VRF.";
            svg = c.finalized
                ? FlowerCatRenderer.renderCat(tokenId, c.seed, c.startCanvasId, c.canvasCount)
                : FlowerCatRenderer.renderPending(tokenId);
            attributes = FlowerCatRenderer.attributesJSON(
                c.seed,
                c.startCanvasId,
                c.canvasCount,
                c.finalized
            );
        }

        string memory image = Base64.encode(bytes(svg));
        string memory json = Base64.encode(
            bytes(
                string.concat(
                    "{",
                    '"name":"', name, '",',
                    '"description":"', description, '",',
                    '"image":"data:image/svg+xml;base64,', image, '",',
                    '"attributes":', attributes,
                    "}"
                )
            )
        );

        return string.concat("data:application/json;base64,", json);
    }

    // ══════════════════════════════════════════════════════════════
    // Hooks
    // ══════════════════════════════════════════════════════════════

    function _afterTokenTransfers(
        address from,
        address to,
        uint256,
        uint256
    ) internal override {
        MillionFlowerCatStorage.Layout storage s = _storage();
        if (from != address(0) && balanceOf(from) == 0) {
            HolderLib.removeHolder(s.holders, s.holderIndexPlusOne, from);
        }
        if (to != address(0) && s.holderIndexPlusOne[to] == 0) {
            HolderLib.addHolder(s.holders, s.holderIndexPlusOne, to);
        }
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    // ══════════════════════════════════════════════════════════════
    // Owner 函数
    // ══════════════════════════════════════════════════════════════

    /// @inheritdoc IMillionFlowerCat
    function setSaleActive(bool active) external onlyOwner {
        MillionFlowerCatStorage.Layout storage s = _storage();
        if (s.salePermanentlyClosed && active) revert Errors.SaleClosed();
        s.saleActive = active;
        emit SaleActiveSet(active);
    }

    /// @inheritdoc IMillionFlowerCat
    function setMintPrice(uint256 price) external onlyOwner {
        if (price == 0) revert Errors.MintPriceZero();
        MillionFlowerCatStorage.Layout storage s = _storage();
        s.mintPrice = price;
        emit MintPriceSet(price);
    }

    /// @inheritdoc IMillionFlowerCat
    function setVRFConfig(
        bytes32 keyHash_,
        uint256 subscriptionId_,
        uint32 callbackGasLimit_,
        uint16 requestConfirmations_,
        bool nativePayment_
    ) external onlyOwner {
        MillionFlowerCatStorage.Layout storage s = _storage();
        s.keyHash = keyHash_;
        s.subscriptionId = subscriptionId_;
        s.callbackGasLimit = callbackGasLimit_;
        s.requestConfirmations = requestConfirmations_;
        s.nativePayment = nativePayment_;
    }

    /// @inheritdoc IMillionFlowerCat
    function requestKingRandomnessManually()
        external
        onlyOwner
        returns (uint256 requestId)
    {
        MillionFlowerCatStorage.Layout storage s = _storage();
        if (s.kingRequested) revert Errors.KingAlreadyRequested();
        if (s.allocatedCanvas != TOTAL_CANVAS || s.pendingCanvasTokens != 0) revert Errors.CanvasSoldOut();
        requestId = _requestKingRandomness();
    }

    /// @inheritdoc IMillionFlowerCat
    function withdrawRemainder(address payable to) external onlyOwner nonReentrant {
        MillionFlowerCatStorage.Layout storage s = _storage();
        if (!s.kingMinted) revert Errors.WithdrawLockedUntilKingSettled();
        if (to == address(0)) revert Errors.InvalidWithdrawAddress();
        uint256 locked;
        if (s.kingWinner != address(0)) locked = s.claimablePrize[s.kingWinner];
        uint256 amount = address(this).balance - locked;
        (bool ok,) = to.call{value: amount}("");
        if (!ok) revert Errors.PrizeTransferFailed();
    }

    // ══════════════════════════════════════════════════════════════
    // 只读查询函数
    // ══════════════════════════════════════════════════════════════

    /// @inheritdoc IMillionFlowerCat
    function mintPrice() public view override returns (uint256) { return _storage().mintPrice; }
    /// @inheritdoc IMillionFlowerCat
    function saleActive() public view override returns (bool) { return _storage().saleActive; }
    /// @inheritdoc IMillionFlowerCat
    function salePermanentlyClosed() public view override returns (bool) { return _storage().salePermanentlyClosed; }
    /// @inheritdoc IMillionFlowerCat
    function allocatedCanvas() public view override returns (uint256) { return _storage().allocatedCanvas; }
    /// @inheritdoc IMillionFlowerCat
    function pendingCanvasTokens() public view override returns (uint256) { return _storage().pendingCanvasTokens; }
    /// @inheritdoc IMillionFlowerCat
    function regularMinted() public view override returns (uint256) { return _storage().regularMinted; }
    /// @inheritdoc IMillionFlowerCat
    function kingRequested() public view override returns (bool) { return _storage().kingRequested; }
    /// @inheritdoc IMillionFlowerCat
    function kingMinted() public view override returns (bool) { return _storage().kingMinted; }
    /// @inheritdoc IMillionFlowerCat
    function kingRequestId() public view override returns (uint256) { return _storage().kingRequestId; }
    /// @inheritdoc IMillionFlowerCat
    function kingTokenId() public view override returns (uint256) { return _storage().kingTokenId; }
    /// @inheritdoc IMillionFlowerCat
    function kingWinner() public view override returns (address) { return _storage().kingWinner; }
    /// @inheritdoc IMillionFlowerCat
    function kingSeed() public view override returns (uint256) { return _storage().kingSeed; }
    /// @inheritdoc IMillionFlowerCat
    function kingPrize() public view override returns (uint256) { return _storage().kingPrize; }
    /// @inheritdoc IMillionFlowerCat
    function keyHash() public view override returns (bytes32) { return _storage().keyHash; }
    /// @inheritdoc IMillionFlowerCat
    function subscriptionId() public view override returns (uint256) { return _storage().subscriptionId; }
    /// @inheritdoc IMillionFlowerCat
    function callbackGasLimit() public view override returns (uint32) { return _storage().callbackGasLimit; }
    /// @inheritdoc IMillionFlowerCat
    function requestConfirmations() public view override returns (uint16) { return _storage().requestConfirmations; }
    /// @inheritdoc IMillionFlowerCat
    function nativePayment() public view override returns (bool) { return _storage().nativePayment; }

    /// @inheritdoc IMillionFlowerCat
    function vrfRequests(uint256 requestId)
        public
        view
        override
        returns (MillionFlowerCatStorage.RequestKind kind, uint256 startTokenId, uint32 quantity, bool fulfilled)
    {
        MillionFlowerCatStorage.Request storage r = _storage().vrfRequests[requestId];
        kind = r.kind;
        startTokenId = r.startTokenId;
        quantity = r.quantity;
        fulfilled = r.fulfilled;
    }

    /// @inheritdoc IMillionFlowerCat
    function canvasOf(uint256 tokenId)
        public
        view
        override
        returns (uint32 startCanvasId, uint16 canvasCount, uint256 seed, bool finalized)
    {
        MillionFlowerCatStorage.CanvasAllocation storage c = _storage().canvasOf[tokenId];
        startCanvasId = c.startCanvasId;
        canvasCount = c.canvasCount;
        seed = c.seed;
        finalized = c.finalized;
    }

    /// @inheritdoc IMillionFlowerCat
    function claimablePrize(address winner) public view override returns (uint256) {
        return _storage().claimablePrize[winner];
    }

    /// @inheritdoc IMillionFlowerCat
    function remainingCanvasForNewMints() external view override returns (uint256) {
        MillionFlowerCatStorage.Layout storage s = _storage();
        return TOTAL_CANVAS - s.allocatedCanvas - s.pendingCanvasTokens;
    }

    /// @inheritdoc IMillionFlowerCat
    function holderCount() external view override returns (uint256) {
        return _storage().holders.length;
    }

    /// @inheritdoc IMillionFlowerCat
    function holderAt(uint256 index) external view override returns (address) {
        return _storage().holders[index];
    }

    /// @inheritdoc IMillionFlowerCat
    function isHolder(address account) external view override returns (bool) {
        return _storage().holderIndexPlusOne[account] != 0;
    }

    /// @inheritdoc IMillionFlowerCat
    function traitSpace() external pure override returns (uint256) {
        return FlowerCatRenderer.traitSpace();
    }

    // ══════════════════════════════════════════════════════════════
    // 内部辅助
    // ══════════════════════════════════════════════════════════════

    function _closeSaleByReserve() internal {
        MillionFlowerCatStorage.Layout storage s = _storage();
        if (!s.salePermanentlyClosed) {
            s.saleActive = false;
            s.salePermanentlyClosed = true;
            emit SaleClosedByCanvasReserve(s.allocatedCanvas, s.pendingCanvasTokens);
        }
    }
}
