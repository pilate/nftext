// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./Base64.sol";


contract NFTText is ERC721Enumerable, Ownable {
    using Strings for uint256;

    mapping(uint256 => Word) public wordsToTokenId;
    uint private fee = 0.005 ether;

    struct Word {
        string text;
        string bgHue;
        string textHue;
    }

    constructor() ERC721("NFTText", "NTXT") {
        mint('first');
    }

    function randomHue(
        uint8 _salt
    ) public view returns (string memory) {
        return (uint256(
            keccak256(
                abi.encodePacked(
                    blockhash(block.number), 
                    "_",
                    totalSupply(), 
                    "_",
                    _salt)
            )
        ) % 361).toString();
    }

    function mint(string memory _userText, address _destination) public payable {
        require(bytes(_userText).length <= 30, "Text is too long");
        uint256 supply = totalSupply();

        Word memory newWord = Word(
            _userText,
            randomHue(1),
            randomHue(2)
        );

        if (msg.sender != owner()) {
            require(msg.value >= fee, string(abi.encodePacked("Requires payment of ", fee.toString(), " wei")));
        }

        wordsToTokenId[supply + 1] = newWord;
        _safeMint(_destination, supply + 1);
    }

    function mint(string memory _userText) public payable {
        mint(_userText, msg.sender);
    }

    function buildImage(uint256 _tokenId) private view returns (bytes memory) {
        Word memory currentWord = wordsToTokenId[_tokenId];
        return
            Base64.encode(
                bytes.concat(
                    '<svg xmlns="http://www.w3.org/2000/svg">'
                    '<rect height="100%" width="100%" y="0" x="0" fill="hsl(', bytes(currentWord.bgHue), ',50%,25%)"/>'
                    '<text y="50%" x="50%" text-anchor="middle" dy=".3em" fill="hsl(', bytes(currentWord.textHue), ',100%,80%)">', bytes(currentWord.text), "</text>"
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
                            "{"
                                '"name":"', bytes(currentWord.text), '",'
                                '"description":"\'', bytes(currentWord.text), '\' as NFTText by Pilate",'
                                '"image":"data:image/svg+xml;base64,', buildImage(_tokenId), '"'
                            "}"
                        )
                    )
                )
            );
    }

    function getFee() public view returns (uint) {
        return fee;
    }

    function setFee(uint _newFee) public onlyOwner {
        fee = _newFee;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}
