// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

interface IVRFV2PlusConsumerLike {
    function rawFulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) external;
}

contract MockVRFCoordinatorV2Plus {
    uint256 public nextRequestId = 1;

    struct Request {
        address requester;
        uint32 numWords;
    }

    mapping(uint256 requestId => Request) public requests;

    event RandomWordsRequested(uint256 indexed requestId, address indexed requester, uint32 numWords);
    event RandomWordsFulfilled(uint256 indexed requestId, address indexed consumer);

    function requestRandomWords(VRFV2PlusClient.RandomWordsRequest calldata req) external returns (uint256 requestId) {
        requestId = nextRequestId++;
        requests[requestId] = Request({requester: msg.sender, numWords: req.numWords});
        emit RandomWordsRequested(requestId, msg.sender, req.numWords);
    }

    function fulfill(uint256 requestId, uint256 seed) external {
        Request memory r = requests[requestId];
        require(r.requester != address(0), "unknown request");
        uint256[] memory words = new uint256[](r.numWords);
        for (uint256 i = 0; i < r.numWords; i++) {
            words[i] = uint256(keccak256(abi.encode(seed, requestId, i)));
        }
        IVRFV2PlusConsumerLike(r.requester).rawFulfillRandomWords(requestId, words);
        emit RandomWordsFulfilled(requestId, r.requester);
    }
}
