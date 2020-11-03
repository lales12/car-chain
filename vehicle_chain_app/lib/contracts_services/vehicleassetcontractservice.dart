import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:vehicle_chain_app/services/walletmanager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/io.dart';

class OwnedVehicle {
  int index;
  BigInt id;
  EthereumAddress address;
  OwnedVehicle({this.index, this.id, this.address});
}

// events
// event classes (model)
class TransferEvent {
  EthereumAddress from;
  EthereumAddress to;
  BigInt tokenId;
  TransferEvent({this.from, this.to, this.tokenId});
}

class ApprovalEvent {
  EthereumAddress owner;
  EthereumAddress approved;
  UintType tokenId;
  ApprovalEvent({this.owner, this.approved, this.tokenId});
}

class ApprovalForAllEvent {
  EthereumAddress owner;
  EthereumAddress theOperator;
  bool approved;
  ApprovalForAllEvent({this.owner, this.theOperator, this.approved});
}

class VehicleAssetContractService extends ChangeNotifier {
  // private variables
  Web3Client _client;
  String _abiCode;
  Credentials _credentials;
  EthereumAddress _contractAddress;
  EthereumAddress _userAddress;
  DeployedContract _contract;
  WalletManager _walletManager;
  BigInt _usersTotalNumberOwnedVehicles;
  List<OwnedVehicle> _listOfOwnedVehicles;

  // contract functions
  List<ContractFunction> contractFunctionsList;
  ContractFunction _balanceOf;
  ContractFunction _tokenOfOwnerByIndex;
  ContractFunction _transferFrom;
  ContractFunction _getCarAddress;

  // events
  ContractEvent _transferEvent;

  // public variables
  BlockNum contractDeployedBlockNumber;
  EthereumAddress contractAddress;
  EthereumAddress userAddress;
  bool doneLoading = false;

  VehicleAssetContractService(WalletManager walletManager) {
    _walletManager = walletManager;
    _initiateSetup();
  }

  Future<void> _initiateSetup() async {
    doneLoading = false;
    notifyListeners();
    _client = Web3Client(_walletManager.activeNetwork.rpcUrl, Client(), socketConnector: () {
      return IOWebSocketChannel.connect(_walletManager.activeNetwork.wsUrl).cast<String>();
    });
    await _getAbi();
    await _getCredentials(_walletManager.getAppUserWallet.privkey);
    await _getDeployedContract();
    await updateUserOwnedVehicles();
    // public variable
    doneLoading = true;
    notifyListeners();
  }

  Future<void> _getAbi() async {
    String abiStringFile = await rootBundle.loadString("abis/CarAsset.json");
    var jsonAbi = jsonDecode(abiStringFile);
    _abiCode = jsonEncode(jsonAbi["abi"]);
    _contractAddress = EthereumAddress.fromHex(jsonAbi["networks"][_walletManager.activeNetwork.networkId]["address"]);
    // _contractAddress = EthereumAddress.fromHex('0x9B34b92D5C38BCa9E9cE788984Df3321Ad555d78');
    contractAddress = _contractAddress;
    // gettting contractDeployedBlockNumber
    String _deplyTxHash = jsonAbi["networks"][_walletManager.activeNetwork.networkId]["transactionHash"];
    TransactionInformation txInfo = await _client.getTransactionByHash(_deplyTxHash);
    contractDeployedBlockNumber = txInfo.blockNumber;
  }

  Future<void> _getCredentials(EthPrivateKey privateKey) async {
    _credentials = privateKey;
    _userAddress = await _credentials.extractAddress();
    userAddress = _userAddress;
    log('VehicleAssetContractService: useraddress from privkey: ' + _userAddress.toString());
    notifyListeners();
  }

