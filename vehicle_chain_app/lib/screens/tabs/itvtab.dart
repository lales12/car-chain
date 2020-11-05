import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:ethereum_address/ethereum_address.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:progress_state_button/iconed_button.dart';
import 'package:progress_state_button/progress_button.dart';
import 'package:provider/provider.dart';
import 'package:vehicle_chain_app/contracts_services/itvmanagercontractservice.dart';
import 'package:vehicle_chain_app/screens/tabs/authorizertab.dart';
import 'package:vehicle_chain_app/services/walletmanager.dart';
import 'package:vehicle_chain_app/util/loading.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class ItvTab extends StatefulWidget {
  @override
  _ItvTabState createState() => _ItvTabState();
}

class _ItvTabState extends State<ItvTab> {
  // nfc
  static const platformMethods = const MethodChannel('carChain.com/methodsChannel');
  static const platformEvents = const EventChannel('carChain.com/getCardInfoEvent');
  static const platformSignEvents = const EventChannel('carChain.com/signEvent');

  String _isNfcAdapterEnabled = 'Unknown Nfc Status.';
  String _nfcCardPubKeyError = 'no error yet';
  String _nfcCardPubKey;
  String _nfcCardMessage;
  dynamic _nfcCardSignitureList;

  Future<void> _getNfcAdapterStatus() async {
    String isNfcAdapterEnabled;
    try {
      final bool result = await platformMethods.invokeMethod('getNfcStatus');
      isNfcAdapterEnabled = 'Nfc Status: $result ';
    } on PlatformException catch (e) {
      isNfcAdapterEnabled = "Failed to get Nfc Status: '${e.message}'.";
    }

    setState(() {
      _isNfcAdapterEnabled = isNfcAdapterEnabled;
    });
  }

  Future<void> _runCardInfoStreamOnPlatform() async {
    try {
      final bool result = await platformMethods.invokeMethod('runCardInfoStream');
      setState(() {
        _nfcCardPubKey = result ? 'Please attach your KeyCard to your device.' : 'Somthing is wrong...';
      });
      result ? _listenForCardInfo() : log('somthing is wrong');
    } on PlatformException catch (e) {
      log("Failed to launch a new stream for card info: '${e.message}'.");
    }
  }

  Future<bool> _runCardSignerOnPlatform(Uint8List hash) async {
    try {
      final bool result = await platformMethods.invokeMethod('runSignStream', {"hash": hash});
      setState(() {
        result == true ? _nfcCardMessage = 'Please attach your KeyCard to your device to Sign.' : _nfcCardMessage = 'Somthing is wrong...';
      });
      result ? _listenSignedHash() : log('somthing is wrong');
      return true;
    } on PlatformException catch (e) {
      log("Failed to launch a new stream for card info: '${e.message}'.");
      return false;
    }
  }

  void _listenForCardInfo() {
    platformEvents.receiveBroadcastStream().listen(_onEvent, onError: _onError);
  }

  StreamSubscription signitureSubscription;

  void _listenSignedHash() {
    signitureSubscription = platformSignEvents.receiveBroadcastStream().listen(_onSignEvent, onError: _onError);
  }

  @override
  void dispose() {
    log('vehicleManager Tab dispose');
    super.dispose();
    if (signitureSubscription != null) {
      signitureSubscription.cancel();
    }
  }

  void _onSignEvent(Object event) {
    log(event.toString());
    log(event.toString().length.toString());
    // log(ethereumAddressFromPublicKey(event));
    setState(() {
      _nfcCardSignitureList = json.decode(event);
      _nfcCardMessage = "Car Signiture:\n" +
          "R: " +
          '0x' +
          _nfcCardSignitureList['r'] +
          "\n" +
          "S: " +
          '0x' +
          _nfcCardSignitureList['s'] +
          "\n" +
          "V: " +
          (int.parse(_nfcCardSignitureList['v']) + 27).toString();
      stateNFCButton = ButtonState.success;
      Timer(Duration(seconds: 4), () {
        stateNFCButton = ButtonState.idle;
      });
    });
  }

  void _onEvent(Object event) {
    // log(event.toString());
    // log(event.toString().length.toString());
    // log(ethereumAddressFromPublicKey(event));
    setState(() {
      _nfcCardPubKey = ethereumAddressFromPublicKey(event);
    });
  }

  void _onError(Object error) {
    log(error.toString());
    setState(() {
      _nfcCardPubKeyError = error.toString();
    });
  }

