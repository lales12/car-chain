pragma solidity >=0.5.16;

import { ECDSA } from  "./libraries/ECDSA.sol";

import "./interfaces/CarInterface.sol";
import "./Authorizer.sol";
import "./BaseManager.sol";

contract CarManager is BaseManager {
    using ECDSA for bytes32;

    string public constant CREATE_CAR_METHOD = "create(bytes32,bytes,uint256)";
    string public constant DELIVER_CAR_METHOD = "deliverCar(address)";
    string public constant SELL_CAR_METHOD = "sellCar(address)";
    string public constant REGISTER_CAR_METHOD = "registerCar()";
    string public constant UPDATE_CAR_METHOD = "updateCarState(bytes,uint256)";
    /*
     * At the moment this state adds nothing to the contract - it doesn't give the users relevant information,
     * and it doesn't modify functions. We must update this to include relevant information or remove it.
     */
    enum CarState {
        SHIPPED,
        FOR_SALE,
        SOLD,
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
    event ITVInspection(uint256 indexed carID);
    event CarStateUpdated(
        address indexed carID,
        uint256 carState
    );

    constructor(
        address authorizerContractAddress,
        address carTokenContractAddress
    ) public
        BaseManager(authorizerContractAddress, carTokenContractAddress)
    {}

    function createCar(
        bytes32 carIdHash,
        bytes calldata signature,
        uint256 carTypeIndex
    ) external onlyAuthorized(CREATE_CAR_METHOD, msg.sender) {
        address carAddress = carIdHash.recover(signature);

        carToken.mint(
            msg.sender,
            carIdHash,
            carAddress
        );

        trackedCars[carAddress] = Car({
            licensePlate: '',
            carType: CarType(carTypeIndex),
            carState: CarState.SHIPPED
        });

         _updateCarState(
            carAddress,
            uint256(CarState.SHIPPED)
        );

        emit CarAdded(carAddress);
    }

    function deliverCar(
        address carAddress
    )
        public
        onlyAuthorized(DELIVER_CAR_METHOD, msg.sender)
    {
        require(
            CarState.SHIPPED == trackedCars[carAddress].carState,
            "This car is not shipped"
        );

        _updateCarState(
            carAddress,
            uint256(CarState.FOR_SALE)
        );
    }

    function sellCar(
        address carAddress
    )
        public
        onlyAuthorized(SELL_CAR_METHOD, msg.sender)
        onlyAssetOwner(carAddress, msg.sender)
    {
        require(
            CarState.FOR_SALE == trackedCars[carAddress].carState,
            "This car is not for sale"
        );

        _updateCarState(
            carAddress,
            uint256(CarState.SOLD)
        );
        // This is an attemp to do in the same call the token transfer and update the status
        // (bool success, bytes memory result) = carTokenAddress.delegatecall(
        //     abi.encodeWithSignature(
        //         'transferFrom(address,address,uint256)',
        //         msg.sender,
        //         to,
        //         carAddress
        //     )
        // );
        // require(success, "Error transfering token");
        // carToken.transferFrom(msg.sender, to, carId);
        // END_COMMENT
    }

    function registerCar(
        address carAddress,
        string memory licensePlate
    )
        public
        onlyAuthorized(REGISTER_CAR_METHOD, msg.sender)
        // onlyAssetOwner(carAddress, msg.sender)
    {
        require(
            CarState.SOLD == trackedCars[carAddress].carState,
            "This car is not sold"
        );

        trackedCars[carAddress].licensePlate = licensePlate;

        _updateCarState(
            carAddress,
            uint256(CarState.REGISTERED)
        );
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

    function _updateCarState(
        address carAddress,
        uint256 carStateIndex
    )
        internal
    {
        trackedCars[carAddress].carState = CarState(carStateIndex);

        emit CarStateUpdated(carAddress, carStateIndex);
    }
}
