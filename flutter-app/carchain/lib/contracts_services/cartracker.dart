import 'dart:convert';

import 'package:carchain/app_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/io.dart';

// object classes
class Car {
  FixedBytes id;
  BigInt creationBlock;
  EthereumAddress ownerID;
  String licensePlate;
  BigInt carType;
  BigInt carState;
  BigInt itvState;
  BigInt lastInspection;
  Car(
      {this.id,
      this.creationBlock,
      this.ownerID,
      this.licensePlate,
      this.carType,
      this.carState,
      this.itvState,
      this.lastInspection});
}

// event classes
class CarAddedEvent {
  FixedBytes carId;
  BigInt date;
  CarAddedEvent({this.carId, this.date});
}

class CarStateUpdatedEvent {
  FixedBytes carId;
  BigInt date;
  CarStateUpdatedEvent({this.carId, this.date});
}

class ITVInspectionEvent {
  FixedBytes carId;
  BigInt date;
  ITVInspectionEvent({this.carId, this.date});
}

class CarTracker extends ChangeNotifier {
  // initialization variables
  String prefKey = 'privKey';
  SharedPreferences prefs;

  // private variables
  Web3Client _client;
  String _abiCode;
  Credentials _credentials;
  EthereumAddress _contractAddress;
  EthereumAddress _userAddress;
  DeployedContract _contract;
  ContractFunction _addCar;
  ContractFunction _updateCarState;
  ContractFunction _updateITV;
  ContractFunction _getCar;
  // events
  ContractEvent _carAddedEvent;
  ContractEvent _carStateUpdatedEvent;
  ContractEvent _iTVInspectionEvent;

  // public variables
  List<ContractFunction> contractFunctionsList; // = List<ContractFunction>();
  BlockNum contractDeployedBlockNumber;
  EthereumAddress contractAddress;
  bool doneLoading = false;

  CarTracker() {
    _initiateSetup();
  }

  // initialize shared preferences
  Future initPrefs() async {
    if (prefs == null) prefs = await SharedPreferences.getInstance();
  }

  Future<void> _initiateSetup() async {
    _client = Web3Client(configParams.rpcUrl, Client(), socketConnector: () {
      return IOWebSocketChannel.connect(configParams.wsUrl).cast<String>();
    });
    await initPrefs();
    String privKey = prefs.getString(prefKey) ?? null;
    if (privKey != null) {
      await _getAbi();
      await _getCredentials(privKey);
      await _getDeployedContract();
      // public variable
      doneLoading = true;
      notifyListeners();
    }
  }

  Future<void> _getAbi() async {
    String abiStringFile =
        await rootBundle.loadString("src/abis/CarTracker.json");
    var jsonAbi = jsonDecode(abiStringFile);
    _abiCode = jsonEncode(jsonAbi["abi"]);
    _contractAddress = EthereumAddress.fromHex(
        jsonAbi["networks"][configParams.networkId]["address"]);
    print('CarTracker contract address' + _contractAddress.toString());
    contractAddress = _contractAddress;
    // gettting contractDeployedBlockNumber
    String _deplyTxHash =
        jsonAbi["networks"][configParams.networkId]["transactionHash"];
    TransactionInformation txInfo =
        await _client.getTransactionByHash(_deplyTxHash);
    contractDeployedBlockNumber = txInfo.blockNumber;
  }

  Future<void> _getCredentials(String privateKey) async {
    _credentials = await _client.credentialsFromPrivateKey(privateKey);
    _userAddress = await _credentials.extractAddress();
    print('CarTracker: useraddress from privkey');
    print(_userAddress);
  }

  Future<void> _getDeployedContract() async {
    _contract = DeployedContract(
        ContractAbi.fromJson(_abiCode, "CarTracker"), _contractAddress);
    // set events
    _carAddedEvent = _contract.event('CarAdded');
    _carStateUpdatedEvent = _contract.event('CarStateUpdated');
    _iTVInspectionEvent = _contract.event('ITVInspection');
    // set functions list
    List<ContractFunction> tempFuncList = List.of(_contract.functions);
    if (tempFuncList != null) {
      tempFuncList.removeAt(0);
    }
    contractFunctionsList = tempFuncList;
    // set functions
    _addCar = _contract.function('addCar');
    _updateCarState = _contract.function('updateCarState');
    _updateITV = _contract.function('updateITV');
    _getCar = _contract.function('getCar');
  }

