import 'dart:async';
import 'dart:convert';

import 'package:carchain/app_config.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/io.dart';

class AddPermisionEvent {
  EthereumAddress contract;
  String method;
  EthereumAddress to;
  AddPermisionEvent({this.contract, this.method, this.to});
}

class RemovePermisionEvent {
  EthereumAddress contract;
  String method;
  EthereumAddress to;
  RemovePermisionEvent({this.contract, this.method, this.to});
}

class PermissionContract extends ChangeNotifier {
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
  EthereumAddress contractAddress;
  bool doneLoading = false;
  AddPermisionEvent addPermisionEvent;
  RemovePermisionEvent removePermisionEvent;

  PermissionContract(String userPrivKey) {
    initiateSetup(userPrivKey);
  }

  Future<void> initiateSetup(String privateKey) async {
    // print(configParams.rpcUrl);
    // print(configParams.wsUrl);
    _client = Web3Client(configParams.rpcUrl, Client(), socketConnector: () {
      return IOWebSocketChannel.connect(configParams.wsUrl).cast<String>();
    });

    await _getAbi();
    await _getCredentials(privateKey);
    await _getDeployedContract();
    doneLoading = true;
    notifyListeners();
  }

  Future<void> _getAbi() async {
    String abiStringFile =
        await rootBundle.loadString("src/abis/Permissions.json");
    var jsonAbi = jsonDecode(abiStringFile);
    _abiCode = jsonEncode(jsonAbi["abi"]);
    _contractAddress =
        EthereumAddress.fromHex(jsonAbi["networks"]["5777"]["address"]);
    // print('permissions contract address');
    // print(_contractAddress);
    contractAddress = _contractAddress;
  }

  Future<void> _getCredentials(String privateKey) async {
    _credentials = await _client.credentialsFromPrivateKey(privateKey);
    _userAddress = await _credentials.extractAddress();
    // print('useraddress from privkey');
    // print(_userAddress);
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
    // public variable
    await _getContractOwner();
    await _subscribeToAddPermisionEvent();
    await _subscribeToremovePermisionEvent();
  }

  Future<void> _subscribeToAddPermisionEvent() async {
    // listen for the Transfer event when it's emitted by the contract above
    _client
        .events(
            FilterOptions.events(contract: _contract, event: _permissionAdded))
        .take(1)
        .listen((event) {
      final decoded = _permissionAdded.decodeResults(event.topics, event.data);

      addPermisionEvent = AddPermisionEvent(
        contract: decoded[0] as EthereumAddress,
        method: decoded[1] as String,
        to: decoded[2] as EthereumAddress,
      );
      notifyListeners();
    });
  }

  Future<void> _subscribeToremovePermisionEvent() async {
    // listen for the Transfer event when it's emitted by the contract above
    _client
        .events(FilterOptions.events(
            contract: _contract, event: _permissionRemoved))
        .take(1)
        .listen((event) {
      final decoded =
          _permissionRemoved.decodeResults(event.topics, event.data);

      removePermisionEvent = RemovePermisionEvent(
        contract: decoded[0] as EthereumAddress,
        method: decoded[1] as String,
        to: decoded[2] as EthereumAddress,
      );
      notifyListeners();
    });
  }

  // functions
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
