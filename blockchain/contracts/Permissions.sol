pragma solidity >=0.5.16;


contract Permissions {
    address public owner;

    /*
     * create a mapping(contract => mapping(method => mapping(address => bool)) permissions;
     * this will be reponsible for managing all permissions.
     */
    mapping(address => mapping(bytes32 => mapping(address => bool))) public permissions;

    event PermissionAdded(address _contract, bytes32 _method, address _to);
    event PermissionRemoved(address _contract, bytes32 _method, address _to);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function addPermission(address _contract, bytes memory _method, address _to)
        public
        onlyOwner
    {
        bytes32 methodHash = keccak256(_method);
        permissions[_contract][methodHash][_to] = true;
        emit PermissionAdded(_contract, methodHash, _to);
    }

    function removePermission(
        address _contract,
        bytes memory _method,
        address _to
    ) public onlyOwner {
        bytes32 methodHash = keccak256(_method);
        permissions[_contract][methodHash][_to] = false;
        emit PermissionRemoved(_contract, methodHash, _to);
    }
}
