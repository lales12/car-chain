pragma solidity ^0.6.2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


interface ICarAsset is IERC721 {
    function mint(address to, uint256 tokenId) external;

    function burn(uint256 tokenId) external;
}
