pragma solidity ^0.6.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract CarAsset is ERC721 {
    mapping( address => uint256) carMappingAddressToken;
    mapping( uint256 => address) carMappingTokenAddress;


    constructor () public ERC721('CarAsset', 'car') {}
    
    event testEvent(address  testData);

    function mint(
        address to,
        bytes32 carId,
        address carAddress
    ) public  {
        uint256 carIdUint = uint256(carId);

        carMappingAddressToken[carAddress] = carIdUint;
        carMappingTokenAddress[carIdUint] = carAddress;
        _mint(to, carIdUint);
    }

    function burn(uint256 carId) public {
        _burn(carId);
    }

    function transferFromAddress(
        address from,
        address to,
        address carAddress
    ) public {
        uint256 carId = carMappingAddressToken[carAddress];

        transferFrom(from, to, carId);
    }

    function getCarAddress(
        uint256 tokenId
    ) public view returns(address) {
        return carMappingTokenAddress[tokenId];
    }

    function getCarToken(
        address carAddress
    ) public view returns(uint256) {
        return carMappingAddressToken[carAddress];
    }
}
