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
        require(bytes(_userText).length <= 30, "String input exceeds limit.");
        uint256 supply = totalSupply();

        Word memory newWord = Word(
            _userText,
            randomHue(block.difficulty, supply).toString(),
            randomHue(block.timestamp, supply).toString()
        );

        if (msg.sender != owner()) {
            require(msg.value >= 0.005 ether);
        }

        wordsToTokenId[supply + 1] = newWord;
        _safeMint(msg.sender, supply + 1);
    }

    function randomHue(
        uint256 _seed,
        uint256 _salt
    ) public view returns (uint256) {
        return uint256(
            keccak256(
                abi.encodePacked(block.timestamp, msg.sender, _seed, _salt)
            )
        ) % 361;
    }

    function buildImage(uint256 _tokenId) private view returns (bytes memory) {
        Word memory currentWord = wordsToTokenId[_tokenId];
        return
            Base64.encode(
                bytes.concat(
                    '<svg xmlns="http://www.w3.org/2000/svg">'
                    '  <rect height="100%" width="100%" y="0" x="0" fill="hsl(', bytes(currentWord.bgHue), ',50%,25%)"/>'
                    '  <text y="50%" x="50%" text-anchor="middle" dy=".3em" fill="hsl(', bytes(currentWord.textHue), ',100%,80%)">', bytes(currentWord.text), "</text>"
                    "</svg>"
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

        Word memory currentWord = wordsToTokenId[_tokenId];
        return
            string(
                bytes.concat(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes.concat(
                            '{"name":"NFTXT:', bytes(currentWord.text), '", "description":"', bytes(currentWord.text), '", "image": "data:image/svg+xml;base64,', buildImage(_tokenId), '"}'
                        )
                    )
                )
            );
    }

    //only owner
    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}
