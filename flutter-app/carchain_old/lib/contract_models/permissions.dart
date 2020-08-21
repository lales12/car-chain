import 'dart:convert';

import 'package:carchain/app_config.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/io.dart';

class Permissions extends ChangeNotifier {
  Web3Client _client;
  String _abiCode;
  Credentials _credentials;
  EthereumAddress _contractAddress;
  EthereumAddress _userAddress;
  DeployedContract _contract;
  ContractFunction _owner;
  ContractFunction _addPermission;
  ContractFunction _removePermission;
  ContractFunction _requestAccess;
  ContractEvent _permissionAdded;
  ContractEvent _permissionRemoved;
  // public variables
  EthereumAddress contractOwner;

  Permissions(String userPrivKey, AppConfigParams params) {
    initiateSetup(userPrivKey, params);
  }

  Future<void> initiateSetup(String privateKey, AppConfigParams params) async {
    _client = Web3Client(params.rpc, Client(), socketConnector: () {
      return IOWebSocketChannel.connect(params.ws).cast<String>();
    });

    await _getAbi();
    await _getCredentials(privateKey);
    await _getDeployedContract();
  }

  Future<void> _getAbi() async {
    String abiStringFile =
        await rootBundle.loadString("src/abis/Permissions.json");
    var jsonAbi = jsonDecode(abiStringFile);
    _abiCode = jsonEncode(jsonAbi["abi"]);
    _contractAddress =
        EthereumAddress.fromHex(jsonAbi["networks"]["5777"]["address"]);
    print('permissions contract address');
    print(_contractAddress);
  }

  Future<void> _getCredentials(String privateKey) async {
    _credentials = await _client.credentialsFromPrivateKey(privateKey);
    _userAddress = await _credentials.extractAddress();
    print('useraddress from privkey');
    print(_userAddress);
  }

  Future<void> _getDeployedContract() async {
    _contract = DeployedContract(
        ContractAbi.fromJson(_abiCode, "Permissions"), _contractAddress);

    // functions
    _owner = _contract.function('owner');
    _addPermission = _contract.function('addPermission');
    _removePermission = _contract.function('removePermission');
    _requestAccess = _contract.function('requestAccess');
    // events
    _permissionAdded = _contract.event("PermissionAdded");
    _permissionRemoved = _contract.event("PermissionRemoved");
    // public variable setter
    await _getContractOwner();
  }

  Future<void> _getContractOwner() async {
    List response =
        await _client.call(contract: _contract, function: _owner, params: []);
    contractOwner = response[0];
    notifyListeners();
  }

  Future<void> addPermission(EthereumAddress contractAddress,
      String functionName, EthereumAddress toAddress) async {
    await _client.call(
        contract: _contract,
        function: _addPermission,
        params: [contractAddress, functionName, toAddress]);
  }

  Future<void> removePermission(EthereumAddress contractAddress,
      String functionName, EthereumAddress toAddress) async {
    await _client.call(
        contract: _contract,
        function: _removePermission,
        params: [contractAddress, functionName, toAddress]);
  }

  Future<bool> requestAccess(EthereumAddress contractAddress,
      String functionName, EthereumAddress toAddress) async {
    List haveAccess = await _client.call(
        contract: _contract,
        function: _requestAccess,
        params: [contractAddress, functionName, toAddress]);

    return haveAccess[0];
  }
}
