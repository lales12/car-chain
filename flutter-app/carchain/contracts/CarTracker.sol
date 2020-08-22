pragma solidity >=0.5.16;

import "./Permissions.sol";
import "./CarInterface.sol";


contract CarTracker is CarInterface {
    Permissions private auth;

    mapping(bytes32 => Car) trackedCars;

    modifier onlyAuthorized(string memory _method, address _account) {
        bool hasAccess = auth.requestAccess(address(this), _method, _account);
        require(hasAccess, "Unauthorized");
        _;
    }

    constructor(address authorizerContractAddress) public {
        auth = Permissions(authorizerContractAddress);
    }

    function addCar(
        bytes calldata carID,
        string calldata licensePlate,
        uint256 carTypeIndex
    ) external onlyAuthorized("addCar(bytes,string,uint256)", msg.sender) {
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

    function updateCarState(bytes calldata ID, uint256 carStateIndex)
        external
        onlyAuthorized("updateCarState(bytes,uint256)", msg.sender)
    {
        bytes32 _ID = keccak256(ID);
        trackedCars[_ID]._state = CarState(carStateIndex);
        emit CarStateUpdated(_ID, now);
    }

    function updateITV(bytes calldata ID, uint256 itvStateIndex)
        external
        onlyAuthorized("updateITV(bytes,uint256)", msg.sender)
    {
        bytes32 _ID = keccak256(ID);
        Car storage car = trackedCars[_ID];
        uint256 date = now;
        car.itv.state = ITVState(itvStateIndex);
        car.itv.lastInspection = date;
        emit ITVInspection(_ID, date);
    }

    function getCar(bytes calldata carID)
        external
        view
        returns (
            bytes32 ID,
            uint256 creationBlock,
            address ownerID,
            string memory licensePlate,
            uint256 carType,
            uint256 carState,
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
            carType = uint256(car._type),
            carState = uint256(car._state),
            itvState = uint256(car.itv.state),
            lastInspection = car.itv.lastInspection
        );
    }
}
