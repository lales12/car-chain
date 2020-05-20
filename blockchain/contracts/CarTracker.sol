pragma solidity >=0.5.16;


contract CarTracker {
    mapping(bytes32 => Car) trackedCars;

    enum CarType {
        TWO_WHEEL,
        THREE_WHEEL,
        FOUR_WHEEL,
        HEAVY,
        AGRICULTURE,
        SERVICE
    }

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
