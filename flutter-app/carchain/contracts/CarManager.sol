pragma solidity >=0.5.16;

import "./interfaces/CarInterface.sol";
import "./Authorizer.sol";
import "./BaseManager.sol";


contract CarManager is BaseManager {
    string constant ADD_CAR_METHOD = "addCar(string,string,uint256)";
    string constant UPDATE_CAR_METHOD = "updateCarState(uint256,uint256)";
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

    struct Car {
        string licensePlate;
        CarType carType;
        CarState carState;
    }

    mapping(uint256 => Car) trackedCars;
    uint256[] registeredCars;

    event CarAdded(uint256 indexed carID); // probably we need carOwner's address in the event
    event CarStateUpdated(uint256 indexed carID);
    event ITVInspection(uint256 indexed carID);

    constructor(
        address authorizerContractAddress,
        address carTokenContractAddress
    ) public
        BaseManager(authorizerContractAddress, carTokenContractAddress)
    {}

    function addCar(
        string calldata carId,
        string calldata licensePlate,
        uint256 carTypeIndex
    ) external onlyAuthorized(ADD_CAR_METHOD, msg.sender) {
        uint256 id = uint256(keccak256(abi.encode(carId)));

        carToken.mint(msg.sender, id);

        trackedCars[id] = Car({
            licensePlate: licensePlate,
            carType: CarType(carTypeIndex),
            carState: CarState.FOR_SALE
        });

        emit CarAdded(id);
    }

    function updateCarState(uint256 id, uint256 carStateIndex)
        external
        onlyAuthorized(UPDATE_CAR_METHOD, msg.sender)
    {
        trackedCars[id].carState = CarState(carStateIndex);

        emit CarStateUpdated(id);
    }

    function getCar(uint256 carId)
        external
        view
        returns (
            uint256 ID,
            string memory licensePlate,
            uint256 carType,
            uint256 carState
        )
    {
        Car memory car = trackedCars[carId];

        return (
            carId,
            car.licensePlate,
            uint256(car.carType),
            uint256(car.carState)
        );
    }
}
