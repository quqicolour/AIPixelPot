// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/// @title IVRFCoordinatorLike
/// @notice VRF Coordinator 接口 (适配 Chainlink VRF V2Plus)
/// @dev 实际使用时替换为 @chainlink/contracts/src/v0.8/vrf/dev/VRFCoordinatorV2_5.sol
interface IVRFCoordinatorLike {
    /// @notice 请求随机数
    /// @param req 请求参数
    /// @return requestId 请求ID
    function requestRandomWords(
        VRFV2PlusClient.RandomWordsRequest calldata req
    ) external returns (uint256 requestId);
}
