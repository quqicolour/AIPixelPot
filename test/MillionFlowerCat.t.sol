// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {StdError} from "forge-std/StdError.sol";

import {MillionFlowerCat} from "../src/core/MillionFlowerCat.sol";
import {MockVRFCoordinatorV2Plus} from "../src/mocks/MockVRFCoordinatorV2Plus.sol";
import {FlowerCatRenderer} from "../src/libraries/FlowerCatRenderer.sol";
import {Errors} from "../src/libraries/Errors.sol";
import {SeedLib} from "../src/libraries/SeedLib.sol";
import {CanvasLib} from "../src/libraries/CanvasLib.sol";
import {HolderLib} from "../src/libraries/HolderLib.sol";
import {MillionFlowerCatStorage} from "../src/storage/MillionFlowerCatStorage.sol";

/// @title MillionFlowerCatTest
/// @notice MillionFlowerCat 核心 NFT 合约完整测试套件
contract MillionFlowerCatTest is Test {
    // ══════════════════════════════════════════════════════════════
    // 合约实例
    // ══════════════════════════════════════════════════════════════

    MillionFlowerCat public nft;
    MockVRFCoordinatorV2Plus public vrfCoordinator;

    // ══════════════════════════════════════════════════════════════
    // 测试角色
    // ══════════════════════════════════════════════════════════════

    address public owner;
    address public alice;
    address public bob;
    address public carol;

    // ══════════════════════════════════════════════════════════════
    // 常量
    // ══════════════════════════════════════════════════════════════

    uint256 constant MINT_PRICE = 0.01 ether;
    uint256 constant VRF_SUBSCRIPTION_ID = 1;
    bytes32 constant VRF_KEY_HASH = bytes32(0x1234abcd);
    uint256 constant TOTAL_CANVAS = 1_000_000;
    uint256 constant MAX_MINT_PER_TX = 10;

    // ══════════════════════════════════════════════════════════════
    // 初始化
    // ══════════════════════════════════════════════════════════════

    function setUp() public {
        owner = address(this);
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        carol = makeAddr("carol");

        // 部署 VRF Mock
        vrfCoordinator = new MockVRFCoordinatorV2Plus();

        // 部署 NFT 合约
        nft = new MillionFlowerCat(
            owner,
            address(vrfCoordinator),
            VRF_KEY_HASH,
            VRF_SUBSCRIPTION_ID,
            MINT_PRICE
        );

        // 开启销售
        nft.setSaleActive(true);

        // 给用户 ETH
        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
        vm.deal(carol, 100 ether);
    }

    // ══════════════════════════════════════════════════════════════
    // TC-01: 初始状态验证
    // ══════════════════════════════════════════════════════════════

    function test_TC01_initialState() public view {
        assertEq(nft.name(), "Million Flower Cat");
        assertEq(nft.symbol(), "MFLOWERCAT");
        assertEq(nft.mintPrice(), MINT_PRICE);
        assertTrue(nft.saleActive());
        assertFalse(nft.salePermanentlyClosed());
        assertEq(nft.allocatedCanvas(), 0);
        assertEq(nft.pendingCanvasTokens(), 0);
        assertEq(nft.regularMinted(), 0);
        assertFalse(nft.kingRequested());
        assertFalse(nft.kingMinted());
        assertEq(nft.totalSupply(), 0);
        assertEq(nft.holderCount(), 0);
        assertEq(nft.TOTAL_CANVAS(), TOTAL_CANVAS);
    }

    // ══════════════════════════════════════════════════════════════
    // TC-02: 单个 NFT 铸造
    // ══════════════════════════════════════════════════════════════

    function test_TC02_mintSingle() public {
        vm.prank(alice);
        uint256 requestId = nft.mint{value: MINT_PRICE}(1);

        assertEq(nft.regularMinted(), 1);
        assertEq(nft.pendingCanvasTokens(), 1);
        assertEq(nft.totalSupply(), 1);
        assertEq(nft.ownerOf(1), alice);
        assertEq(requestId, 1);
        assertEq(nft.holderCount(), 1);
        assertTrue(nft.isHolder(alice));
        assertEq(nft.holderAt(0), alice);
    }

    // ══════════════════════════════════════════════════════════════
    // TC-03: 批量铸造
    // ══════════════════════════════════════════════════════════════

    function test_TC03_mintMultiple() public {
        vm.prank(alice);
        nft.mint{value: MINT_PRICE * 3}(3);

        assertEq(nft.regularMinted(), 3);
        assertEq(nft.pendingCanvasTokens(), 3);
        assertEq(nft.totalSupply(), 3);
        assertEq(nft.ownerOf(1), alice);
        assertEq(nft.ownerOf(2), alice);
        assertEq(nft.ownerOf(3), alice);
        assertEq(nft.holderCount(), 1);
    }

    // ══════════════════════════════════════════════════════════════
    // TC-04: 多用户铸造
    // ══════════════════════════════════════════════════════════════

    function test_TC04_mintByMultipleUsers() public {
        vm.prank(alice);
        nft.mint{value: MINT_PRICE * 2}(2);
        assertEq(nft.holderCount(), 1);

        vm.prank(bob);
        nft.mint{value: MINT_PRICE}(1);

        assertEq(nft.totalSupply(), 3);
        assertEq(nft.holderCount(), 2);
        assertTrue(nft.isHolder(alice));
        assertTrue(nft.isHolder(bob));
    }

    // ══════════════════════════════════════════════════════════════
    // TC-05: 铸造上限验证
    // ══════════════════════════════════════════════════════════════

    function test_TC05_maxMintPerTx() public {
        vm.prank(alice);
        nft.mint{value: MINT_PRICE * MAX_MINT_PER_TX}(MAX_MINT_PER_TX);
        assertEq(nft.totalSupply(), MAX_MINT_PER_TX);
    }

    function test_TC06_failZeroQuantity() public {
        vm.prank(alice);
        vm.expectRevert(Errors.InvalidQuantity.selector);
        nft.mint{value: 0}(0);
    }

    function test_TC07_failExceedMaxPerTx() public {
        vm.prank(alice);
        vm.expectRevert(Errors.InvalidQuantity.selector);
        nft.mint{value: MINT_PRICE * 11}(11);
    }

    function test_TC08_failWrongValue() public {
        vm.prank(alice);
        vm.expectRevert(Errors.WrongValue.selector);
        nft.mint{value: MINT_PRICE - 1}(1);
    }

    function test_TC09_failSaleClosed() public {
        nft.setSaleActive(false);
        vm.prank(alice);
        vm.expectRevert(Errors.SaleClosed.selector);
        nft.mint{value: MINT_PRICE}(1);
    }

    // ══════════════════════════════════════════════════════════════
    // TC-10: VRF 回调 - Canvas 分配
    // ══════════════════════════════════════════════════════════════

    function test_TC10_fulfillCanvasBatch() public {
        vm.prank(alice);
        uint256 requestId = nft.mint{value: MINT_PRICE * 2}(2);

        assertEq(nft.pendingCanvasTokens(), 2);
        assertEq(nft.allocatedCanvas(), 0);

        // 触发 VRF 回调
        vrfCoordinator.fulfill(requestId, 12345);

        assertEq(nft.pendingCanvasTokens(), 0);
        assertGt(nft.allocatedCanvas(), 0);
        assertEq(nft.allocatedCanvas(), 2);
    }

    function test_TC11_fulfillDifferentSeeds() public {
        vm.prank(bob);
        uint256 requestId = nft.mint{value: MINT_PRICE * 3}(3);

        vrfCoordinator.fulfill(requestId, 99999);

        (, uint16 count1, uint256 seed1, ) = nft.canvasOf(1);
        (, uint16 count2, uint256 seed2, ) = nft.canvasOf(2);
        (, uint16 count3, uint256 seed3, ) = nft.canvasOf(3);

        assertTrue(count1 > 0 && count1 <= 500);
        assertTrue(count2 > 0 && count2 <= 500);
        assertTrue(count3 > 0 && count3 <= 500);
        assertTrue(seed1 > 0 && seed2 > 0 && seed3 > 0);
    }

    function test_TC12_fulfillIdempotent() public {
        vm.prank(alice);
        uint256 requestId = nft.mint{value: MINT_PRICE}(1);

        vrfCoordinator.fulfill(requestId, 11111);
        assertEq(nft.pendingCanvasTokens(), 0);

        uint256 allocatedBefore = nft.allocatedCanvas();
        vrfCoordinator.fulfill(requestId, 22222); // 第二次应该跳过
        assertEq(nft.allocatedCanvas(), allocatedBefore);
    }

    // ══════════════════════════════════════════════════════════════
    // TC-13: tokenURI 测试
    // ══════════════════════════════════════════════════════════════

    function test_TC13_tokenURI_pending() public {
        vm.prank(alice);
        nft.mint{value: MINT_PRICE}(1);

        string memory uri = nft.tokenURI(1);
        assertTrue(bytes(uri).length > 0);
        assertTrue(_contains(uri, "data:application/json;base64,"));
        assertTrue(_contains(uri, "Pending") || _contains(uri, "Waiting"));
    }

    function test_TC14_tokenURI_finalized() public {
        vm.prank(alice);
        uint256 requestId = nft.mint{value: MINT_PRICE}(1);
        vrfCoordinator.fulfill(requestId, 12345);

        string memory uri = nft.tokenURI(1);
        assertTrue(bytes(uri).length > 0);
        assertTrue(_contains(uri, "data:application/json;base64,"));
        assertTrue(_contains(uri, "Flower Cat"));
    }

    function test_TC15_tokenURI_nonexistent() public {
        vm.expectRevert(Errors.TokenNotFinalized.selector);
        nft.tokenURI(999);
    }

    // ══════════════════════════════════════════════════════════════
    // TC-16: NFT 转账 & Holder 管理
    // ══════════════════════════════════════════════════════════════

    function test_TC16_holderAfterTransfer() public {
        vm.prank(alice);
        nft.mint{value: MINT_PRICE}(1);

        assertTrue(nft.isHolder(alice));
        assertEq(nft.holderCount(), 1);

        vm.prank(alice);
        nft.safeTransferFrom(alice, bob, 1);

        assertFalse(nft.isHolder(alice));
        assertTrue(nft.isHolder(bob));
        assertEq(nft.holderCount(), 1);
    }

    function test_TC17_holderAfterBurn() public {
        vm.prank(alice);
        nft.mint{value: MINT_PRICE}(1);

        assertTrue(nft.isHolder(alice));
        assertEq(nft.holderCount(), 1);

        vm.prank(alice);
        nft.burn(1);

        assertFalse(nft.isHolder(alice));
        assertEq(nft.holderCount(), 0);
    }

    // ══════════════════════════════════════════════════════════════
    // TC-18: Owner 函数测试
    // ══════════════════════════════════════════════════════════════

    function test_TC18_setSaleActive() public {
        assertTrue(nft.saleActive());
        nft.setSaleActive(false);
        assertFalse(nft.saleActive());
        nft.setSaleActive(true);
        assertTrue(nft.saleActive());
    }

    function test_TC19_setSaleActive_nonOwner() public {
        vm.prank(alice);
        vm.expectRevert("Ownable: caller is not the owner");
        nft.setSaleActive(false);
    }

    function test_TC20_setMintPrice() public {
        nft.setMintPrice(0.05 ether);
        assertEq(nft.mintPrice(), 0.05 ether);

        vm.prank(alice);
        vm.expectRevert(Errors.WrongValue.selector);
        nft.mint{value: 0.01 ether}(1);
    }

    function test_TC21_setMintPriceZero() public {
        vm.expectRevert(Errors.MintPriceZero.selector);
        nft.setMintPrice(0);
    }

    function test_TC22_setVRFConfig() public {
        nft.setVRFConfig(bytes32(0xabcd), 42, 500_000, 5, true);

        assertEq(nft.keyHash(), bytes32(0xabcd));
        assertEq(nft.subscriptionId(), 42);
        assertEq(nft.callbackGasLimit(), 500_000);
        assertEq(nft.requestConfirmations(), 5);
        assertTrue(nft.nativePayment());
    }

    // ══════════════════════════════════════════════════════════════
    // TC-23: King 抽奖测试
    // ══════════════════════════════════════════════════════════════

    function test_TC23_kingRandomnessRequest() public {
        vm.prank(alice);
        nft.mint{value: MINT_PRICE * 5}(5);

        vrfCoordinator.fulfill(1, 12345);

        uint256 kingReqId = nft.requestKingRandomnessManually();

        assertTrue(nft.kingRequested());
        assertFalse(nft.saleActive());
        assertTrue(nft.salePermanentlyClosed());
        assertEq(kingReqId, 2);
    }

    function test_TC24_kingManual_onlyOwner() public {
        vm.prank(alice);
        vm.expectRevert("Ownable: caller is not the owner");
        nft.requestKingRandomnessManually();
    }

    function test_TC25_kingManual_beforeCanvasSoldOut() public {
        vm.prank(alice);
        nft.mint{value: MINT_PRICE}(1);
        vm.expectRevert(Errors.CanvasSoldOut.selector);
        nft.requestKingRandomnessManually();
    }

    // ══════════════════════════════════════════════════════════════
    // TC-26: 完整 King 流程
    // ══════════════════════════════════════════════════════════════

    function test_TC26_fullKingFlow() public {
        // Arrange: 3 个用户 mint
        vm.prank(alice);
        uint256 req1 = nft.mint{value: MINT_PRICE * 3}(3);
        vm.prank(bob);
        uint256 req2 = nft.mint{value: MINT_PRICE * 2}(2);
        vm.prank(carol);
        uint256 req3 = nft.mint{value: MINT_PRICE}(1);

        // VRF 回调
        vrfCoordinator.fulfill(req1, 111);
        vrfCoordinator.fulfill(req2, 222);
        vrfCoordinator.fulfill(req3, 333);

        // 充入奖金
        vm.deal(address(nft), 10 ether);

        // Owner 请求 King
        uint256 kingReqId = nft.requestKingRandomnessManually();
        vrfCoordinator.fulfill(kingReqId, 777);

        // Assert
        assertTrue(nft.kingMinted());
        assertGt(nft.kingPrize(), 0);
        assertTrue(nft.kingWinner() != address(0));
        assertEq(nft.ownerOf(nft.kingTokenId()), nft.kingWinner());

        string memory uri = nft.tokenURI(nft.kingTokenId());
        assertTrue(bytes(uri).length > 0);
        assertTrue(_contains(uri, "data:application/json;base64,"));
    }

    function test_TC27_claimPrize() public {
        _runFullKingFlow();

        address winner = nft.kingWinner();
        uint256 prize = nft.kingPrize();
        uint256 winnerBalanceBefore = winner.balance;

        vm.prank(winner);
        nft.claimPrize();

        assertEq(winner.balance, winnerBalanceBefore + prize);
        assertEq(nft.claimablePrize(winner), 0);
    }

    function test_TC28_claimPrize_onlyWinner() public {
        _runFullKingFlow();

        vm.prank(alice);
        vm.expectRevert(Errors.NoPrize.selector);
        nft.claimPrize();
    }

    function test_TC29_claimPrize_idempotent() public {
        _runFullKingFlow();

        address winner = nft.kingWinner();
        vm.prank(winner);
        nft.claimPrize();

        vm.prank(winner);
        vm.expectRevert(Errors.NoPrize.selector);
        nft.claimPrize();
    }

    // ══════════════════════════════════════════════════════════════
    // TC-30: 提款测试
    // ══════════════════════════════════════════════════════════════

    function test_TC30_withdrawRemainder() public {
        _runFullKingFlow();

        uint256 ownerBalanceBefore = owner.balance;
        uint256 prize = nft.kingPrize();
        uint256 contractBalance = address(nft).balance;

        nft.withdrawRemainder(payable(owner));

        assertEq(owner.balance, ownerBalanceBefore + (contractBalance - prize));
    }

    function test_TC31_withdrawRemainder_lockedBeforeKing() public {
        vm.prank(alice);
        nft.mint{value: MINT_PRICE}(1);

        vm.expectRevert(Errors.WithdrawLockedUntilKingSettled.selector);
        nft.withdrawRemainder(payable(owner));
    }

    function test_TC32_withdrawRemainder_invalidAddress() public {
        _runFullKingFlow();

        vm.expectRevert(Errors.InvalidWithdrawAddress.selector);
        nft.withdrawRemainder(payable(address(0)));
    }

    // ══════════════════════════════════════════════════════════════
    // TC-33: 查询函数
    // ══════════════════════════════════════════════════════════════

    function test_TC33_remainingCanvas() public view {
        assertEq(nft.remainingCanvasForNewMints(), TOTAL_CANVAS);
    }

    function test_TC34_traitSpace() public pure {
        uint256 space = nft.traitSpace();
        uint256 expected = 20 * 20 * 15 * 8 * 10 * 10 * 8 * 8 * 6 * 12 * 12 * 8;
        assertEq(space, expected);
    }

    // ══════════════════════════════════════════════════════════════
    // TC-35: 销售永久关闭
    // ══════════════════════════════════════════════════════════════

    function test_TC35_permanentlyClosed_blocksReopening() public {
        _runFullKingFlow();

        vm.expectRevert(Errors.SaleClosed.selector);
        nft.setSaleActive(true);
    }

    // ══════════════════════════════════════════════════════════════
    // 内部辅助
    // ══════════════════════════════════════════════════════════════

    function _runFullKingFlow() internal {
        vm.prank(alice);
        uint256 req1 = nft.mint{value: MINT_PRICE * 3}(3);
        vm.prank(bob);
        uint256 req2 = nft.mint{value: MINT_PRICE * 2}(2);
        vm.prank(carol);
        uint256 req3 = nft.mint{value: MINT_PRICE}(1);

        vrfCoordinator.fulfill(req1, 111);
        vrfCoordinator.fulfill(req2, 222);
        vrfCoordinator.fulfill(req3, 333);

        vm.deal(address(nft), 10 ether);

        uint256 kingReqId = nft.requestKingRandomnessManually();
        vrfCoordinator.fulfill(kingReqId, 777);
    }

    // ══════════════════════════════════════════════════════════════
    // 字符串辅助
    // ══════════════════════════════════════════════════════════════

    function _contains(string memory haystack, string memory needle)
        internal pure returns (bool)
    {
        bytes memory h = bytes(haystack);
        bytes memory n = bytes(needle);
        if (h.length < n.length) return false;
        for (uint256 i = 0; i <= h.length - n.length; i++) {
            bool found = true;
            for (uint256 j = 0; j < n.length; j++) {
                if (h[i + j] != n[j]) { found = false; break; }
            }
            if (found) return true;
        }
        return false;
    }
}