  Future<void> _getDeployedContract() async {
    _contract = DeployedContract(ContractAbi.fromJson(_abiCode, "CarAsset"), _contractAddress);
    // set events
    _transferEvent = _contract.event('Transfer');
    // set functions
    _balanceOf = _contract.function('balanceOf');
    _tokenOfOwnerByIndex = _contract.function('tokenOfOwnerByIndex');
    _transferFrom = _contract.function('transferFrom');
    _getCarAddress = _contract.function('getCarAddress');

    contractFunctionsList = _contract.functions;
    log('VehicleAssetContractService: List of functions ' + contractFunctionsList.map<String>((f) => f.name).toList().toString());
  }

  // Contract Calls
  Future<String> transferFrom(EthereumAddress to, BigInt tokenId) async {
    log('VehicleAssetContractService: transferFrom ' + tokenId.toString() + ' ,from ' + _userAddress.toString() + ' ,to' + to.toString());
    String res = await _client.sendTransaction(
      _credentials,
      Transaction.callContract(contract: _contract, function: _transferFrom, maxGas: 6721975, parameters: [_userAddress, to, tokenId]),
      fetchChainIdFromNetworkId: true,
    );
    log('VehicleAssetContractService: transferFrom result' + res);
    return res;
  }

  Future<BigInt> getTockenIdByIndex(BigInt index) async {
    List<dynamic> ret = await _client.call(contract: _contract, function: _tokenOfOwnerByIndex, params: [_userAddress, index]);
    return ret[0] as BigInt;
  }

  Future<EthereumAddress> getVehicleAddressById(BigInt id) async {
    List<dynamic> ret = await _client.call(contract: _contract, function: _getCarAddress, params: [id]);
    return ret[0] as EthereumAddress;
  }

  Future<void> updateUserOwnedVehicles() async {
    List<dynamic> balance = await _client.call(contract: _contract, function: _balanceOf, params: [_userAddress]);

    _usersTotalNumberOwnedVehicles = balance[0] as BigInt;

    log('VehicleAssetContractService: useraddress ' + _userAddress.toString());
    log('VehicleAssetContractService: usersOwnedVehicles ' + _usersTotalNumberOwnedVehicles.toString());

    _listOfOwnedVehicles = new List<OwnedVehicle>();
    for (var i = 0; i < _usersTotalNumberOwnedVehicles.toInt(); i++) {
      BigInt id = await getTockenIdByIndex(BigInt.from(i));
      EthereumAddress carAddress = await getVehicleAddressById(id);
      OwnedVehicle currentVehicle = new OwnedVehicle(index: i, id: id, address: carAddress);
      log('VehicleAssetContractService: usersCurrentVehicles: ' +
          currentVehicle.index.toString() +
          ', ' +
          currentVehicle.address.toString() +
          ', ' +
          currentVehicle.id.toString());
      _listOfOwnedVehicles.add(currentVehicle);
    }

    notifyListeners();
  }

  BigInt get usersTotalNumberOwnedVehicles => _usersTotalNumberOwnedVehicles;
  List<OwnedVehicle> get usersListOwnedVehicles => _listOfOwnedVehicles;

  // Streams
  Stream<List<TransferEvent>> get transferEventListStream {
    print('iTVInspectionEventListStream from block: ' + contractDeployedBlockNumber.blockNum.toString());

    StreamController<List<TransferEvent>> controller;
    List<TransferEvent> temp = new List<TransferEvent>();
    void start() {
      // first get historical events
      _client
          .getLogs(
        // filter,
        FilterOptions.events(contract: _contract, event: _transferEvent, fromBlock: contractDeployedBlockNumber),
      )
          .then(
        (List<FilterEvent> eventsList) {
          eventsList.forEach(
            (FilterEvent event) {
              final decoded = _transferEvent.decodeResults(event.topics, event.data);
              temp.add(
                TransferEvent(from: decoded[0] as EthereumAddress, to: decoded[1] as EthereumAddress, tokenId: decoded[2] as BigInt),
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

    controller = StreamController<List<TransferEvent>>(
      onListen: start,
      onPause: stop,
      onResume: start,
      onCancel: stop,
    );

    return controller.stream;
  }
}
