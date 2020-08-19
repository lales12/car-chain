pragma solidity >=0.6.0;


contract CarManager {
    address public root;

    mapping(address => bool) public brands; // now is dealership

    mapping(bytes32 => Car) trackedCars;

    mapping(address => bool) public auhtorizedShops; // now is mechanic

    mapping(address => bool) public ITVAuthorities;

    /*
     * Permit type or car type is related to the ITV - inspection intervals are determined by this variable
     * We must look into the `legal` types of vehicles and permits
     */
    enum CarType {
        TWO_WHEEL,
        THREE_WHEEL,
        FOUR_WHEEL,
        HEAVY,
        AGRICULTURE,
        SERVICE
    }

    /*
     * At the moment this state adds nothing to the contract - it doesn't give the users relevant information,
     * and it doesn't modify functions. We must update this to include relevant information or remove it.
     */
    enum CarState {
        SHIPPED,
        FOR_SALE,
        PROCESSING_SALE,
        SOLD,
        PROCESSING_REGISTER,
        REGISTERED
    }

    enum ITVState {PASSED, NOT_PASSED, NEGATIVE}

    // What should the initial value of lastInspection be? How does the ITV manage this?
    struct ITV {
        ITVState state;
        uint256 lastInspection;
    }

    struct Car {
        bytes32 ID;
        uint256 creationBlock;
        address ownerID;
        string licensePlate;
        CarType _type;
        CarState _state;
        ITV itv;
    }

    event CarAdded(bytes32 carID, uint256 date);
    event ITVInspection(bytes32 carID, uint256 date);

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
            ITVAuthorities[msg.sender] == true,
            "Only ITV can perform this action"
        );
        _;
    }

    modifier onlyOwner(bytes memory carID) {
        bytes32 _carID = keccak256(carID);
        require(
            msg.sender == trackedCars[_carID].ownerID,
            "Only car owner can perform this action"
        );
        _;
    }

    constructor() public {
        root = msg.sender;
    }

    function addBrand(address brandID) public onlyRoot {
        brands[brandID] = true;
    }

    function deleteBrand(address brandID) public onlyRoot {
        brands[brandID] = false;
    }

    function addITV(address ItvID) public onlyRoot {
        ITVAuthorities[ItvID] = true;
    }

    function deleteITV(address ItvID) public onlyRoot {
        ITVAuthorities[ItvID] = false;
    }

    function addCar(
        bytes memory carID,
        string memory licensePlate,
        uint256 carTypeIndex
    ) public onlyActiveBrand {
        uint256 creationBlock = block.number;
        bytes32 _ID = keccak256(carID);
        trackedCars[_ID] = Car({
            ID: _ID,
            creationBlock: creationBlock,
            ownerID: msg.sender,
            licensePlate: licensePlate,
            _type: CarType(carTypeIndex),
            _state: CarState.FOR_SALE,
            itv: ITV({state: ITVState.PASSED, lastInspection: 0})
        });
        emit CarAdded(_ID, creationBlock);
    }

    function updateCarState(bytes memory ID, uint256 carStateIndex)
        public
        onlyActiveBrand
    {
        bytes32 _ID = keccak256(ID);
        trackedCars[_ID]._state = CarState(carStateIndex);
    }

    function updateITV(bytes memory ID, uint256 itvStateIndex) public onlyITV {
        bytes32 _ID = keccak256(ID);
        Car storage car = trackedCars[_ID];
        uint256 date = now;
        car.itv.state = ITVState(itvStateIndex);
        car.itv.lastInspection = date;
        emit ITVInspection(_ID, date);
    }

    function getCar(bytes memory carID)
        public
        view
        returns (
            bytes32 ID,
            uint256 creationBlock,
            address ownerID,
            string memory licensePlate,
            uint256 permitType,
            uint256 itvState,
            uint256 lastInspection
        )
    {
        bytes32 _carID = keccak256(carID);
        Car memory car = trackedCars[_carID];
        return (
            ID = car.ID,
            creationBlock = car.creationBlock,
            ownerID = car.ownerID,
            licensePlate = car.licensePlate,
            permitType = uint256(car._type),
            itvState = uint256(car.itv.state),
            lastInspection = car.itv.lastInspection
        );
    }
}
