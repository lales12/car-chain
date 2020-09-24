pragma solidity ^0.6.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract CarAsset is ERC721 {
    mapping(uint256 => address) carMapping;

    constructor () public ERC721('CarAsset', 'car') {}

    function mint(
        address to,
        uint256  carId,
        address carAddress
    ) public  {
        carMapping[carId] = carAddress;

        _mint(to, carId);
    }

    function burn(uint256 tokenId) public {
        _burn(tokenId);
    }

    function getCarAddress(
        uint256 tokenId
    ) public view returns(address) {
        return carMapping[tokenId];
    }
}
