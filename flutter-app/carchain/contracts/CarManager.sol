pragma solidity ^0.6.0;

import "./BaseManager.sol";
import "./interfaces/CarInterface.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract CarManager is BaseManager, ERC721 {
    // erc721 related
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    //
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
        uint256 vehicleId;
        string licensePlate;
        CarType carType;
        CarState carState;
    }

    mapping(uint256 => Car) trackedCars;
    uint256[] registeredCars;

    event CarAdded(uint256 indexed carID); // probably we need carOwner's address in the event
    event CarStateUpdated(uint256 indexed carID);
    event ITVInspection(uint256 indexed carID);

    constructor(address authorizerContractAddress)
        public
        BaseManager(authorizerContractAddress) ERC721("VehicleTocken", "VCLE")
    {}

    function _generateVehicleTocken(address vehicleOwner, string memory tokenURI)
        internal
        returns (uint256)
    {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(vehicleOwner, newItemId);
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }

    function addCar(
        // string calldata carId,
        string calldata licensePlate,
        uint256 carTypeIndex
    ) external onlyAuthorized(ADD_CAR_METHOD, msg.sender) {
        // uint256 id = uint256(keccak256(abi.encode(carId)));

        uint256 tockenId = _generateVehicleTocken(msg.sender,licensePlate);

        trackedCars[tockenId] = Car({
            vehicleId: tockenId,
            licensePlate: licensePlate,
            carType: CarType(carTypeIndex),
            carState: CarState.FOR_SALE
        });

        emit CarAdded(tockenId);
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
