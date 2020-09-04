import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:carchain/app_config.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/io.dart';

// events models
class AddPermisionEvent {
  EthereumAddress contract;
  EthereumAddress to;
  String method;
  AddPermisionEvent({this.contract, this.to, this.method});
}

class RemovePermisionEvent {
  EthereumAddress contract;
  String method;
  EthereumAddress to;
  RemovePermisionEvent({this.contract, this.method, this.to});
}

// contract class
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

  PermissionContract(EthPrivateKey userPrivKey) {
    _initiateSetup(userPrivKey);
  }

  Future<void> _initiateSetup(EthPrivateKey privateKey) async {
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
    String abiStringFile = await rootBundle.loadString("abis/Permissions.json");
    var jsonAbi = jsonDecode(abiStringFile);
    _abiCode = jsonEncode(jsonAbi["abi"]);
    _contractAddress = EthereumAddress.fromHex(jsonAbi["networks"][configParams.networkId]["address"]);
    contractAddress = _contractAddress;
    log('permissions contract address: ' + contractAddress.toString());
    // gettting contractDeployedBlockNumber
    String _deplyTxHash = jsonAbi["networks"][configParams.networkId]["transactionHash"];
    TransactionInformation txInfo = await _client.getTransactionByHash(_deplyTxHash);
    contractDeployedBlockNumber = txInfo.blockNumber;
  }

  Future<void> _getCredentials(EthPrivateKey privateKey) async {
    _credentials = privateKey;
    //await _client.credentialsFromPrivateKey(privateKey);
    _userAddress = await _credentials.extractAddress();
    log('Permisions: useraddress from privkey: ' + _userAddress.toString());
  }

  Future<void> _getDeployedContract() async {
    _contract = DeployedContract(ContractAbi.fromJson(_abiCode, "Permissions"), _contractAddress);

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
    List response = await _client.call(contract: _contract, function: _owner, params: []);
    contractOwner = response[0];
    log('Permissions: contract owner: ' + contractOwner.toString());
    notifyListeners();
  }

  //events
  Stream<List<AddPermisionEvent>> get addPermissionEventStream {
    return _client
        .events(
          FilterOptions.events(contract: _contract, event: _permissionAdded, fromBlock: contractDeployedBlockNumber),
        )
        .map((event) {
          final decoded = _permissionAdded.decodeResults(event.topics, event.data);
          print('from stream listen: addPermissionEventStream');
          print(decoded.toString());
          return AddPermisionEvent(
            contract: decoded[0] as EthereumAddress,
            method: decoded[1] as String,
            to: decoded[2] as EthereumAddress,
          );
        })
        .toList()
        .asStream();
  }

  Stream<List<AddPermisionEvent>> get addPermissionEventHistoryStream {
    log('addPermissionEventHistoryStream from block: ' + contractDeployedBlockNumber.blockNum.toString());

    return _client
        .getLogs(
          // filter,
          FilterOptions.events(contract: _contract, event: _permissionAdded, fromBlock: contractDeployedBlockNumber),
        )
        .asStream()
        .map((eventList) {
      return eventList.map((event) {
        final decoded = _permissionAdded.decodeResults(event.topics, event.data);
        print('from stream listen: addPermissionEventHistoryStream');
        print(decoded.toString());
        return AddPermisionEvent(
          contract: decoded[0] as EthereumAddress,
          to: decoded[1] as EthereumAddress,
          method: decoded[2] as String,
        );
      }).toList();
    });
  }

  Stream<List<RemovePermisionEvent>> get removePermissionEventStream {
    return _client
        .events(FilterOptions.events(contract: _contract, event: _permissionRemoved, fromBlock: contractDeployedBlockNumber))
        .map((event) {
          final decoded = _permissionRemoved.decodeResults(event.topics, event.data);

          return RemovePermisionEvent(
            contract: decoded[0] as EthereumAddress,
            method: decoded[1] as String,
            to: decoded[2] as EthereumAddress,
          );
        })
        .toList()
        .asStream();
  }

  Stream<List<RemovePermisionEvent>> get removePermissionEventHistoryStream {
    log('removePermissionEventHistoryStream from block: ' + contractDeployedBlockNumber.blockNum.toString());
    return _client
        .getLogs(FilterOptions.events(contract: _contract, event: _permissionRemoved, fromBlock: contractDeployedBlockNumber))
        .asStream()
        .map((eventList) {
      return eventList.map((event) {
        final decoded = _permissionRemoved.decodeResults(event.topics, event.data);
        return RemovePermisionEvent(
          contract: decoded[0] as EthereumAddress,
          method: decoded[1] as String,
          to: decoded[2] as EthereumAddress,
        );
      }).toList();
    });
  }

  // callable functions
  Future<String> addPermission(EthereumAddress contractAddress, String functionName, EthereumAddress toAddress) async {
    String res = await _client.sendTransaction(
      _credentials,
      Transaction.callContract(contract: _contract, function: _addPermission, parameters: [contractAddress, functionName, toAddress]),
      fetchChainIdFromNetworkId: true,
    );
    return res;
  }

  Future<String> removePermission(EthereumAddress contractAddress, String functionName, EthereumAddress toAddress) async {
    String res = await _client.sendTransaction(
      _credentials,
      Transaction.callContract(contract: _contract, function: _removePermission, parameters: [contractAddress, functionName, toAddress]),
      fetchChainIdFromNetworkId: true,
    );
    return res;
  }

  Future<bool> requestAccess(EthereumAddress contractAddress, String functionName, EthereumAddress toAddress) async {
    List haveAccess = await _client.call(contract: _contract, function: _requestAccess, params: [contractAddress, functionName, toAddress]);

    return haveAccess[0];
  }
}

