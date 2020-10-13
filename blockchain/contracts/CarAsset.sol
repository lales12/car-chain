pragma solidity ^0.6.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract CarAsset is ERC721 {
    mapping(uint256 => address) carMapping;

    constructor () public ERC721('CarAsset', 'car') {}
 
    function mint(
        address to,
        bytes32 carId,
        address carAddress
    ) public  {
        uint256 carIdUint = uint256(carId);
        carMapping[carIdUint] = carAddress;

        _mint(to, carIdUint);
    }

    function burn(uint256 tokenId) public {
        _burn(tokenId);
    }

    function transfer (address from, address to, uint256 tokenId) public {
        transferFrom(from, to, tokenId);
    }

    function getCarAddress(
        uint256 tokenId
    ) public view returns(address) {
        return carMapping[tokenId];
    }
}
