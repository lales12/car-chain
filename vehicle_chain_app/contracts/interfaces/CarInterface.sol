pragma solidity >=0.5.16;


interface CarInterface {
    event CarAdded(bytes32 indexed carID, uint256 date); // probably we need carOwner's address in the event
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
            uint256
        );
}
