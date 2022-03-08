//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

contract SparseMerkleTree {
    uint8 constant DEPTH = 8;
    uint256 constant BUFFER_LENGTH = 1;

    mapping(uint8 => mapping(uint8 => bytes32)) public tree;
    uint8[] public pendingIndex;
    
    function pop(uint8[] storage array) internal returns (uint8){
        uint8 item = array[array.length-1];
        array.pop();
        return item;
    }

    function bitmap(uint256 index) internal pure returns (uint8) {
        uint8 bytePos = (uint8(BUFFER_LENGTH) - 1) - (uint8(index) / 8);
        return bytePos + 1 << (uint8(index) % 8);
    }

    function _updateLeaf(bytes32 leafHash, uint8 index) internal{
        tree[uint8(DEPTH-1)][index] = leafHash;
        pendingIndex.push(index);
    }

    function _batchMerkleUpdate() internal returns(bytes32) {
        for(uint i=pendingIndex.length; i > 0 ; i--) {
            uint8 currentIndex = pop(pendingIndex);
            for(uint8 j=DEPTH-1; j>0; j--) {
                uint8 siblingIndex = currentIndex % 2 == 0 ? currentIndex + 1 : currentIndex -1;
                if (siblingIndex > currentIndex) {
                    tree[j-1][currentIndex/2] = keccak256(abi.encodePacked(tree[j][currentIndex], tree[j][siblingIndex]));
                } else {
                    tree[j-1][currentIndex/2] = keccak256(abi.encodePacked(tree[j][siblingIndex], tree[j][currentIndex]));
                }
                currentIndex /= 2;
            }
        }
        return tree[0][0];
    } 

    function getMerkleProof(uint8 _index) public view returns(bytes memory proof) {
        uint8 proofBits = 0;
        bytes32[] memory proofHash;
        uint8 siblingIndex;
        bytes32 siblingHash;

        for (uint8 level=0; level < DEPTH; level++) {
            siblingIndex = (_index % 2) == 0 ? _index + 1 : _index - 1;
            _index = _index / 2;

            siblingHash = tree[level][siblingIndex];
            if (siblingHash != 0) {
                proofHash[proofHash.length] = siblingHash;
                proofBits += bitmap(level);
            } 
        }

        bytes memory encoded = '';
        uint len = proofHash.length;
        for (uint i = 0; i < len; i++) {
            encoded = bytes.concat(
                encoded,
                abi.encodePacked(proofHash[i])
            );
        }

        proof = abi.encodePacked(proofBits, encoded);
        return proof;
    }

    function checkMembership(
        bytes32 leaf,
        bytes32 root,
        uint8 index,
        bytes memory proof) public pure returns (bool)
    {
        bytes32 computedHash = getRoot(leaf, index, proof);
        return (computedHash == root);
    }

    function getRoot(bytes32 leaf, uint8 index, bytes memory proof) public pure returns (bytes32) {
        require((proof.length - 8) % 32 == 0 && proof.length <= 2056);
        bytes32 proofElement;
        bytes32 computedHash = leaf;
        uint16 p = 8;
        uint8 proofBits;
        assembly {proofBits := div(mload(add(proof, 32)), exp(256, 24))}

        for (uint d = 0; d < DEPTH; d++ ) {
            if (proofBits % 2 == 0) {
                proofElement = 0;
            } else {
                p += 32;
                require(proof.length >= p);
                assembly { proofElement := mload(add(proof, p)) }
            }
            if (index % 2 == 0) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
            proofBits = proofBits / 2; 
            index = index / 2;
        }
        return computedHash;
    }
}