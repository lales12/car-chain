pragma solidity ^0.6.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract CarAsset is ERC721 {
    address _owner;

    mapping( address => uint256) carMappingAddressToken;
    mapping( uint256 => address) carMappingTokenAddress;
    mapping( address => bool) authorizedManagers;

    constructor () public ERC721('CarAsset', 'car') {
        _owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(_owner == msg.sender, "Only owner can perform this action");
        _;
    }

    modifier onlyManager() {
        require(authorizedManagers[msg.sender], "Only authorized managers can perform this acction");
        _;
    }

    function addManager(
        address managerAddress
    ) 
        public 
        onlyOwner() 
    {
        authorizedManagers[managerAddress] = true;
    }

    function removeManager(
        address managerAddress
    ) 
        public 
        onlyOwner() 
    {
        authorizedManagers[managerAddress] = false;
    }

    function mint(
        address to,
        bytes32 carId,
        address carAddress
    ) 
        public
        onlyManager()
    {
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
