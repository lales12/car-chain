pragma solidity ^0.6.2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


interface ICarAsset is IERC721 {
    function mint(
        address to,
        uint256 carId,
        address carAddress
    ) external;

    function burn(uint256 tokenId) external;

    function getCarAddress(
        uint256 tokenId
    ) external view returns(address);
}
