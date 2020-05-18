pragma solidity >=0.5.16;


contract CarManager {
    address public root;

    mapping(address => bool) public brands; // now is dealership

    mapping(string => Car) trackedCars;

    mapping(address => bool) public auhtorizedShops; // now is mechanic

    mapping(address => bool) public ITVAuthorities;

    /*
     * Permit type or car type is related to the ITV - inspection intervals are determined by this variable
     * We must look into the `legal` types of vehicles and permits
     */
    enum PermitType {
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

    /*
     * What is the ITV INITIAL state? Are there any other states?
     * Again, this needs to include relevant, precise information.
     */
    enum ITVState {INTITIAL, PASSED, NOT_PASSED, NEGATIVE}

    // What should the initial value of lastInspection be? How does the ITV manage this?
    struct ITV {
        ITVState state;
        uint256 lastInspection;
    }

    struct Car {
        uint256 creationDate;
        address ownerID;
        string licensePlate;
        PermitType permitType;
        CarState state;
        ITV itv;
        // history: all maintenance events
    }

    event CarAdded(string licensePlate, uint256 date);
    event ITVInspection(string licensePlate, uint256 date);

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

    modifier onlyOwner(string memory licensePlate) {
        require(
            msg.sender == trackedCars[licensePlate].ownerID,
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

    function addCar(string memory licensePlate, uint256 permitTypeIndex)
        public
        onlyActiveBrand
    {
        uint256 creationDate = block.timestamp;
        trackedCars[licensePlate] = Car({
            creationDate: creationDate,
            ownerID: msg.sender,
            licensePlate: licensePlate,
            permitType: PermitType(permitTypeIndex),
            state: CarState.FOR_SALE,
            itv: ITV({state: ITVState.INTITIAL, lastInspection: 0})
        });
        emit CarAdded(licensePlate, creationDate);
    }

    function updateCarState(string memory licensePlate, uint256 carStateIndex)
        public
        onlyActiveBrand
    {
        trackedCars[licensePlate].state = CarState(carStateIndex);
    }

    function updateITV(string memory licensePlate, uint256 itvStateIndex)
        public
        onlyITV
    {
        Car storage car = trackedCars[licensePlate];
        uint256 date = block.timestamp;
        car.itv.state = ITVState(itvStateIndex);
        car.itv.lastInspection = date;
        emit ITVInspection(licensePlate, date);
    }

    function getCar(string memory _licensePlate)
        public
        view
        returns (
            uint256 creationDate,
            address ownerID,
            string memory licensePlate,
            uint256 permitType,
            uint256 itvState,
            uint256 lastInspection
        )
    {
        Car memory car = trackedCars[_licensePlate];
        return (
            creationDate = car.creationDate,
            ownerID = car.ownerID,
            licensePlate = car.licensePlate,
            permitType = uint256(car.permitType),
            itvState = uint256(car.itv.state),
            lastInspection = car.itv.lastInspection
        );
    }
}
