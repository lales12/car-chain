pragma solidity >=0.5.16;

import "./Authorizer.sol";

contract BaseManager {
    Authorizer private auth;
    address public owner;

    modifier onlyAuthorized(string memory _method, address _account) {
        bool hasAccess = auth.requestAccess(address(this), _method, _account);
        require(hasAccess, "Unauthorized");
        _;
    }

    constructor(address authorizer) public {
        owner = msg.sender;
        auth = Authorizer(authorizer);
    }
}
