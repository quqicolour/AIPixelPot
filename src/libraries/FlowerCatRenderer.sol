// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

library FlowerCatRenderer {
    using Strings for uint256;

    struct Traits {
        uint8 background;
        uint8 fur;
        uint8 eyes;
        uint8 ears;
        uint8 pose;
        uint8 expression;
        uint8 mouth;
        uint8 nose;
        uint8 whiskers;
        uint8 flower;
        uint8 pattern;
        uint8 aura;
    }

    uint256 internal constant BACKGROUND_COUNT = 20;
    uint256 internal constant FUR_COUNT = 20;
    uint256 internal constant EYES_COUNT = 15;
    uint256 internal constant EARS_COUNT = 8;
    uint256 internal constant POSE_COUNT = 10;
    uint256 internal constant EXPRESSION_COUNT = 10;
    uint256 internal constant MOUTH_COUNT = 8;
    uint256 internal constant NOSE_COUNT = 8;
    uint256 internal constant WHISKERS_COUNT = 6;
    uint256 internal constant FLOWER_COUNT = 12;
    uint256 internal constant PATTERN_COUNT = 12;
    uint256 internal constant AURA_COUNT = 8;

    function traitSpace() internal pure returns (uint256) {
        return
            BACKGROUND_COUNT *
            FUR_COUNT *
            EYES_COUNT *
            EARS_COUNT *
            POSE_COUNT *
            EXPRESSION_COUNT *
            MOUTH_COUNT *
            NOSE_COUNT *
            WHISKERS_COUNT *
            FLOWER_COUNT *
            PATTERN_COUNT *
            AURA_COUNT;
    }

    function traitsFromSeed(
        uint256 seed
    ) internal pure returns (Traits memory t) {
        uint256 x = seed;
        t.background = uint8(x % BACKGROUND_COUNT);
        x /= BACKGROUND_COUNT;
        t.fur = uint8(x % FUR_COUNT);
        x /= FUR_COUNT;
        t.eyes = uint8(x % EYES_COUNT);
        x /= EYES_COUNT;
        t.ears = uint8(x % EARS_COUNT);
        x /= EARS_COUNT;
        t.pose = uint8(x % POSE_COUNT);
        x /= POSE_COUNT;
        t.expression = uint8(x % EXPRESSION_COUNT);
        x /= EXPRESSION_COUNT;
        t.mouth = uint8(x % MOUTH_COUNT);
        x /= MOUTH_COUNT;
        t.nose = uint8(x % NOSE_COUNT);
        x /= NOSE_COUNT;
        t.whiskers = uint8(x % WHISKERS_COUNT);
        x /= WHISKERS_COUNT;
        t.flower = uint8(x % FLOWER_COUNT);
        x /= FLOWER_COUNT;
        t.pattern = uint8(x % PATTERN_COUNT);
        x /= PATTERN_COUNT;
        t.aura = uint8(x % AURA_COUNT);
    }

    function renderPending(
        uint256 tokenId
    ) internal pure returns (string memory) {
        return
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="1000" height="1000" viewBox="0 0 1000 1000">',
                '<defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#111827"/><stop offset="1" stop-color="#312e81"/></linearGradient></defs>',
                '<rect width="1000" height="1000" fill="url(#g)"/>',
                '<text x="60" y="120" fill="#fff" font-size="50" font-family="monospace">Flower Cat #',
                tokenId.toString(),
                "</text>",
                '<text x="60" y="190" fill="#c4b5fd" font-size="32" font-family="monospace">Waiting for Chainlink VRF...</text>',
                '<circle cx="500" cy="560" r="210" fill="#f9a8d4" opacity="0.25"/>',
                '<path d="M330 500 Q500 300 670 500 Q710 760 500 800 Q290 760 330 500Z" fill="#fff7ed"/>',
                '<circle cx="420" cy="555" r="26" fill="#111827"/><circle cx="580" cy="555" r="26" fill="#111827"/>',
                '<path d="M490 625 Q500 640 510 625" stroke="#111827" stroke-width="10" fill="none" stroke-linecap="round"/>',
                "</svg>"
            );
    }

    function renderCat(
        uint256 tokenId,
        uint256 seed,
        uint256 startCanvasId,
        uint256 canvasCount
    ) internal pure returns (string memory) {
        Traits memory t = traitsFromSeed(seed);
        string memory bg = _background(t.background, t.aura);
        string memory fur = _furColor(t.fur);
        string memory pattern = _pattern(seed, t.pattern, fur);
        string memory ears = _ears(t.ears, fur);
        string memory eyes = _eyes(t.eyes, t.expression);
        string memory mouth = _mouth(t.mouth, t.expression);
        string memory nose = _nose(t.nose);
        string memory whiskers = _whiskers(t.whiskers);
        string memory flowers = _flowers(seed, t.flower);
        string memory pose = _pose(t.pose, fur);

        return
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="1000" height="1000" viewBox="0 0 1000 1000">',
                bg,
                flowers,
                pose,
                ears,
                '<ellipse cx="500" cy="520" rx="220" ry="200" fill="',
                fur,
                '"/>',
                pattern,
                eyes,
                nose,
                mouth,
                whiskers,
                '<rect x="30" y="30" width="940" height="150" rx="30" fill="rgba(0,0,0,0.45)"/>',
                '<text x="60" y="86" fill="#ffffff" font-size="42" font-family="monospace">Flower Cat #',
                tokenId.toString(),
                "</text>",
                '<text x="60" y="132" fill="#dbeafe" font-size="26" font-family="monospace">Canvas ',
                startCanvasId.toString(),
                " - ",
                (startCanvasId + canvasCount - 1).toString(),
                "</text>",
                '<text x="60" y="164" fill="#bbf7d0" font-size="26" font-family="monospace">Count ',
                canvasCount.toString(),
                "</text>",
                "</svg>"
            );
    }

    function renderKing(
        uint256 tokenId,
        address winner,
        uint256 seed,
        uint256 prizeWei
    ) internal pure returns (string memory) {
        string memory shortWinner = _addressText(winner);
        return
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="1000" height="1000" viewBox="0 0 1000 1000">',
                '<defs><radialGradient id="kg" cx="50%" cy="45%" r="70%"><stop stop-color="#fde68a"/><stop offset="0.55" stop-color="#7c2d12"/><stop offset="1" stop-color="#020617"/></radialGradient></defs>',
                '<rect width="1000" height="1000" fill="url(#kg)"/>',
                '<circle cx="500" cy="540" r="270" fill="#fbbf24" opacity="0.18"/>',
                '<path d="M280 330 L360 170 L460 310 L540 150 L640 310 L730 175 L720 360 Z" fill="#facc15" stroke="#713f12" stroke-width="14"/>',
                '<circle cx="360" cy="190" r="24" fill="#ef4444"/><circle cx="540" cy="170" r="24" fill="#3b82f6"/><circle cx="730" cy="195" r="24" fill="#22c55e"/>',
                '<path d="M300 520 Q500 250 700 520 Q750 815 500 860 Q250 815 300 520Z" fill="#fef3c7" stroke="#78350f" stroke-width="12"/>',
                '<path d="M310 510 L225 365 L390 420Z" fill="#fef3c7" stroke="#78350f" stroke-width="12"/>',
                '<path d="M690 510 L775 365 L610 420Z" fill="#fef3c7" stroke="#78350f" stroke-width="12"/>',
                '<ellipse cx="420" cy="570" rx="42" ry="55" fill="#111827"/><ellipse cx="580" cy="570" rx="42" ry="55" fill="#111827"/>',
                '<circle cx="405" cy="548" r="12" fill="#ffffff"/><circle cx="565" cy="548" r="12" fill="#ffffff"/>',
                '<path d="M500 635 L465 610 L535 610 Z" fill="#fb7185"/>',
                '<path d="M500 640 Q465 695 420 665" stroke="#111827" stroke-width="12" fill="none" stroke-linecap="round"/>',
                '<path d="M500 640 Q535 695 580 665" stroke="#111827" stroke-width="12" fill="none" stroke-linecap="round"/>',
                '<path d="M285 630 H110 M285 675 H110 M715 630 H890 M715 675 H890" stroke="#fef3c7" stroke-width="10" stroke-linecap="round"/>',
                '<rect x="36" y="36" width="928" height="170" rx="34" fill="rgba(0,0,0,0.52)"/>',
                '<text x="65" y="95" fill="#fff7ed" font-size="46" font-family="monospace">King Flower Cat #',
                tokenId.toString(),
                "</text>",
                '<text x="65" y="145" fill="#fde68a" font-size="27" font-family="monospace">Winner ',
                shortWinner,
                "</text>",
                '<text x="65" y="180" fill="#bbf7d0" font-size="25" font-family="monospace">Prize Wei ',
                prizeWei.toString(),
                "</text>",
                '<text x="650" y="925" fill="#fde68a" font-size="22" font-family="monospace">seed ',
                (seed % 1000000).toString(),
                "</text>",
                "</svg>"
            );
    }

    function attributesJSON(
        uint256 seed,
        uint256 startCanvasId,
        uint256 canvasCount,
        bool finalized
    ) internal pure returns (string memory) {
        if (!finalized) {
            return '[{"trait_type":"Status","value":"Pending VRF"}]';
        }
        Traits memory t = traitsFromSeed(seed);
        return
            string.concat(
                "[",
                '{"trait_type":"Status","value":"Finalized"},',
                '{"trait_type":"Start Canvas ID","value":',
                startCanvasId.toString(),
                "},",
                '{"trait_type":"Canvas Count","value":',
                canvasCount.toString(),
                "},",
                '{"trait_type":"Background","value":"',
                _backgroundName(t.background),
                '"},',
                '{"trait_type":"Fur","value":"',
                _furName(t.fur),
                '"},',
                '{"trait_type":"Eyes","value":"',
                _eyeName(t.eyes),
                '"},',
                '{"trait_type":"Ears","value":"',
                _earName(t.ears),
                '"},',
                '{"trait_type":"Pose","value":"',
                _poseName(t.pose),
                '"},',
                '{"trait_type":"Expression","value":"',
                _expressionName(t.expression),
                '"},',
                '{"trait_type":"Mouth","value":"',
                _mouthName(t.mouth),
                '"},',
                '{"trait_type":"Nose","value":"',
                _noseName(t.nose),
                '"},',
                '{"trait_type":"Whiskers","value":"',
                _whiskerName(t.whiskers),
                '"},',
                '{"trait_type":"Flower","value":"',
                _flowerName(t.flower),
                '"},',
                '{"trait_type":"Pattern","value":"',
                _patternName(t.pattern),
                '"},',
                '{"trait_type":"Aura","value":"',
                _auraName(t.aura),
                '"}',
                "]"
            );
    }

    function kingAttributesJSON(
        address winner,
        uint256 prizeWei
    ) internal pure returns (string memory) {
        return
            string.concat(
                "[",
                '{"trait_type":"Status","value":"King"},',
                '{"trait_type":"Winner","value":"',
                _addressText(winner),
                '"},',
                '{"trait_type":"Prize Wei","value":',
                prizeWei.toString(),
                "}",
                "]"
            );
    }

    function _background(
        uint8 id,
        uint8 aura
    ) private pure returns (string memory) {
        string memory c1 = _palette(id);
        string memory c2 = _palette(uint8((id + aura + 7) % 20));
        return
            string.concat(
                '<defs><linearGradient id="bg" x1="0" y1="0" x2="1" y2="1"><stop stop-color="',
                c1,
                '"/><stop offset="1" stop-color="',
                c2,
                '"/></linearGradient></defs><rect width="1000" height="1000" fill="url(#bg)"/>'
            );
    }

    function _pose(
        uint8 id,
        string memory fur
    ) private pure returns (string memory) {
        uint256 bodyY = 780 + (uint256(id % 3) * 8);
        uint256 tilt = uint256(id % 5) * 10;
        return
            string.concat(
                '<ellipse cx="500" cy="',
                bodyY.toString(),
                '" rx="260" ry="170" fill="',
                fur,
                '" opacity="0.95"/><path d="M',
                (300 + tilt).toString(),
                " 780 Q500 900 ",
                (700 - tilt).toString(),
                ' 780" stroke="#111827" stroke-width="10" fill="none" opacity="0.2"/>'
            );
    }

    function _ears(
        uint8 id,
        string memory fur
    ) private pure returns (string memory) {
        uint256 left = 285 + uint256(id % 4) * 8;
        uint256 right = 715 - uint256(id % 4) * 8;
        return
            string.concat(
                '<path d="M',
                left.toString(),
                ' 470 L220 280 L390 390Z" fill="',
                fur,
                '"/><path d="M',
                right.toString(),
                ' 470 L780 280 L610 390Z" fill="',
                fur,
                '"/><path d="M295 420 L255 330 L360 395Z" fill="#f9a8d4" opacity="0.7"/><path d="M705 420 L745 330 L640 395Z" fill="#f9a8d4" opacity="0.7"/>'
            );
    }

    function _eyes(
        uint8 id,
        uint8 expression
    ) private pure returns (string memory) {
        string memory color = _palette(uint8((id * 3 + 2) % 20));
        if (expression % 5 == 0) {
            return
                string.concat(
                    '<path d="M380 560 Q420 520 460 560" stroke="#111827" stroke-width="16" fill="none" stroke-linecap="round"/><path d="M540 560 Q580 520 620 560" stroke="#111827" stroke-width="16" fill="none" stroke-linecap="round"/>'
                );
        }
        uint256 ry = 34 + uint256(id % 4) * 5;
        return
            string.concat(
                '<ellipse cx="420" cy="555" rx="38" ry="',
                ry.toString(),
                '" fill="#111827"/><ellipse cx="580" cy="555" rx="38" ry="',
                ry.toString(),
                '" fill="#111827"/><circle cx="420" cy="555" r="18" fill="',
                color,
                '"/><circle cx="580" cy="555" r="18" fill="',
                color,
                '"/><circle cx="407" cy="540" r="8" fill="#fff"/><circle cx="567" cy="540" r="8" fill="#fff"/>'
            );
    }

    function _mouth(
        uint8 id,
        uint8 expression
    ) private pure returns (string memory) {
        if (expression % 4 == 0)
            return
                '<path d="M500 650 Q455 710 410 670" stroke="#111827" stroke-width="10" fill="none" stroke-linecap="round"/><path d="M500 650 Q545 710 590 670" stroke="#111827" stroke-width="10" fill="none" stroke-linecap="round"/>';
        if (id % 3 == 0)
            return
                '<ellipse cx="500" cy="675" rx="38" ry="22" fill="#7f1d1d" opacity="0.85"/>';
        if (id % 3 == 1)
            return
                '<path d="M455 665 Q500 705 545 665" stroke="#111827" stroke-width="10" fill="none" stroke-linecap="round"/>';
        return
            '<path d="M500 650 Q475 685 450 665 M500 650 Q525 685 550 665" stroke="#111827" stroke-width="10" fill="none" stroke-linecap="round"/>';
    }

    function _nose(uint8 id) private pure returns (string memory) {
        string memory c = id % 2 == 0 ? "#fb7185" : "#f472b6";
        return
            string.concat(
                '<path d="M500 610 L465 585 L535 585 Z" fill="',
                c,
                '"/>'
            );
    }

    function _whiskers(uint8 id) private pure returns (string memory) {
        uint256 w = 5 + uint256(id % 4) * 2;
        return
            string.concat(
                '<path d="M360 625 H170 M360 655 H150 M640 625 H830 M640 655 H850" stroke="#111827" stroke-width="',
                w.toString(),
                '" stroke-linecap="round" opacity="0.65"/>'
            );
    }

    function _flowers(
        uint256 seed,
        uint8 flower
    ) private pure returns (string memory s) {
        string memory c = _palette(uint8((flower * 5 + 3) % 20));
        for (uint256 i = 0; i < 8; i++) {
            uint256 r = uint256(keccak256(abi.encode(seed, flower, i)));
            uint256 x = 90 + (r % 820);
            uint256 y = 230 + ((r / 1000) % 650);
            uint256 size = 12 + ((r / 1e6) % 18);
            s = string.concat(
                s,
                '<g transform="translate(',
                x.toString(),
                " ",
                y.toString(),
                ')"><circle cx="0" cy="0" r="',
                size.toString(),
                '" fill="',
                c,
                '" opacity="0.7"/><circle cx="',
                size.toString(),
                '" cy="0" r="',
                (size / 2).toString(),
                '" fill="#fff7ed" opacity="0.8"/><circle cx="0" cy="',
                size.toString(),
                '" r="',
                (size / 2).toString(),
                '" fill="#fff7ed" opacity="0.8"/></g>'
            );
        }
    }

    function _pattern(
        uint256 seed,
        uint8 id,
        string memory
    ) private pure returns (string memory s) {
        string memory c = _palette(uint8((id * 7 + 4) % 20));
        uint256 n = 5 + uint256(id % 7);
        for (uint256 i = 0; i < n; i++) {
            uint256 r = uint256(keccak256(abi.encode(seed, id, i, "pattern")));
            uint256 x = 330 + (r % 340);
            uint256 y = 430 + ((r / 1000) % 210);
            uint256 rx = 20 + ((r / 1e6) % 45);
            s = string.concat(
                s,
                '<ellipse cx="',
                x.toString(),
                '" cy="',
                y.toString(),
                '" rx="',
                rx.toString(),
                '" ry="18" fill="',
                c,
                '" opacity="0.28"/>'
            );
        }
    }

    function _palette(uint8 id) private pure returns (string memory) {
        string[20] memory p = [
            "#fef3c7",
            "#fde68a",
            "#fbcfe8",
            "#f9a8d4",
            "#c4b5fd",
            "#a5b4fc",
            "#93c5fd",
            "#67e8f9",
            "#86efac",
            "#bbf7d0",
            "#fed7aa",
            "#fdba74",
            "#fca5a5",
            "#d9f99d",
            "#ccfbf1",
            "#e9d5ff",
            "#ddd6fe",
            "#bae6fd",
            "#fecdd3",
            "#fafaf9"
        ];
        return p[id % 20];
    }

    function _furColor(uint8 id) private pure returns (string memory) {
        string[20] memory p = [
            "#fff7ed",
            "#ffedd5",
            "#fed7aa",
            "#fdba74",
            "#fb923c",
            "#fef3c7",
            "#fde68a",
            "#f5f5f4",
            "#e7e5e4",
            "#d6d3d1",
            "#a8a29e",
            "#78716c",
            "#f9a8d4",
            "#f0abfc",
            "#c4b5fd",
            "#bfdbfe",
            "#bbf7d0",
            "#fecaca",
            "#fef9c3",
            "#f8fafc"
        ];
        return p[id % 20];
    }

    function _backgroundName(uint8 id) private pure returns (string memory) {
        return _name20(id);
    }
    function _furName(uint8 id) private pure returns (string memory) {
        return _name20(id);
    }
    function _eyeName(uint8 id) private pure returns (string memory) {
        return _name15(id);
    }
    function _earName(uint8 id) private pure returns (string memory) {
        return _name8(id);
    }
    function _poseName(uint8 id) private pure returns (string memory) {
        return _name10(id);
    }
    function _expressionName(uint8 id) private pure returns (string memory) {
        return _name10(id);
    }
    function _mouthName(uint8 id) private pure returns (string memory) {
        return _name8(id);
    }
    function _noseName(uint8 id) private pure returns (string memory) {
        return _name8(id);
    }
    function _whiskerName(uint8 id) private pure returns (string memory) {
        return _name6(id);
    }
    function _flowerName(uint8 id) private pure returns (string memory) {
        return string.concat("Flower ", uint256(id + 1).toString());
    }
    function _patternName(uint8 id) private pure returns (string memory) {
        return string.concat("Pattern ", uint256(id + 1).toString());
    }
    function _auraName(uint8 id) private pure returns (string memory) {
        return _name8(id);
    }

    function _name20(uint8 id) private pure returns (string memory) {
        return string.concat("Type ", uint256(id + 1).toString());
    }
    function _name15(uint8 id) private pure returns (string memory) {
        return string.concat("Type ", uint256(id + 1).toString());
    }
    function _name10(uint8 id) private pure returns (string memory) {
        return string.concat("Type ", uint256(id + 1).toString());
    }
    function _name8(uint8 id) private pure returns (string memory) {
        return string.concat("Type ", uint256(id + 1).toString());
    }
    function _name6(uint8 id) private pure returns (string memory) {
        return string.concat("Type ", uint256(id + 1).toString());
    }

    function _addressText(address a) private pure returns (string memory) {
        bytes20 value = bytes20(a);
        bytes16 alphabet = "0123456789abcdef";
        bytes memory str = new bytes(42);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[i] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i] & 0x0f)];
        }
        return string(str);
    }
}