  // Stream Events
  Stream<List<CarAddedEvent>> get addcarAddedEventListStream {
    print('addcarAddedEventListStream from block: ' +
        contractDeployedBlockNumber.blockNum.toString());

    return _client
        .getLogs(FilterOptions.events(
            contract: _contract,
            event: _carAddedEvent,
            fromBlock: contractDeployedBlockNumber))
        .asStream()
        .map((eventList) {
      return eventList.map((event) {
        final decoded = _carAddedEvent.decodeResults(event.topics, event.data);
        return CarAddedEvent(
            carId: decoded[0] as FixedBytes, date: decoded[1] as BigInt);
      }).toList();
    });
  }

  Stream<List<CarStateUpdatedEvent>> get carStateUpdatedEventListStream {
    print('carStateUpdatedEventListStream from block: ' +
        contractDeployedBlockNumber.blockNum.toString());

    return _client
        .getLogs(FilterOptions.events(
            contract: _contract,
            event: _carStateUpdatedEvent,
            fromBlock: contractDeployedBlockNumber))
        .asStream()
        .map((eventList) {
      return eventList.map((event) {
        final decoded =
            _carStateUpdatedEvent.decodeResults(event.topics, event.data);
        return CarStateUpdatedEvent(
            carId: decoded[0] as FixedBytes, date: decoded[1] as BigInt);
      }).toList();
    });
  }

  Stream<List<ITVInspectionEvent>> get iTVInspectionEventListStream {
    print('iTVInspectionEventListStream from block: ' +
        contractDeployedBlockNumber.blockNum.toString());

    return _client
        .getLogs(FilterOptions.events(
            contract: _contract,
            event: _iTVInspectionEvent,
            fromBlock: contractDeployedBlockNumber))
        .asStream()
        .map((eventList) {
      return eventList.map((event) {
        final decoded =
            _iTVInspectionEvent.decodeResults(event.topics, event.data);
        return ITVInspectionEvent(
            carId: decoded[0] as FixedBytes, date: decoded[1] as BigInt);
      }).toList();
    });
  }

  // callable functions
  Future<String> addCar(
      FixedBytes carID, String licensePlate, int carTypeIndex) async {
    String res = await _client.sendTransaction(
      _credentials,
      Transaction.callContract(
          contract: _contract,
          function: _addCar,
          parameters: [carID, licensePlate, carTypeIndex]),
      fetchChainIdFromNetworkId: true,
    );
    return res;
  }

  Future<String> updateCarState(FixedBytes carID, int carStateIndex) async {
    String res = await _client.sendTransaction(
      _credentials,
      Transaction.callContract(
          contract: _contract,
          function: _updateCarState,
          parameters: [carID, carStateIndex]),
      fetchChainIdFromNetworkId: true,
    );
    return res;
  }

  Future<String> updateITV(FixedBytes carID, int itvStateIndex) async {
    String res = await _client.sendTransaction(
      _credentials,
      Transaction.callContract(
          contract: _contract,
          function: _updateITV,
          parameters: [carID, itvStateIndex]),
      fetchChainIdFromNetworkId: true,
    );
    return res;
  }

  Future<Car> requestAccess(FixedBytes carID) async {
    List haveAccess = await _client
        .call(contract: _contract, function: _getCar, params: [carID]);

    return Car(
        id: haveAccess[0] as FixedBytes,
        creationBlock: haveAccess[1] as BigInt,
        ownerID: haveAccess[2] as EthereumAddress,
        licensePlate: haveAccess[3] as String,
        carType: haveAccess[4] as BigInt,
        carState: haveAccess[5] as BigInt,
        itvState: haveAccess[6] as BigInt,
        lastInspection: haveAccess[7] as BigInt);
  }
}
