pragma solidity >=0.4.21 <0.7.0;

import "./interfaces/CarInterface.sol";
import "./BaseManager.sol";


contract ITVManager  is BaseManager {
    string constant UPDATE_METHOD = 'updateITV(uint256,uint256)';

    enum ITVState {PASSED, NOT_PASSED, NEGATIVE}

    struct ITVInspection {
        ITVState state;
        uint256 date;
    }

    mapping(uint256 => ITVInspection[]) ITVs;

    event ITVInspectionEvent(uint256 carID, ITVState state);

    constructor(
        address authorizerContractAddress,
        address carAssetContractAddress
    ) BaseManager(authorizerContractAddress, carAssetContractAddress) public {}

    function updateITV(uint256 carId, ITVState itvStateIndex) 
        public
        onlyAuthorized (UPDATE_METHOD, msg.sender)
    {
        ITVs[carId].push(
            ITVInspection(itvStateIndex, now)
        );
        
        emit ITVInspectionEvent(carId, itvStateIndex);
    }

}
