pragma solidity <0.6.0;


contract CarManager {
    address public root;

    uint256 ID;

    mapping(address => bool) public brands;

    mapping(uint256 => Car) trackedCars;

    mapping(address => bool) auhtorizedShops;

    struct Car {
        uint256 ID;
        address ownerID;
        string licensePlate;
    }

    event CarAdded(uint256 ID);

    modifier onlyRoot() {
        require(msg.sender == root, "Only root can manage brands");
        _;
    }

    modifier onlyActiveBrand() {
        require(
            brands[msg.sender] == true,
            "Only active brand can add a new car"
        );
        _;
    }

    modifier onlyOwner(uint256 carID, string memory errorMsg) {
        require(msg.sender == trackedCars[carID].ownerID, errorMsg);
        _;
    }

    constructor() public {
        root = msg.sender;
        ID = 0;
    }

    function addBrand(address brandID) public onlyRoot {
        brands[brandID] = true;
    }

    function deleteBrand(address brandID) public onlyRoot {
        brands[brandID] = false;
    }

    function addCar(string memory licensePlate) public onlyActiveBrand {
        ID = ID + 1;

        trackedCars[ID] = Car({
            ID: ID,
            ownerID: msg.sender,
            licensePlate: licensePlate
        });

        emit CarAdded(ID);
    }

    function getCar(uint256 _ID)
        public
        view
        returns (uint256 carID, address ownerID, string memory licensePlate)
    {
        Car memory car = trackedCars[_ID];
        return (
            carID = car.ID,
            ownerID = car.ownerID,
            licensePlate = car.licensePlate
        );
    }
}
