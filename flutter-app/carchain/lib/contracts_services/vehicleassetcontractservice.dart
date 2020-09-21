import 'dart:convert';
import 'dart:developer';

import 'package:carchain/services/walletmanager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/io.dart';

// events
// event classes (model)
class Transfer {
  EthereumAddress from;
  EthereumAddress to;
  UintType tokenId;
  Transfer({this.from, this.to, this.tokenId});
}

class Approval {
  EthereumAddress owner;
  EthereumAddress approved;
  UintType tokenId;
  Approval({this.owner, this.approved, this.tokenId});
}

class ApprovalForAll {
  EthereumAddress owner;
  EthereumAddress theOperator;
  bool approved;
  ApprovalForAll({this.owner, this.theOperator, this.approved});
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
  BigInt _usersOwnedVehicles;

  // contract functions
  List<ContractFunction> contractFunctionsList;
  ContractFunction _balanceOf;
  ContractFunction _tokenOfOwnerByIndex;

  // events

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
    await _getCredentials(_walletManager.appUserWallet.privkey);
    await _getDeployedContract();
    await _userOwnedVehicles();
    // public variable
    doneLoading = true;
    notifyListeners();
  }

  Future<void> _getAbi() async {
    String abiStringFile = await rootBundle.loadString("abis/CarAsset.json");
    var jsonAbi = jsonDecode(abiStringFile);
    _abiCode = jsonEncode(jsonAbi["abi"]);
    _contractAddress = EthereumAddress.fromHex(jsonAbi["networks"][_walletManager.activeNetwork.networkId]["address"]);
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
    // set functions
    _balanceOf = _contract.function('balanceOf');
    _tokenOfOwnerByIndex = _contract.function('tokenOfOwnerByIndex');

    contractFunctionsList = _contract.functions;
    log('VehicleAssetContractService: List of functions ' + contractFunctionsList.map<String>((f) => f.name).toList().toString());
  }

  Future<void> _userOwnedVehicles() async {
    List<dynamic> balance = await _client.call(contract: _contract, function: _balanceOf, params: [_userAddress]);

    _usersOwnedVehicles = balance[0] as BigInt;
    log('VehicleAssetContractService: usersOwnedVehicles ' + _usersOwnedVehicles.toString());
    // notifyListeners();
  }

  BigInt get usersOwnedVehicles => _usersOwnedVehicles;

  Future<BigInt> getTockenIdByIndex(BigInt index) async {
    List<dynamic> ret = await _client.call(contract: _contract, function: _tokenOfOwnerByIndex, params: [_userAddress, index]);
    return ret[0] as BigInt;
  }
}
