import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:vehicle_chain_app/services/walletmanager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/io.dart';

// object classes (model)

// contract class
class TestContract extends ChangeNotifier {
  // private variables
  Web3Client _client;
  String _abiCode;
  Credentials _credentials;
  EthereumAddress _contractAddress;
  EthereumAddress _userAddress;
  DeployedContract _contract;
  // contract functions
  ContractFunction _verifySigniture;
  ContractFunction _getAddress;

  // public variables
  List<String> contractFunctionsList;
  BlockNum contractDeployedBlockNumber;
  EthereumAddress contractAddress;
  EthereumAddress userAddress;
  bool doneLoading = false;
  // BigInt usersOwnedVehicles;

  TestContract(WalletManager walletManager) {
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
    String abiStringFile = await rootBundle.loadString("abis/Test.json");
    var jsonAbi = jsonDecode(abiStringFile);
    _abiCode = jsonEncode(jsonAbi["abi"]);
    _contractAddress = EthereumAddress.fromHex(jsonAbi["networks"][walletManager.activeNetwork.networkId]["address"]);
    contractAddress = _contractAddress;
    // gettting contractDeployedBlockNumber
    String _deplyTxHash = jsonAbi["networks"][walletManager.activeNetwork.networkId]["transactionHash"];
    TransactionInformation txInfo = await _client.getTransactionByHash(_deplyTxHash);
    contractDeployedBlockNumber = txInfo.blockNumber;
    log('Test: contract address: ' + contractAddress.toString());
  }

  Future<void> _getCredentials(EthPrivateKey privateKey) async {
    _credentials = privateKey;
    _userAddress = await _credentials.extractAddress();
    userAddress = _userAddress;
    log('Test: useraddress from privkey: ' + _userAddress.toString());
    notifyListeners();
  }

  Future<void> _getDeployedContract() async {
    log('Test: start loading abis');
    _contract = DeployedContract(ContractAbi.fromJson(_abiCode, "Test"), _contractAddress);

    // set functions
    _verifySigniture = _contract.function('verifySigniture');
    _getAddress = _contract.function('getAddress');

    log('Test: list of functions:' + _contract.functions.map((e) => e.name).toList().toString());
  }

  Future<String> verifySigniture(Uint8List carIdHash, BigInt v, Uint8List r, Uint8List s) async {
    log('TestContract: verifySigniture ' + carIdHash.toString() + ' ,' + v.toString() + r.toString() + s.toString());
    String res = await _client.sendTransaction(
      _credentials,
      Transaction.callContract(contract: _contract, function: _verifySigniture, maxGas: 6721975, parameters: [carIdHash, v, r, s]),
      fetchChainIdFromNetworkId: true,
    );
    log('TestContract: verifySigniture result' + res);
    return res;
  }

  Future<EthereumAddress> getAddress(Uint8List carIdHash, BigInt v, Uint8List r, Uint8List s) async {
    List listRes = await _client.call(contract: _contract, function: _getAddress, params: [carIdHash, v, r, s]);

    return listRes[0] as EthereumAddress;
  }
}
