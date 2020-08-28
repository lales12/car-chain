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
  BlockNum contractDeployedBlockNumber;
  EthereumAddress contractOwner;
  EthereumAddress contractAddress;
  bool doneLoading = false;

  PermissionContract(String userPrivKey) {
    _initiateSetup(userPrivKey);
  }

  Future<void> _initiateSetup(String privateKey) async {
    // print(configParams.rpcUrl);
    // print(configParams.wsUrl);
    _client = Web3Client(configParams.rpcUrl, Client(), socketConnector: () {
      return IOWebSocketChannel.connect(configParams.wsUrl).cast<String>();
    });

    await _getAbi();
    await _getCredentials(privateKey);
    await _getDeployedContract();
    // public variable
    await _getContractOwner();
    doneLoading = true;
    notifyListeners();
  }

  Future<void> _getAbi() async {
    String abiStringFile =
        await rootBundle.loadString("src/abis/Permissions.json");
    var jsonAbi = jsonDecode(abiStringFile);
    _abiCode = jsonEncode(jsonAbi["abi"]);
    _contractAddress = EthereumAddress.fromHex(
        jsonAbi["networks"][configParams.networkId]["address"]);
    // print('permissions contract address');
    // print(_contractAddress);
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
  }

  // functions
  Future<void> _getContractOwner() async {
    List response =
        await _client.call(contract: _contract, function: _owner, params: []);
    contractOwner = response[0];
    print('contract owner: ' + contractOwner.toString());
    notifyListeners();
  }

  //events
  Stream<List<AddPermisionEvent>> get addPermissionEventStream {
    print('addPermissionEventStream from block: ' +
        contractDeployedBlockNumber.blockNum.toString());

    return _client
        .getLogs(FilterOptions.events(
            contract: _contract,
            event: _permissionAdded,
            fromBlock: contractDeployedBlockNumber))
        .asStream()
        .map((eventList) {
      return eventList.map((event) {
        final decoded =
            _permissionAdded.decodeResults(event.topics, event.data);
        print('from stream listen: addPermissionEventStream');
        print(decoded.toString());
        return AddPermisionEvent(
          contract: decoded[0] as EthereumAddress,
          method: decoded[1] as String,
          to: decoded[2] as EthereumAddress,
        );
      }).toList();
    });
  }

  Stream<List<RemovePermisionEvent>> get removePermissionEventStream {
    print('removePermissionEventStream from block: ' +
        contractDeployedBlockNumber.blockNum.toString());

    return _client
        .getLogs(FilterOptions.events(
            contract: _contract,
            event: _permissionRemoved,
            fromBlock: contractDeployedBlockNumber))
        .asStream()
        .map((eventList) {
      return eventList.map((event) {
        final decoded =
            _permissionRemoved.decodeResults(event.topics, event.data);

        return RemovePermisionEvent(
          contract: decoded[0] as EthereumAddress,
          method: decoded[1] as String,
          to: decoded[2] as EthereumAddress,
        );
      }).toList();
    });
  }

  // callable functions
  Future<String> addPermission(EthereumAddress contractAddress,
      String functionName, EthereumAddress toAddress) async {
    String res = await _client.sendTransaction(
      _credentials,
      Transaction.callContract(
          contract: _contract,
          function: _addPermission,
          parameters: [contractAddress, functionName, toAddress]),
      fetchChainIdFromNetworkId: true,
    );
    return res;
  }

  Future<String> removePermission(EthereumAddress contractAddress,
      String functionName, EthereumAddress toAddress) async {
    String res = await _client.sendTransaction(
      _credentials,
      Transaction.callContract(
          contract: _contract,
          function: _removePermission,
          parameters: [contractAddress, functionName, toAddress]),
      fetchChainIdFromNetworkId: true,
    );
    return res;
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