  ////////////////////////////////////////////////
  List<ExpandingItem> _data = [
    ExpandingItem(
      name: 'Inspection Update',
      shortDiscribe: "Update vehicle's inspection state",
      isExpanded: false,
    ),
  ];

  final _formKeyUpdateInspection = GlobalKey<FormState>();
  String vinId = '';
  ButtonState stateNFCButton = ButtonState.idle;
  String inputFunctionName = '';
  ButtonState stateCallSmartContractFunctionButton = ButtonState.idle;
  String inputToAddress = '';
  int selectedvehicleStates;
  final Map<String, int> vehicleStates = {'PASSED': 1, 'NOT_PASSED': 2, 'NEGATIVE': 3};

  @override
  Widget build(BuildContext context) {
    // final authorizerContract = Provider.of<AuthorizerContract>(context);
    // final carManagerContract = Provider.of<CarManager>(context);
    final itvManagerContract = Provider.of<ItvManager>(context);
    final appUserWallet = Provider.of<WalletManager>(context).getAppUserWallet;

    if (appUserWallet != null && itvManagerContract.doneLoading) {
      return Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Container(
                  child: ExpansionPanelList(
                    expandedHeaderPadding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 8.0),
                    expansionCallback: (int index, bool isExpanded) {
                      _data.forEach((item) {
                        setState(() {
                          item.isExpanded = false;
                        });
                      });
                      setState(() {
                        _data[index].isExpanded = !isExpanded;
                      });
                    },
                    children: [
                      ExpansionPanel(
                        isExpanded: _data[0].isExpanded,
                        canTapOnHeader: true,
                        headerBuilder: (BuildContext context, bool isExpanded) {
                          return ListTile(
                            title: Text(_data[0].name),
                          );
                        },
                        body: Form(
                          key: _formKeyUpdateInspection,
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                SizedBox(height: 20.0),
                                Text(
                                  _data[0].shortDiscribe,
                                ),
                                SizedBox(height: 20.0),
                                new TextFormField(
                                  // initialValue: vinId,
                                  decoration: InputDecoration().copyWith(hintText: 'VIN Id'),
                                  validator: (val) => val.isEmpty ? 'Enter a valid VIN Id' : null,
                                  onChanged: (val) {
                                    vinId = val;
                                  },
                                ),
                                SizedBox(height: 20.0),
                                DropdownButtonFormField(
                                  items: vehicleStates.entries.map((entry) {
                                    print('key: ' + entry.key);
                                    return DropdownMenuItem(value: entry.value, child: Text(entry.key));
                                  }).toList(),
                                  decoration: InputDecoration().copyWith(hintText: 'Next vehicle state'),
                                  onChanged: (val) {
                                    setState(() {
                                      selectedvehicleStates = val;
                                    });
                                    log('selected nex state: ' + val.toString());
                                  },
                                ),
                                SizedBox(height: 20.0),
                                new ProgressButton.icon(
                                  iconedButtons: {
                                    ButtonState.idle: IconedButton(
                                        text: 'Get Car Signiture', icon: Icon(Icons.credit_card, color: Colors.white), color: Theme.of(context).buttonColor),
                                    ButtonState.loading: IconedButton(text: "Changing", color: Theme.of(context).buttonColor),
                                    ButtonState.fail:
                                        IconedButton(text: "Failed", icon: Icon(Icons.cancel, color: Colors.white), color: Theme.of(context).accentColor),
                                    ButtonState.success: IconedButton(
                                        text: "Success",
                                        icon: Icon(
                                          Icons.check_circle,
                                          color: Colors.white,
                                        ),
                                        color: Theme.of(context).buttonColor)
                                  },
                                  state: stateNFCButton,
                                  onPressed: () async {
                                    if (_formKeyUpdateInspection.currentState.validate()) {
                                      print('button pressed: Get Car Signiture');
                                      setState(() {
                                        _nfcCardMessage = "Please attach your device to Vehicle's card";
                                      });
                                      setState(() {
                                        stateNFCButton = ButtonState.loading;
                                      });
                                      try {
                                        Uint8List vinHash = keccak256(Uint8List.fromList(vinId.codeUnits));
                                        // log('hash of vin in flutter: ' + vinHash.toString());
                                        log('hash of vin in hex: ' + bytesToHex(vinHash));

                                        await _runCardSignerOnPlatform(vinHash);

                                        print('done NFC signing: ' + _nfcCardSignitureList.toString());
                                      } catch (e) {
                                        final snackBar = SnackBar(
                                          duration: Duration(seconds: 10),
                                          content: Text('error: ' + e.toString()),
                                          action: SnackBarAction(
                                            textColor: Theme.of(context).buttonColor,
                                            label: 'OK',
                                            onPressed: () {
                                              // Some code to undo the change.
                                            },
                                          ),
                                        );
                                        Scaffold.of(context).showSnackBar(snackBar);
                                        setState(() {
                                          stateNFCButton = ButtonState.fail;
                                        });
                                        // Timer(Duration(seconds: 3), () {
                                        //   setState(() {
                                        //     stateNFCButton = ButtonState.idle;
                                        //   });
                                        // });
                                      }
                                    } else {
                                      setState(() {
                                        stateNFCButton = ButtonState.idle;
                                      });
                                    }
                                  },
                                ),
                                SizedBox(height: 20.0),
                                new ProgressButton.icon(
                                  iconedButtons: {
                                    ButtonState.idle:
                                        IconedButton(text: _data[0].name, icon: Icon(Icons.search, color: Colors.white), color: Theme.of(context).buttonColor),
                                    ButtonState.loading: IconedButton(text: "Loading", color: Theme.of(context).buttonColor),
                                    ButtonState.fail:
                                        IconedButton(text: "Failed", icon: Icon(Icons.cancel, color: Colors.white), color: Theme.of(context).accentColor),
                                    ButtonState.success: IconedButton(
                                        text: "Success",
                                        icon: Icon(
                                          Icons.check_circle,
                                          color: Colors.white,
                                        ),
                                        color: Theme.of(context).buttonColor)
                                  },
                                  state: stateCallSmartContractFunctionButton,
                                  onPressed: () async {
                                    if (_formKeyUpdateInspection.currentState.validate()) {
                                      print('button pressed: ' + _data[0].name);
                                      print(vinId);
                                      print(inputFunctionName);
                                      print(inputToAddress);
                                      setState(() {
                                        stateCallSmartContractFunctionButton = ButtonState.loading;
                                      });
                                      try {
                                        TransactionReceipt result = null;
                                        if (result != null) {
                                          setState(() {
                                            stateCallSmartContractFunctionButton = ButtonState.success;
                                          });
                                          Timer(Duration(seconds: 3), () {
                                            setState(() {
                                              stateCallSmartContractFunctionButton = ButtonState.idle;
                                            });
                                          });
                                        }
                                        print('done call have access: ' + result.toString());
                                      } catch (e) {
                                        final snackBar = SnackBar(
                                          duration: Duration(seconds: 10),
                                          content: Text('error: ' + e.toString()),
                                          action: SnackBarAction(
                                            textColor: Theme.of(context).buttonColor,
                                            label: 'OK',
                                            onPressed: () {
                                              // Some code to undo the change.
                                            },
                                          ),
                                        );
                                        Scaffold.of(context).showSnackBar(snackBar);
                                        setState(() {
                                          stateCallSmartContractFunctionButton = ButtonState.fail;
                                        });
                                        Timer(Duration(seconds: 3), () {
                                          setState(() {
                                            stateCallSmartContractFunctionButton = ButtonState.idle;
                                          });
                                        });
                                      }
                                    } else {
                                      setState(() {
                                        stateCallSmartContractFunctionButton = ButtonState.idle;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // _buildPanel(_data, authorizerContract, carManagerContract.contractFunctionsList, appUserWallet),
                Divider(thickness: 2.0, height: 40.0),
                StreamBuilder(
                  stream: itvManagerContract.iTVInspectionEventListStream,
                  builder: (context, AsyncSnapshot<List<ITVInspectionEvent>> snapShot) {
                    if (snapShot.hasError) {
                      return Text('error: ' + snapShot.toString());
                    } else if (snapShot.connectionState == ConnectionState.waiting) {
                      return Text('Add Permision Event waiting...');
                    } else {
                      return Column(
                        children: [
                          Center(
                            child: Text(
                              'Technical Inspection History',
                              style: TextStyle(fontSize: 18.0, color: Theme.of(context).primaryColorLight),
                            ),
                          ),
                          ...snapShot.data.map(
                            (event) {
                              return ListTile(
                                title: Text(event.carId.toString()),
                                subtitle: Text(event.state.toString()),
                              );
                            },
                          ).toList(),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Loading(
      loadingMessage: 'Loading Contract . . .',
    );
  }
}
