import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:vehicle_chain_app/services/walletmanager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/credentials.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/io.dart';

class ITVInspection {
  BigInt state;
  BigInt date;
  ITVInspection({this.state, this.date});
}

class ITVInspectionEvent {
  BigInt carId;
  BigInt state;
  ITVInspectionEvent({this.carId, this.state});
}

class ItvManager extends ChangeNotifier {
  // private variables
  Web3Client _client;
  String _abiCode;
  Credentials _credentials;
  EthereumAddress _contractAddress;
  EthereumAddress _userAddress;
  DeployedContract _contract;

  // contract functions
  ContractFunction _updateITV;
  List<String> contractFunctionsList;

  // events
  ContractEvent _iTVInspectionEvent;

  // public variables
  BlockNum contractDeployedBlockNumber;
  EthereumAddress contractAddress;
  EthereumAddress userAddress;
  bool doneLoading = false;

  ItvManager(WalletManager walletManager) {
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
    // public variable
    doneLoading = true;
    notifyListeners();
  }

  Future<void> _getAbi(WalletManager walletManager) async {
    String abiStringFile = await rootBundle.loadString("abis/ITVManager.json");
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
    log('ITVManager: useraddress from privkey: ' + _userAddress.toString());
    notifyListeners();
  }

  Future<void> _getDeployedContract() async {
    _contract = DeployedContract(ContractAbi.fromJson(_abiCode, "ITVManager"), _contractAddress);
    // set events
    _iTVInspectionEvent = _contract.event('ITVInspectionEvent');
    // set functions
    _updateITV = _contract.function('updateITV');

    const String UPDATE_METHOD = 'updateITV(uint256,uint256)';

    contractFunctionsList = [
      UPDATE_METHOD,
    ];
    // contractFunctionsList = _contract.functions;
    // log('ItvManager: List of functions ' + contractFunctionsList.map<String>((f) => f.name).toList().toString());
  }

  // Streams
  Stream<List<ITVInspectionEvent>> get iTVInspectionEventListStream {
    print('iTVInspectionEventListStream from block: ' + contractDeployedBlockNumber.blockNum.toString());

    StreamController<List<ITVInspectionEvent>> controller;
    List<ITVInspectionEvent> temp = new List<ITVInspectionEvent>();
    void start() {
      // first get historical events
      _client
          .getLogs(
        // filter,
        FilterOptions.events(contract: _contract, event: _iTVInspectionEvent, fromBlock: contractDeployedBlockNumber),
      )
          .then(
        (List<FilterEvent> eventsList) {
          eventsList.forEach(
            (FilterEvent event) {
              final decoded = _iTVInspectionEvent.decodeResults(event.topics, event.data);
              temp.add(
                ITVInspectionEvent(
                  carId: decoded[0] as BigInt,
                  state: decoded[1] as BigInt,
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

    controller = StreamController<List<ITVInspectionEvent>>(
      onListen: start,
      onPause: stop,
      onResume: start,
      onCancel: stop,
    );

    return controller.stream;
  }

  // Contract Calls
  Future<TransactionReceipt> updateITV(BigInt vehicleId, BigInt itvStateIndex) async {
    String res = await _client.sendTransaction(
      _credentials,
      Transaction.callContract(contract: _contract, function: _updateITV, maxGas: 6721975, parameters: [vehicleId, itvStateIndex]),
      fetchChainIdFromNetworkId: true,
    );
    TransactionReceipt receipt = await _client.addedBlocks().asyncMap((_) => _client.getTransactionReceipt(res)).firstWhere((receipt) => receipt != null);
    return receipt;
  }
}
