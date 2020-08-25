import 'dart:convert';

import 'package:carchain/app_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/io.dart';

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
    // _contractAddress = EthereumAddress.fromHex(
    //     jsonAbi["networks"][configParams.networkId]["address"]);
    // print('permissions contract address');
    // print(_contractAddress);
    contractAddress = _contractAddress;
    // gettting contractDeployedBlockNumber
    // String _deplyTxHash =
    //     jsonAbi["networks"][configParams.networkId]["transactionHash"];
    // TransactionInformation txInfo =
    //     await _client.getTransactionByHash(_deplyTxHash);
    // contractDeployedBlockNumber = txInfo.blockNumber;
  }

  Future<void> _getCredentials(String privateKey) async {
    _credentials = await _client.credentialsFromPrivateKey(privateKey);
    _userAddress = await _credentials.extractAddress();
    // print('useraddress from privkey');
    // print(_userAddress);
  }

  Future<void> _getDeployedContract() async {
    _contract = DeployedContract(
        ContractAbi.fromJson(_abiCode, "CarTracker"), _contractAddress);
    // set functions list
    contractFunctionsList = _contract.functions;
    // functions
    _addCar = _contract.function('addCar');
    _updateCarState = _contract.function('updateCarState');
    _updateITV = _contract.function('updateITV');
    _getCar = _contract.function('getCar');
  }

  // callable functions
  Future<String> addCar(
      String carID, String licensePlate, int carTypeIndex) async {
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
}
