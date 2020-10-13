pragma solidity >=0.5.16;

import { ECDSA } from  "./libraries/ECDSA.sol";

import "./interfaces/CarInterface.sol";
import "./Authorizer.sol";
import "./BaseManager.sol";



contract CarManager is BaseManager {
    using ECDSA for bytes32;

    string constant ADD_CAR_METHOD = "addCar(bytes,string,uint256)";
    string constant UPDATE_CAR_METHOD = "updateCarState(bytes,uint256)";
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

    mapping(address => Car) trackedCars;
    uint256[] registeredCars;

    event CarAdded(address indexed carAddress); // probably we need carOwner's address in the event
    event CarStateUpdated(address indexed carID);
    event ITVInspection(uint256 indexed carID);

    constructor(
        address authorizerContractAddress,
        address carTokenContractAddress
    ) public
        BaseManager(authorizerContractAddress, carTokenContractAddress)
    {}

    function addCar(
        bytes32 carIdHash,
        bytes calldata signature,
        string calldata licensePlate,
        uint256 carTypeIndex
    ) external onlyAuthorized(ADD_CAR_METHOD, msg.sender) {
        address carAddress = carIdHash.recover(signature);

        carToken.mint(
            msg.sender,
            carIdHash,
            carAddress
        );

        trackedCars[carAddress] = Car({
            licensePlate: licensePlate,
            carType: CarType(carTypeIndex),
            carState: CarState.FOR_SALE
        });

        emit CarAdded(carAddress);
    }

    function updateCarState(
        address carAddress,
        uint256 carStateIndex
    )
        external
        onlyAuthorized(UPDATE_CAR_METHOD, msg.sender)
    {
        trackedCars[carAddress].carState = CarState(carStateIndex);

        emit CarStateUpdated(carAddress);
    }

    function getCar(address carAddress)
        external
        view
        returns (
            address id,
            string memory licensePlate,
            uint256 carType,
            uint256 carState
        )
    {
        Car memory car = trackedCars[carAddress];

        return (
            carAddress,
            car.licensePlate,
            uint256(car.carType),
            uint256(car.carState)
        );
    }
}
