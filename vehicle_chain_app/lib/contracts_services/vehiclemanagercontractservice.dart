import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:vehicle_chain_app/services/walletmanager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/io.dart';

// object classes (model)
class Car {
  BigInt id;
  String licensePlate;
  BigInt carType;
  BigInt carState;

  Car({this.id, this.licensePlate, this.carType, this.carState});
}

// event classes (model)
class CarAddedEvent {
  BigInt carId;
  CarAddedEvent({this.carId});
}

class CarStateUpdatedEvent {
  BigInt carId;
  CarStateUpdatedEvent({this.carId});
}

// contract class
class CarManager extends ChangeNotifier {
  // private variables
  Web3Client _client;
  String _abiCode;
  Credentials _credentials;
  EthereumAddress _contractAddress;
  EthereumAddress _userAddress;
  DeployedContract _contract;
  // contract functions
  ContractFunction _addCar;
  ContractFunction _updateCarState;
  ContractFunction _getCar;
  // functions from ERC721
  // ContractFunction _balanceOf;
  // events
  ContractEvent _carAddedEvent;
  ContractEvent _carStateUpdatedEvent;

  // public variables
  List<ContractFunction> contractFunctionsList;
  BlockNum contractDeployedBlockNumber;
  EthereumAddress contractAddress;
  EthereumAddress userAddress;
  bool doneLoading = false;
  // BigInt usersOwnedVehicles;

  CarManager(WalletManager walletManager) {
    _initiateSetup(walletManager);
  }

  Future<void> _initiateSetup(WalletManager walletManager) async {
    doneLoading = false;
    notifyListeners();
    _client = Web3Client(walletManager.activeNetwork.rpcUrl, Client(), socketConnector: () {
      return IOWebSocketChannel.connect(walletManager.activeNetwork.wsUrl).cast<String>();
    });
    await _getAbi(walletManager);
    await _getCredentials(walletManager.getAppUserWallet.privkey);
    await _getDeployedContract();
    // await _userOwnedVehicles();
    // public variable
    doneLoading = true;
    notifyListeners();
  }

  Future<void> _getAbi(WalletManager walletManager) async {
    String abiStringFile = await rootBundle.loadString("abis/CarManager.json");
    var jsonAbi = jsonDecode(abiStringFile);
    _abiCode = jsonEncode(jsonAbi["abi"]);
    _contractAddress = EthereumAddress.fromHex(jsonAbi["networks"][walletManager.activeNetwork.networkId]["address"]);
    contractAddress = _contractAddress;
    // gettting contractDeployedBlockNumber
    String _deplyTxHash = jsonAbi["networks"][walletManager.activeNetwork.networkId]["transactionHash"];
    TransactionInformation txInfo = await _client.getTransactionByHash(_deplyTxHash);
    contractDeployedBlockNumber = txInfo.blockNumber;
  }

  Future<void> _getCredentials(EthPrivateKey privateKey) async {
    _credentials = privateKey;
    _userAddress = await _credentials.extractAddress();
    userAddress = _userAddress;
    log('CarManager: useraddress from privkey: ' + _userAddress.toString());
    notifyListeners();
  }

  Future<void> _getDeployedContract() async {
    _contract = DeployedContract(ContractAbi.fromJson(_abiCode, "CarManager"), _contractAddress);
    // set events
    _carAddedEvent = _contract.event('CarAdded');
    _carStateUpdatedEvent = _contract.event('CarStateUpdated');
    // _iTVInspectionEvent = _contract.event('ITVInspection');

    // set functions
    _addCar = _contract.function('addCar');
    _updateCarState = _contract.function('updateCarState');
    // _updateITV = _contract.function('updateITV');
    _getCar = _contract.function('getCar');

    log('VehicleManager: list of functions:' + _contract.functions.map((e) => e.name).toList().toString());
    // set functions list
    contractFunctionsList = [_addCar, _updateCarState];
  }

  // Stream Events
  Stream<List<CarAddedEvent>> get addcarAddedEventListStream {
    print('addcarAddedEventListStream from block: ' + contractDeployedBlockNumber.blockNum.toString());
    StreamController<List<CarAddedEvent>> controller;
    List<CarAddedEvent> temp = new List<CarAddedEvent>();
    void start() {
      // first get historical events
      _client
          .getLogs(
        // filter,
        FilterOptions.events(contract: _contract, event: _carAddedEvent, fromBlock: contractDeployedBlockNumber),
      )
          .then(
        (List<FilterEvent> eventsList) {
          eventsList.forEach(
            (FilterEvent event) {
              final decoded = _carAddedEvent.decodeResults(event.topics, event.data);
              temp.add(
                CarAddedEvent(
                  carId: decoded[0] as BigInt,
                ),
              );
            },
          );
          controller.add(temp);
        },
      ); // end of then
    }

    void stop() {
      controller.close();
    }

    controller = StreamController<List<CarAddedEvent>>(
      onListen: start,
      onPause: stop,
      onResume: start,
      onCancel: stop,
    );

    return controller.stream;
  }

  Stream<List<CarStateUpdatedEvent>> get carStateUpdatedEventListStream {
    print('carStateUpdatedEventListStream from block: ' + contractDeployedBlockNumber.blockNum.toString());

    StreamController<List<CarStateUpdatedEvent>> controller;
    List<CarStateUpdatedEvent> temp = new List<CarStateUpdatedEvent>();
    void start() {
      // first get historical events
      _client
          .getLogs(
        // filter,
        FilterOptions.events(contract: _contract, event: _carStateUpdatedEvent, fromBlock: contractDeployedBlockNumber),
      )
          .then(
        (List<FilterEvent> eventsList) {
          eventsList.forEach(
            (FilterEvent event) {
              final decoded = _carAddedEvent.decodeResults(event.topics, event.data);
              temp.add(
                CarStateUpdatedEvent(
                  carId: decoded[0] as BigInt,
                ),
              );
            },
          );
          controller.add(temp);
        },
      ); // end of then
    }

    void stop() {
      controller.close();
    }

    controller = StreamController<List<CarStateUpdatedEvent>>(
      onListen: start,
      onPause: stop,
      onResume: start,
      onCancel: stop,
    );

    return controller.stream;
  }

  // Contract Calls
  Future<String> addCar(String vehicleVIN, String licensePlate, BigInt carTypeIndex) async {
    log('VehicleManagerContract: addcar ' + vehicleVIN + ' ,' + licensePlate);
    String res = await _client.sendTransaction(
      _credentials,
      Transaction.callContract(contract: _contract, function: _addCar, maxGas: 6721975, parameters: [vehicleVIN, licensePlate, carTypeIndex]),
      fetchChainIdFromNetworkId: true,
    );
    log('VehicleManagerContract: addCar result' + res);
    return res;
  }

  Future<String> updateCarState(BigInt carID, BigInt carStateIndex) async {
    String res = await _client.sendTransaction(
      _credentials,
      Transaction.callContract(contract: _contract, function: _updateCarState, parameters: [carID, carStateIndex]),
      fetchChainIdFromNetworkId: true,
    );
    return res;
  }

  Future<Car> getCar(BigInt tockenId) async {
    List<dynamic> ret = await _client.call(contract: _contract, function: _getCar, params: [tockenId]);

    return Car(
      id: ret[0] as BigInt,
      licensePlate: ret[1] as String,
      carType: ret[2] as BigInt,
      carState: ret[3] as BigInt,
    );
  }
}