pragma solidity >=0.4.21 <0.7.0;

import "./interfaces/CarInterface.sol";
import "./BaseManager.sol";
import { ECDSA } from  "./libraries/ECDSA.sol";


contract ITVManager  is BaseManager {
    using ECDSA for bytes32;

    string constant UPDATE_METHOD = 'updateITV(uint256,uint256)';

    enum ITVState {PASSED, NOT_PASSED, NEGATIVE}

    struct ITVInspection {
        ITVState state;
        uint256 date;
    }

    mapping(address => ITVInspection[]) ITVs;

    event ITVInspectionEvent(address carAddress, ITVState state);

    constructor(
        address authorizerContractAddress,
        address carAssetContractAddress
    ) BaseManager(authorizerContractAddress, carAssetContractAddress) public {}

    function updateITV(
        bytes32 carIdHash,
        bytes memory signature,
        ITVState itvStateIndex
    ) 
        public
        onlyAuthorized (UPDATE_METHOD, msg.sender)
    {
        address carAddress = carIdHash.recover(signature);

        require(carAddress != address(0), "car address not found.");

        ITVs[carAddress].push(
            ITVInspection(itvStateIndex, now)
        );
        
        emit ITVInspectionEvent(carAddress, itvStateIndex);
    }

    function getITVState(
        address carAddress
    )
        public 
        view
        returns(ITVState state, uint256 date)
    {
        uint256 itvLength = ITVs[carAddress].length;

        require(itvLength > 0, "This car don't have inspection");
        
        state = ITVs[carAddress][itvLength].state;
        date = ITVs[carAddress][itvLength].date;
        
    } 

}
