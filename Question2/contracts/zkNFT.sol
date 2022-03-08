// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./SparseMerkleTree.sol";

contract zkNFT is ERC721, ERC721Enumerable, Ownable, SparseMerkleTree {
    using Strings for uint256;

    constructor() ERC721("zkNFT", "ZKNFT") {}

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function mint(
        address to, 
        uint256 tokenId)
    public onlyOwner {
        _safeMint(to, tokenId);
        string memory uri = tokenURI(tokenId);
        bytes32 leafHash = keccak256(abi.encodePacked(msg.sender, to, uint8(tokenId), uri));
        _updateLeaf(leafHash, uint8(tokenId));
        batchMerkleUpdate();
    }

    function batchMerkleUpdate() public onlyOwner returns(bytes32) {
        require(pendingIndex.length > 0, "No pending leaves");
        return _batchMerkleUpdate();
    }

    function getSvg(uint256 tokenId) private pure returns (string memory) {
        string memory svg;
        svg = '<svg height="210" width="500"><polygon points="100,10 40,198 190,78 10,78 160,198" style="fill:lime;stroke:purple;stroke-width:5;fill-rule:nonzero;"/>';
        return string(abi.encodePacked(svg, tokenId, "</svg>"));
    } 

    function tokenURI(uint256 tokenId) override(ERC721) public pure returns (string memory) {
        string memory json = Base64.encode(
            bytes(string(
                abi.encodePacked(
                    '{"name": zkNFT-"', tokenId , '", ',
                    '"description": "Hello zero knowledge!",',
                    '"image": "', getSvg(tokenId), '"}'
                )
            ))
        );
        return string(abi.encodePacked('data:application/json;base64,', json));
    }    
}