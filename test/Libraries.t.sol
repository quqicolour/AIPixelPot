// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";

import {SeedLib} from "../src/libraries/SeedLib.sol";
import {CanvasLib} from "../src/libraries/CanvasLib.sol";
import {MillionFlowerCatStorage} from "../src/storage/MillionFlowerCatStorage.sol";

/// @title LibrariesTest
/// @notice 独立库函数单元测试
contract LibrariesTest is Test {
    // ══════════════════════════════════════════════════════════════
    // SeedLib 测试
    // ══════════════════════════════════════════════════════════════

    function test_SeedLib_deriveCanvasSeed_deterministic() public pure {
        uint256 randomWord = 12345;
        uint256 tokenId = 7;
        uint256 chainId = 1;
        address contractAddr = address(0x1234567890123456789012345678901234567890);

        uint256 seed = SeedLib.deriveCanvasSeed(randomWord, tokenId, chainId, contractAddr);
        uint256 seed2 = SeedLib.deriveCanvasSeed(randomWord, tokenId, chainId, contractAddr);

        assertGt(seed, 0);
        assertEq(seed, seed2); // 确定性
    }

    function test_SeedLib_deriveCanvasSeed_differentInputs() public pure {
        uint256 randomWord = 12345;
        uint256 tokenId = 7;
        uint256 chainId = 1;
        address contractAddr = address(0x1234567890123456789012345678901234567890);

        uint256 seed = SeedLib.deriveCanvasSeed(randomWord, tokenId, chainId, contractAddr);
        uint256 seedDiff = SeedLib.deriveCanvasSeed(randomWord + 1, tokenId, chainId, contractAddr);

        assertTrue(seedDiff != seed); // 不同输入 -> 不同输出
    }

    function test_SeedLib_deriveKingSeed() public pure {
        uint256 randomWord = 999;
        uint256 requestId = 42;
        address contractAddr = address(0xabcd);
        uint256 chainId = 1;

        uint256 seed = SeedLib.deriveKingSeed(randomWord, requestId, contractAddr, chainId);
        uint256 seed2 = SeedLib.deriveKingSeed(randomWord, requestId, contractAddr, chainId);

        assertGt(seed, 0);
        assertEq(seed, seed2); // 确定性
    }

    function test_SeedLib_extractCanvasCount_normal() public pure {
        // seed = 77777 -> canvasCount = 77777 (但不超过 500)
        uint256 seed = 77777;
        uint256 canvasCount = SeedLib.extractCanvasCount(seed, 1_000_000);

        assertTrue(canvasCount >= 1);
        assertTrue(canvasCount <= 500);
        assertEq(canvasCount, 77777);
    }

    function test_SeedLib_extractCanvasCount_zeroSeedBecomesOne() public pure {
        // 当 seed % 100000 == 0 时，返回 1
        // seed = 100000 -> 100000 % 100000 == 0 -> return 1
        uint256 seed = 100000;
        uint256 canvasCount = SeedLib.extractCanvasCount(seed, 1_000_000);
        assertEq(canvasCount, 1);
    }

    function test_SeedLib_extractCanvasCount_exceedsMaxAvailable() public pure {
        // seed 产生 99999，但 maxAvailable 只有 100
        uint256 seed = 99999;
        uint256 canvasCount = SeedLib.extractCanvasCount(seed, 100);

        assertEq(canvasCount, 100); // 限制到 maxAvailable
    }

    function test_SeedLib_extractCanvasCount_exceedsMaxPerNft() public pure {
        // seed 产生很大的数，超过 MAX_CANVAS_PER_NFT=500
        // seed = 99999 * 5 -> 实际会用 seed % 100000
        uint256 seed = 99999; // 这是个小于 100000 的数，所以不会被截断
        uint256 canvasCount = SeedLib.extractCanvasCount(seed, 1_000_000);
        assertEq(canvasCount, 99999);
    }

    function test_SeedLib_extractTraits() public pure {
        uint256 seed = uint256(keccak256(abi.encode("unique test seed for traits")));

        (uint8 bg, uint8 fur, uint8 eyes, uint8 ears, uint8 pose, uint8 expr,
         uint8 mouth, uint8 nose, uint8 whiskers, uint8 flower,
         uint8 pattern, uint8 aura) = SeedLib.extractTraits(seed);

        assertTrue(bg < 20, "background out of range");
        assertTrue(fur < 20, "fur out of range");
        assertTrue(eyes < 15, "eyes out of range");
        assertTrue(ears < 8, "ears out of range");
        assertTrue(pose < 10, "pose out of range");
        assertTrue(expr < 10, "expression out of range");
        assertTrue(mouth < 8, "mouth out of range");
        assertTrue(nose < 8, "nose out of range");
        assertTrue(whiskers < 6, "whiskers out of range");
        assertTrue(flower < 12, "flower out of range");
        assertTrue(pattern < 12, "pattern out of range");
        assertTrue(aura < 8, "aura out of range");
    }

    // ══════════════════════════════════════════════════════════════
    // CanvasLib 测试
    // ══════════════════════════════════════════════════════════════

    function test_CanvasLib_remainingCanvas_full() public pure {
        assertEq(CanvasLib.remainingCanvas(0, 0), 1_000_000);
    }

    function test_CanvasLib_remainingCanvas_partial() public pure {
        assertEq(CanvasLib.remainingCanvas(300_000, 0), 700_000);
        assertEq(CanvasLib.remainingCanvas(300_000, 100_000), 600_000);
    }

    function test_CanvasLib_remainingCanvas_exhausted() public pure {
        assertEq(CanvasLib.remainingCanvas(500_000, 500_000), 0);
        assertEq(CanvasLib.remainingCanvas(999_999, 1), 0);
    }

    function test_CanvasLib_createAllocation() public pure {
        var alloc = CanvasLib.createAllocation(100, 50, 12345);

        assertEq(alloc.startCanvasId, 100, "wrong startCanvasId");
        assertEq(alloc.canvasCount, 50, "wrong canvasCount");
        assertEq(alloc.seed, 12345, "wrong seed");
        assertTrue(alloc.finalized, "should be finalized");
    }

    function test_CanvasLib_nextStartCanvasId() public pure {
        assertEq(CanvasLib.nextStartCanvasId(0), 1);
        assertEq(CanvasLib.nextStartCanvasId(1), 2);
        assertEq(CanvasLib.nextStartCanvasId(999_999), 1_000_000);
    }
}