// notes

// example of filtering
// https://github.com/simolus3/web3dart/issues/56
// if not all topics is needed just send null
// final carTrackerContract = Provider.of<CarTracker>(_context);
// FilterOptions(
//   address: _contractAddress,
//   topics: [
//     //The first index declares the event type
//     [
//       bytesToHex(_permissionAdded.signature,
//           padToEvenLength: true, include0x: true)
//     ],
//     [
//       bytesToHex(carTrackerContract.contractAddress.addressBytes,
//           padToEvenLength: true, include0x: true)
//     ],
//     [
//       bytesToHex(
//           carTrackerContract.contractFunctionsList[0]
//               .encodeName()
//               .codeUnits, // not sure about codeUnits
//           padToEvenLength: true,
//           include0x: true)
//     ],
//     [
//       bytesToHex(_userAddress.addressBytes,
//           padToEvenLength: true, include0x: true)
//     ]
//   ],
// );

// my failed attempt on getLogs
// log('setting fliter for event history for address: ' +
//     _userAddress.toString());
// final filter = FilterOptions(
//     address: _contractAddress,
//     topics: [
//       //The first index declares the event type
//       [
//         bytesToHex(_permissionAdded.signature,
//             padToEvenLength: true, include0x: true),
//         // null,
//         // null,
//         // '0xac700cfea5d84656a09918bd478cb95d43ad7e0a',
//         // null,
//         // 'addCar(bytes,string,uint256)',
//         // bytesToHex(_userAddress.addressBytes,
//         //     padToEvenLength: true, include0x: true)
//       ],
//       // null,
//       // null,
//       // [
//       //   '0x7f7483ceaaaf272c89fca70871045a48950747a4',
//       // ],
//       // null

//       // ['addCar(bytes,string,uint256)'],
//       // [_userAddress.toString()]
//       // [
//       //   bytesToHex(_userAddress.addressBytes,
//       //       padToEvenLength: true, include0x: true)
//       // ]
//     ],
//     fromBlock: contractDeployedBlockNumber);
