pragma solidity >=0.5.16;


contract Permissions {
    address public owner;

    /*
     * create a mapping(contract => mapping(method => mapping(address => bool)) permissions;
     * this will be reponsible for managing all permissions.
     */

    mapping(address => mapping(bytes32 => mapping(address => bool))) public permissions;

    event PermissionAdded(
        address indexed _contract,
        string _method,
        address _to
    );

    event PermissionRemoved(
        address indexed _contract,
        string _method,
        address _to
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can manage permissions");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function addPermission(
        address _contract,
        string memory _method,
        address _to
    ) public onlyOwner {
        bytes32 methodHash = keccak256(abi.encodePacked(_method));
        permissions[_contract][methodHash][_to] = true;
        emit PermissionAdded(_contract, _method, _to);
    }

    function removePermission(
        address _contract,
        string memory _method,
        address _to
    ) public onlyOwner {
        bytes32 methodHash = keccak256(abi.encodePacked(_method));
        permissions[_contract][methodHash][_to] = false;
        emit PermissionRemoved(_contract, _method, _to);
    }

    function requestAccess(
        // shouldn't be named hasAccess ??
        address _contract,
        string memory _method,
        address _to // this could be message.sender
    ) public view returns (bool) {
        bytes32 methodHash = keccak256(abi.encodePacked(_method));
        return permissions[_contract][methodHash][_to];
    }

    // we could have a requestAccess payable so we make money when somebody want access to somthing
}
