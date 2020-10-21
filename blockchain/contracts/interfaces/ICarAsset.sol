pragma solidity ^0.6.2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


interface ICarAsset is IERC721 {
    function mint(
        address to,
        bytes32 carId,
        address carAddress
    ) external;

    function burn(uint256 tokenId) external;

    function transferFromAddress(
        address from,
        address to,
        address carAddress
    ) external;

    function getCarAddress(
        uint256 tokenId
    ) external view returns(address);

       function getCarToken(
        address carAddress
    ) external view returns(uint256);
}
