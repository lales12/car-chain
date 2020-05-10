pragma solidity <0.6.0;


contract CarManager {
    address public root;

    uint256 ID;

    mapping(address => bool) public brands; // now is dealer ship

    mapping(uint256 => Car) trackedCars;

    mapping(address => bool) auhtorizedShops; // now is mechanic

    mapping(address => bool) public auhtorizedITV;

    // Enums
    enum CarType {Vehicle2W, Vehicle3W, Vehicle, VehicleH, VehicleA, VehicleS} // (!!) W, weel, H, Heavy S, Service A, Agriculture
    enum CarOwnershipType {Factory, Brand, User}
    enum CarState { Shiped, ForSale, ProcessingSale, Sold, ProcessingRgister, Registered} // processingSale ~ reserved
    enum ITV {Initial, Passed, NotPassed, Negative} // NotPassed = car can go mechanic, Negative = car need transport to mechanic
    // end - Enums

    struct Car {
        uint256 ID;
        address ownerID;
        string licensePlate;
        // creation time perhaps needed
        CarType carType;
        // car state
        CarOwnershipType carOwnerType;
        CarState carState;
        // ITV state
        ITV itv;
        // car history = perhaps it need a struct type!!
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

    modifier onlyITV() {
        require(
            auhtorizedITV[msg.sender] == true,
            "Only ITV can perform this action"
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

    function addITV(address ItvID) public onlyRoot {
        auhtorizedITV[ItvID] = true;
    }

    function deleteBrand(address brandID) public onlyRoot {
        brands[brandID] = false;
    }

    function deleteITV(address ItvID) public onlyRoot {
        auhtorizedITV[ItvID] = false;
    }

    function addCar(string memory licensePlate, uint256 _carTypeIndex) public onlyActiveBrand {
        ID = ID + 1; // safe math !!
        trackedCars[ID] = Car({
            ID: ID,
            ownerID: msg.sender,
            licensePlate: licensePlate,
            // creation time perhaps needed
            // setting default enums
            // (!!) CarType can not be updated ??
            carType: CarType(_carTypeIndex),
            carOwnerType: CarOwnershipType.Brand,
            carState: CarState.ForSale,
            itv: ITV.Initial
        });
        emit CarAdded(ID);
    }

    // update car
    // update status
    function updateCarOwenerType(uint256 _ID, uint256 _carOwnershipIndex) public onlyActiveBrand {
        trackedCars[_ID].carOwnerType = CarOwnershipType(_carOwnershipIndex);
    }
    function updateCarState(uint256 _ID, uint256 _carStateIndex) public onlyActiveBrand { // modifier ??
        trackedCars[_ID].carState = CarState(_carStateIndex);
    }
    function updateITV(uint256 _ID, uint256 _itv) public onlyITV {
        trackedCars[_ID].itv = ITV(_itv);
    }
    // transfer, maintenance, ITV

    function getCar(uint256 _ID)
        public
        view
        returns (uint256 carID, address ownerID, string memory licensePlate, uint256 carOwnerType, uint256 carITVstate)
    {
        Car memory car = trackedCars[_ID];
        return (
            carID = car.ID,
            ownerID = car.ownerID,
            licensePlate = car.licensePlate,
            carOwnerType = uint256(car.carOwnerType),
            carITVstate = uint256(car.itv)
        );
    }
}
