pragma solidity >=0.5.16;

import "./Authorizer.sol";

import "./interfaces/ICarAsset.sol";

contract BaseManager {
    Authorizer private auth;
    ICarAsset public carToken;

    address public owner;

    modifier onlyAuthorized(
        string memory _method,
        address _account
    ) {
        bool hasAccess = auth.requestAccess(address(this), _method, _account);
        require(hasAccess, "Unauthorized");
        _;
    }

    modifier onlyAssetOwner(
        address _carAddress,
        address _account
    ) {
        uint256 carId = carToken.getCarToken(_carAddress);

        require(_account == carToken.ownerOf(carId), "Only the owner can perfom this action");
        _;
    }

    constructor(
        address authorizer,
        address carTokenAddress
    ) public {
        owner = msg.sender;
        auth = Authorizer(authorizer);
        carToken = ICarAsset(carTokenAddress);
    }
}