/// @title LibraryTest
/// @notice 独立库函数单元测试
contract LibraryTest is Test {
    // ══════════════════════════════════════════════════════════════
    // SeedLib 测试
    // ══════════════════════════════════════════════════════════════

    function test_SeedLib_deriveCanvasSeed() public pure {
        uint256 randomWord = 12345;
        uint256 tokenId = 7;
        uint256 chainId = 1;
        address contractAddr = address(0x1234567890123456789012345678901234567890);

        uint256 seed = SeedLib.deriveCanvasSeed(randomWord, tokenId, chainId, contractAddr);

        assertGt(seed, 0);
        // 相同输入必须产生相同输出
        uint256 seed2 = SeedLib.deriveCanvasSeed(randomWord, tokenId, chainId, contractAddr);
        assertEq(seed, seed2);
        // 不同输入产生不同输出
        uint256 seed3 = SeedLib.deriveCanvasSeed(randomWord + 1, tokenId, chainId, contractAddr);
        assertTrue(seed3 != seed);
    }

    function test_SeedLib_extractCanvasCount_normal() public pure {
        uint256 seed = 123456; // 不整除 100000
        uint256 canvasCount = SeedLib.extractCanvasCount(seed, 1000);
        assertTrue(canvasCount >= 1 && canvasCount <= 500);
        assertTrue(canvasCount <= 1000); // 受 maxAvailable 限制
    }

    function test_SeedLib_extractCanvasCount_zero() public pure {
        // 如果 seed % 100000 == 0，应返回 1
        // 这个我们用特殊构造的 seed 来测试
        uint256 seed = 200000; // 200000 % 100000 == 0
        uint256 canvasCount = SeedLib.extractCanvasCount(seed, 1000);
        assertEq(canvasCount, 1);
    }

    function test_SeedLib_extractCanvasCount_exceedsMax() public pure {
        // seed 产生 > 500 的数量，应该被限制
        // seed = 99999 -> canvasCount = 99999 -> 限制到 500
        uint256 seed = 99999 * 1000; // 大数
        uint256 canvasCount = SeedLib.extractCanvasCount(seed, 10000);
        assertEq(canvasCount, 500); // 被 MAX_CANVAS_PER_NFT 限制
    }

    function test_SeedLib_extractTraits() public pure {
        uint256 seed = uint256(keccak256(abi.encode("test seed")));

        (uint8 bg, uint8 fur, uint8 eyes, uint8 ears, uint8 pose, uint8 expr,
         uint8 mouth, uint8 nose, uint8 whiskers, uint8 flower,
         uint8 pattern, uint8 aura) = SeedLib.extractTraits(seed);

        assertTrue(bg < 20);
        assertTrue(fur < 20);
        assertTrue(eyes < 15);
        assertTrue(ears < 8);
        assertTrue(pose < 10);
        assertTrue(expr < 10);
        assertTrue(mouth < 8);
        assertTrue(nose < 8);
        assertTrue(whiskers < 6);
        assertTrue(flower < 12);
        assertTrue(pattern < 12);
        assertTrue(aura < 8);
    }

    // ══════════════════════════════════════════════════════════════
    // CanvasLib 测试
    // ══════════════════════════════════════════════════════════════

    function test_CanvasLib_remainingCanvas() public pure {
        assertEq(CanvasLib.remainingCanvas(0, 0), 1_000_000);
        assertEq(CanvasLib.remainingCanvas(500_000, 0), 500_000);
        assertEq(CanvasLib.remainingCanvas(500_000, 500_000), 0);
        assertEq(CanvasLib.remainingCanvas(900_000, 100_001), 0); // 超出
    }

    function test_CanvasLib_createAllocation() public pure {
        var alloc = CanvasLib.createAllocation(100, 50, 12345);

        assertEq(alloc.startCanvasId, 100);
        assertEq(alloc.canvasCount, 50);
        assertEq(alloc.seed, 12345);
        assertTrue(alloc.finalized);
    }

    function test_CanvasLib_nextStartCanvasId() public pure {
        assertEq(CanvasLib.nextStartCanvasId(0), 1);
        assertEq(CanvasLib.nextStartCanvasId(999_999), 1_000_000);
    }

    // ══════════════════════════════════════════════════════════════
    // HolderLib 测试
    // ══════════════════════════════════════════════════════════════

    function test_HolderLib_addHolder() public {
        address[] memory holders = new address[](0);

        HolderLib.addHolder(holders, this.holderMapping(), alice);
        HolderLib.addHolder(holders, this.holderMapping(), bob);

        assertEq(holders.length, 2);
        assertEq(holders[0], alice);
        assertEq(holders[1], bob);
    }

    function test_HolderLib_addHolder_noDuplicate() public {
        address[] memory holders = new address[](0);

        HolderLib.addHolder(holders, this.holderMapping(), alice);
        HolderLib.addHolder(holders, this.holderMapping(), alice); // 重复添加

        assertEq(holders.length, 1); // 仍然是 1
    }

    function test_HolderLib_removeHolder() public {
        address[] memory holders = new address[](3);
        holders[0] = alice;
        holders[1] = bob;
        holders[2] = carol;

        // 先添加映射
        HolderLib.addHolder(holders, this.holderMapping(), alice);
        HolderLib.addHolder(holders, this.holderMapping(), bob);
        HolderLib.addHolder(holders, this.holderMapping(), carol);

        HolderLib.removeHolder(holders, this.holderMapping(), bob);

        assertEq(holders.length, 2);
        assertTrue(holders[0] == carol || holders[1] == carol); // carol 被移到最后
    }

    // 用于 HolderLib 测试的映射
    function holderMapping() external returns (mapping(address => uint256) storage) {
        mapping(address => uint256) storage m;
        return m;
    }
}
