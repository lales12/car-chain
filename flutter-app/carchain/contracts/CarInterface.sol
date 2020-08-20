pragma solidity >=0.5.16;


interface CarInterface {
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

    event CarAdded(bytes32 indexed carID, uint256 date);
    event CarStateUpdated(bytes32 indexed carID, uint256 date);
    event ITVInspection(bytes32 indexed carID, uint256 date);

    function addCar(bytes calldata, string calldata, uint256) external;

    function updateCarState(bytes calldata, uint256) external;

    function updateITV(bytes calldata, uint256) external;

    function getCar(bytes calldata)
        external
        view
        returns (
            bytes32,
            uint256,
            address,
            string memory,
            uint256,
            uint256,
            uint256,
            uint256
        );
}
