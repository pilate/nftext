// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Base64.sol";

contract NFText is ERC721Enumerable, Ownable {
    using Strings for uint256;
    mapping(uint256 => Word) public wordsToTokenId;

    struct Word {
        string text;
        string bgHue;
        string textHue;
    }

    constructor() ERC721("NFText", "NTXT") {}

    function mint(string memory _userText) public payable {
        uint256 supply = totalSupply();
        require(bytes(_userText).length <= 30, "String input exceeds limit.");

        Word memory newWord = Word(
            _userText,
            randomNum(361, block.difficulty, supply).toString(),
            randomNum(361, block.timestamp, supply).toString()
        );

        if (msg.sender != owner()) {
            require(msg.value >= 0.005 ether);
        }

        wordsToTokenId[supply + 1] = newWord; //Add word to mapping @tokenId
        _safeMint(msg.sender, supply + 1);
    }

    function randomNum(
        uint256 _mod,
        uint256 _seed,
        uint256 _salt
    ) public view returns (uint256) {
        uint256 num = uint256(
            keccak256(
                abi.encodePacked(block.timestamp, msg.sender, _seed, _salt)
            )
        ) % _mod;
        return num;
    }

    function buildImage(uint256 _tokenId) private view returns (string memory) {
        Word memory currentWord = wordsToTokenId[_tokenId];
        return
            Base64.encode(
                bytes(
                    abi.encodePacked(
                        '<svg xmlns="http://www.w3.org/2000/svg">',
                        '  <rect height="100%" width="100%" y="0" x="0" fill="hsl(', currentWord.bgHue, ',50%,25%)"/>',
                        '  <text y="50%" x="50%" text-anchor="middle" dy=".3em" fill="hsl(', currentWord.textHue, ',100%,80%)">', currentWord.text, "</text>",
                        "</svg>"
                    )
                )
            );
    }

    function buildMetadata(uint256 _tokenId)
        private
        view
        returns (string memory)
    {
        Word memory currentWord = wordsToTokenId[_tokenId];
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"NFTXT:', currentWord.text, '", "description":"', currentWord.text, '", "image": "data:image/svg+xml;base64,', buildImage(_tokenId), '"}'
                            )
                        )
                    )
                )
            );
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return buildMetadata(_tokenId);
    }

    //only owner
    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}
