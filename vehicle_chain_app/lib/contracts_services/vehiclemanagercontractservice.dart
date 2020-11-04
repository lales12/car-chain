import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:vehicle_chain_app/services/walletmanager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/io.dart';

// object classes (model)
class CarGot {
  EthereumAddress address;
  String licensePlate;
  BigInt carType;
  BigInt carState;

  CarGot({this.address, this.licensePlate, this.carType, this.carState});
}

// event classes (model)
class CarAddedEvent {
  EthereumAddress carAddress;
  int blockNumber;
  String transactionHash;
  CarAddedEvent({this.carAddress, this.blockNumber, this.transactionHash});
}

class CarStateUpdatedEvent {
  EthereumAddress carAddress;
  int blockNumber;
  String transactionHash;
  CarStateUpdatedEvent({this.carAddress, this.blockNumber, this.transactionHash});
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
  ContractFunction _createCar;
  // ContractFunction _createCarRaw;
  ContractFunction _deliverCar;
  ContractFunction _sellCar;
  ContractFunction _registerCar;
  ContractFunction _getCar;

  // events
  ContractEvent _carAddedEvent;
  ContractEvent _carStateUpdatedEvent;

  // public variables
  List<String> contractFunctionsList;
  BlockNum contractDeployedBlockNumber;
  EthereumAddress contractAddress;
  EthereumAddress userAddress;
  bool doneLoading = false;

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
    doneLoading = true;
    notifyListeners();
  }

  Future<void> _getAbi(WalletManager walletManager) async {
    String abiStringFile = await rootBundle.loadString("abis/CarManager.json");
    var jsonAbi = jsonDecode(abiStringFile);
    _abiCode = jsonEncode(jsonAbi["abi"]);
    _contractAddress = EthereumAddress.fromHex(jsonAbi["networks"][walletManager.activeNetwork.networkId]["address"]);
    // _contractAddress = EthereumAddress.fromHex('0x1DD65062Db2DEf96bcC765573dd8B36E97273417');
    contractAddress = _contractAddress;
    // gettting contractDeployedBlockNumber
    String _deplyTxHash = jsonAbi["networks"][walletManager.activeNetwork.networkId]["transactionHash"];
    TransactionInformation txInfo = await _client.getTransactionByHash(_deplyTxHash);
    contractDeployedBlockNumber = txInfo.blockNumber;
    log('VehicleManager: contract address: ' + contractAddress.toString());
  }

  Future<void> _getCredentials(EthPrivateKey privateKey) async {
    _credentials = privateKey;
    _userAddress = await _credentials.extractAddress();
    userAddress = _userAddress;
    log('VehicleManager: useraddress from privkey: ' + _userAddress.toString());
    notifyListeners();
  }

  Future<void> _getDeployedContract() async {
    log('VehicleManager: start loading abis');
    _contract = DeployedContract(ContractAbi.fromJson(_abiCode, "CarManager"), _contractAddress);
    // set events
    _carAddedEvent = _contract.event('CarAdded');
    _carStateUpdatedEvent = _contract.event('CarStateUpdated');

    // set functions
    _createCar = _contract.function('createCar');
    _deliverCar = _contract.function('deliverCar');
    _sellCar = _contract.function('sellCar');
    _registerCar = _contract.function('registerCar');
    _getCar = _contract.function('getCar');

    log('VehicleManager: list of functions:' + _contract.functions.map((e) => e.name).toList().toString());
    // set functions list
    const String CREATE_CAR_METHOD = "createCar(bytes32,bytes,uint256)";
    const String CREATE_CAR_RAW_METHOD = "createCarRaw(bytes32,uint8, bytes32, bytes32,uint256)";
    const String DELIVER_CAR_METHOD = "deliverCar(address)";
    const String SELL_CAR_METHOD = "sellCar(address)";
    const String REGISTER_CAR_METHOD = "registerCar()";
    const String UPDATE_CAR_METHOD = "updateCarState(bytes,uint256)";

    contractFunctionsList = [CREATE_CAR_METHOD, CREATE_CAR_RAW_METHOD, DELIVER_CAR_METHOD, SELL_CAR_METHOD, REGISTER_CAR_METHOD, UPDATE_CAR_METHOD];
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
                CarAddedEvent(carAddress: decoded[0] as EthereumAddress, blockNumber: event.blockNum, transactionHash: event.transactionHash),
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
                CarStateUpdatedEvent(carAddress: decoded[0] as EthereumAddress, blockNumber: event.blockNum, transactionHash: event.transactionHash),
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
  Future<TransactionReceipt> createCar(Uint8List carIdHash, Uint8List signiture, BigInt carTypeIndex) async {
    log('VehicleManagerContract: addcar ' + carIdHash.toString() + ' ,' + signiture.toString() + ' ,' + carTypeIndex.toString());
    String res = await _client.sendTransaction(
      _credentials,
      Transaction.callContract(contract: _contract, function: _createCar, maxGas: 6721975, parameters: [carIdHash, signiture, carTypeIndex]),
      fetchChainIdFromNetworkId: true,
    );
    log('VehicleManagerContract: addCar result' + res);
    TransactionReceipt receipt = await _client.addedBlocks().asyncMap((_) => _client.getTransactionReceipt(res)).firstWhere((receipt) => receipt != null);
    return receipt;
  }

  Future<TransactionReceipt> deliverCar(EthereumAddress carAddress) async {
    log('VehicleManagerContract: deliverCar ' + carAddress.toString());
    String res = await _client.sendTransaction(
      _credentials,
      Transaction.callContract(contract: _contract, function: _deliverCar, maxGas: 6721975, parameters: [carAddress]),
      fetchChainIdFromNetworkId: true,
    );
    log('VehicleManagerContract: deliverCar result' + res);
    TransactionReceipt receipt = await _client.addedBlocks().asyncMap((_) => _client.getTransactionReceipt(res)).firstWhere((receipt) => receipt != null);
    return receipt;
  }

  Future<TransactionReceipt> sellCar(EthereumAddress carAddress) async {
    log('VehicleManagerContract: sellCar ' + carAddress.toString());
    String res = await _client.sendTransaction(
      _credentials,
      Transaction.callContract(contract: _contract, function: _sellCar, maxGas: 6721975, parameters: [carAddress]),
      fetchChainIdFromNetworkId: true,
    );
    log('VehicleManagerContract: sellCar result' + res);
    TransactionReceipt receipt = await _client.addedBlocks().asyncMap((_) => _client.getTransactionReceipt(res)).firstWhere((receipt) => receipt != null);
    return receipt;
  }

  Future<TransactionReceipt> registerCar(EthereumAddress carAddress, String licensePlate) async {
    log('VehicleManagerContract: registerCar ' + carAddress.toString() + ' , ' + licensePlate);
    String res = await _client.sendTransaction(
      _credentials,
      Transaction.callContract(contract: _contract, function: _registerCar, maxGas: 6721975, parameters: [carAddress, licensePlate]),
      fetchChainIdFromNetworkId: true,
    );
    log('VehicleManagerContract: registerCar result' + res);
    TransactionReceipt receipt = await _client.addedBlocks().asyncMap((_) => _client.getTransactionReceipt(res)).firstWhere((receipt) => receipt != null);
    return receipt;
  }

  Future<CarGot> getCar(EthereumAddress carAddress) async {
    log('recieved address: ' + carAddress.toString());
    List<dynamic> ret = await _client.call(contract: _contract, function: _getCar, params: [carAddress]);

    return CarGot(
      address: ret[0] as EthereumAddress,
      licensePlate: ret[1] as String,
      carType: ret[2] as BigInt,
      carState: ret[3] as BigInt,
    );
  }
}
