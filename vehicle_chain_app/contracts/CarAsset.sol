pragma solidity ^0.6.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract CarAsset is ERC721 {
    constructor () public ERC721('CarAsset', 'car') {}

    function mint(address to, uint256 tokenId) public  {
        _mint(to, tokenId);
    }

    function burn(uint256 tokenId) public {
        _burn(tokenId);
    }
}
